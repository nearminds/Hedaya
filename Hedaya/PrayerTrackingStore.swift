// MARK: - Prayer Tracking — State, persistence, prayer times

import Foundation
import SwiftUI
import CoreLocation
import Adhan

private enum StorageKey {
    static let dailyLogs = "hedaya.prayerTracking.dailyLogs"
    static let calculationMethod = "hedaya.prayerTracking.calculationMethod"
    static let profile = "hedaya.worshipPath.profile"
    static let quranProgress = "hedaya.quran.readingProgress"
}

final class PrayerTrackingStore: ObservableObject {
    @Published private(set) var todayLog: PrayerDayLog
    @Published private(set) var prayerTimes: PrayerTimesToday?
    @Published private(set) var locationDescription: String?
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var currentLevel: PathLevel = .seeds
    @Published private(set) var levelProgress: Double = 0
    @Published private(set) var mercyDaysUsedThisWeek: Int = 0
    @Published private(set) var mercyDaysAllowedPerWeek: Int = 2
    @Published private(set) var trackingFeeling: TrackingFeeling? = nil
    @Published private(set) var quranProgress: QuranReadingProgress = .initial
    @Published var coordinate: CLLocationCoordinate2D? {
        didSet {
            computePrayerTimes()
            if let coord = coordinate {
                reverseGeocode(coord)
            } else {
                locationDescription = nil
            }
        }
    }

    private let geocoder = CLGeocoder()
    @Published var calculationMethod: PrayerCalculationMethod {
        didSet {
            defaults.set(calculationMethod.rawValue, forKey: StorageKey.calculationMethod)
            computePrayerTimes()
        }
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private var dailyLogs: [String: PrayerDayLog] = [:]

    init() {
        self.todayLog = PrayerDayLog(dateKey: Self.dateKey(for: Date()))
        self.dailyLogs = Self.loadDailyLogs(from: UserDefaults.standard)
        let key = Self.dateKey(for: Date())
        self.todayLog = dailyLogs[key] ?? PrayerDayLog(dateKey: key)
        let methodRaw = UserDefaults.standard.string(forKey: StorageKey.calculationMethod)
            ?? PrayerCalculationMethod.muslimWorldLeague.rawValue
        self.calculationMethod = PrayerCalculationMethod(rawValue: methodRaw)
            ?? .muslimWorldLeague
        refreshProgress()
        self.quranProgress = Self.loadQuranProgress(from: defaults)
    }

    /// Gregorian calendar for date keys so storage is consistent regardless of device calendar (e.g. Hijri).
    private static var gregorian: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    static func dateKey(for date: Date = Date()) -> String {
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static func loadDailyLogs(from defaults: UserDefaults) -> [String: PrayerDayLog] {
        guard let data = defaults.data(forKey: StorageKey.dailyLogs),
              let decoded = try? JSONDecoder().decode([String: PrayerDayLog].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveDailyLogs() {
        guard let data = try? encoder.encode(dailyLogs) else { return }
        defaults.set(data, forKey: StorageKey.dailyLogs)
        refreshProgress()
    }

    private static func dateFrom(_ dateKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateKey)
    }

    private static func startOfWeekKey(for date: Date) -> String {
        guard let start = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return dateKey(for: date)
        }
        return dateKey(for: start)
    }

    private func loadProfile() -> WorshipProfile? {
        guard let data = defaults.data(forKey: StorageKey.profile) else { return nil }
        return try? JSONDecoder().decode(WorshipProfile.self, from: data)
    }

    /// Maps LoggedActionType to PrayerDayLog; returns true if any essential is satisfied.
    private func dayLogSatisfiesAnyEssential(_ log: PrayerDayLog, essentials: [PlanEssentialItem]) -> Bool {
        for item in essentials {
            switch item.actionType {
            case .fajr: if log.prayersCompleted.contains(.fajr) { return true }
            case .dhuhr: if log.prayersCompleted.contains(.dhuhr) { return true }
            case .asr: if log.prayersCompleted.contains(.asr) { return true }
            case .maghrib: if log.prayersCompleted.contains(.maghrib) { return true }
            case .isha: if log.prayersCompleted.contains(.isha) { return true }
            case .quran: if log.quranDone { return true }
            case .dhikrSabah: if log.branchesCompleted.contains(.morningZikr) { return true }
            case .dhikrMasa: if log.branchesCompleted.contains(.eveningZikr) { return true }
            case .dua: if log.branchesCompleted.contains(.extraDuaa) { return true }
            default: break
            }
        }
        return false
    }

    private func isOnPath(dateKey: String) -> Bool {
        guard let log = dailyLogs[dateKey] else { return false }
        if log.usedGraceDay { return true }
        if let profile = loadProfile() {
            let essentials = profile.dailyEssentials()
            if !essentials.isEmpty {
                return dayLogSatisfiesAnyEssential(log, essentials: essentials)
            }
        }
        return !log.prayersCompleted.isEmpty
            || !log.sunnahCompleted.isEmpty
            || log.sunriseSunnahDone
            || log.quranDone
            || !log.branchesCompleted.isEmpty
    }

    private func refreshProgress() {
        let weekStart = Self.startOfWeekKey(for: Date())

        if let profile = loadProfile() {
            mercyDaysAllowedPerWeek = profile.pace == .ambitious ? 1 : 2
            trackingFeeling = profile.trackingFeeling
        } else {
            trackingFeeling = nil
        }
        var mercyUsed = 0
        for (key, log) in dailyLogs where log.usedGraceDay {
            let logWeekStart = Self.startOfWeekKey(for: Self.dateFrom(key) ?? Date())
            if logWeekStart == weekStart { mercyUsed += 1 }
        }
        mercyDaysUsedThisWeek = mercyUsed

        var streak = 0
        var check = Date()
        for _ in 0..<365 {
            let key = Self.dateKey(for: check)
            if isOnPath(dateKey: key) {
                streak += 1
            } else {
                break
            }
            check = Self.gregorian.date(byAdding: .day, value: -1, to: check) ?? check
        }
        streakDays = streak

        let levelFromStreak: (Int) -> PathLevel = { s in
            if s >= 28 { return .blossom }
            if s >= 21 { return .steadfast }
            if s >= 14 { return .growth }
            if s >= 7 { return .roots }
            return .seeds
        }
        currentLevel = levelFromStreak(streak)
        let prevMilestone: [PathLevel: Int] = [.seeds: 0, .roots: 7, .growth: 14, .steadfast: 21, .blossom: 28]
        let nextMilestone: [PathLevel: Int] = [.seeds: 7, .roots: 14, .growth: 21, .steadfast: 28, .blossom: 28]
        let prev = prevMilestone[currentLevel] ?? 0
        let next = nextMilestone[currentLevel] ?? 7
        let range = next - prev
        levelProgress = range > 0 ? min(1.0, Double(streak - prev) / Double(range)) : 1.0
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let pm = placemarks?.first else { return }
            let parts = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }
            DispatchQueue.main.async {
                self.locationDescription = parts.isEmpty ? nil : parts.joined(separator: ", ")
            }
        }
    }

    private func computePrayerTimes() {
        guard let coord = coordinate else {
            prayerTimes = nil
            let playAzanSound = defaults.object(forKey: AzanNotificationManager.playAzanSoundKey) as? Bool ?? true
            AzanNotificationManager.scheduleIfNeeded(prayerTimes: nil, playAzanSound: playAzanSound)
            return
        }
        let dateComponents = Self.gregorian.dateComponents([.year, .month, .day], from: Date())
        let params: CalculationParameters = {
            switch calculationMethod {
            case .muslimWorldLeague: return CalculationMethod.muslimWorldLeague.params
            case .egyptian: return CalculationMethod.egyptian.params
            case .northAmerica: return CalculationMethod.northAmerica.params
            case .makkah: return CalculationMethod.ummAlQura.params
            case .karachi: return CalculationMethod.karachi.params
            case .turkey: return CalculationMethod.turkey.params
            }
        }()
        let coordinates = Coordinates(latitude: coord.latitude, longitude: coord.longitude)
        guard let adhanTimes = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: params) else {
            prayerTimes = nil
            return
        }
        prayerTimes = PrayerTimesToday(
            fajr: adhanTimes.fajr,
            sunrise: adhanTimes.sunrise,
            dhuhr: adhanTimes.dhuhr,
            asr: adhanTimes.asr,
            maghrib: adhanTimes.maghrib,
            isha: adhanTimes.isha
        )
        let playAzanSound = defaults.object(forKey: AzanNotificationManager.playAzanSoundKey) as? Bool ?? true
        AzanNotificationManager.scheduleIfNeeded(prayerTimes: prayerTimes, playAzanSound: playAzanSound)
    }

    func refreshTodayLog() {
        let key = Self.dateKey(for: Date())
        todayLog = dailyLogs[key] ?? PrayerDayLog(dateKey: key)
    }

    /// Ensures todayLog is for the current calendar day (handles overnight / day change).
    private func ensureTodayLogIsCurrent() {
        if todayLog.dateKey != Self.dateKey(for: Date()) {
            refreshTodayLog()
        }
    }

    func isGlowing(for prayer: PrayerName) -> Bool {
        guard let times = prayerTimes else { return false }
        let now = Date()
        let prayerTime = times.time(for: prayer)
        return now >= prayerTime && !todayLog.prayersCompleted.contains(prayer)
    }

    func markPrayerDone(_ prayer: PrayerName) {
        ensureTodayLogIsCurrent()
        var log = todayLog
        log.prayersCompleted.insert(prayer)
        todayLog = log
        dailyLogs[log.dateKey] = log
        saveDailyLogs()
    }

    func markSunriseSunnahDone() {
        ensureTodayLogIsCurrent()
        var log = todayLog
        log.sunriseSunnahDone = true
        todayLog = log
        dailyLogs[log.dateKey] = log
        saveDailyLogs()
    }

    func markSunnahDone(_ prayer: PrayerName) {
        ensureTodayLogIsCurrent()
        var log = todayLog
        log.sunnahCompleted.insert(prayer)
        todayLog = log
        dailyLogs[log.dateKey] = log
        saveDailyLogs()
    }

    func markQuranDone() {
        ensureTodayLogIsCurrent()
        var log = todayLog
        log.quranDone = true
        todayLog = log
        dailyLogs[log.dateKey] = log
        saveDailyLogs()
    }

    func markBranchDone(_ branch: BranchType) {
        ensureTodayLogIsCurrent()
        var log = todayLog
        log.branchesCompleted.insert(branch)
        todayLog = log
        dailyLogs[log.dateKey] = log
        saveDailyLogs()
    }

    /// Returns daily essentials from the loaded profile for display (e.g. "Today's focus" strip).
    func dailyEssentialsForDisplay() -> [PlanEssentialItem] {
        guard let profile = loadProfile() else { return [] }
        return profile.dailyEssentials()
    }

    /// Returns true if the given essential is satisfied by the log.
    func isEssentialSatisfied(_ item: PlanEssentialItem, in log: PrayerDayLog) -> Bool {
        switch item.actionType {
        case .fajr: return log.prayersCompleted.contains(.fajr)
        case .dhuhr: return log.prayersCompleted.contains(.dhuhr)
        case .asr: return log.prayersCompleted.contains(.asr)
        case .maghrib: return log.prayersCompleted.contains(.maghrib)
        case .isha: return log.prayersCompleted.contains(.isha)
        case .quran: return log.quranDone
        case .dhikrSabah: return log.branchesCompleted.contains(.morningZikr)
        case .dhikrMasa: return log.branchesCompleted.contains(.eveningZikr)
        case .dua: return log.branchesCompleted.contains(.extraDuaa)
        default: return false
        }
    }

    func markGraceDay(for date: Date = Date()) {
        let key = Self.dateKey(for: date)
        var log = dailyLogs[key] ?? PrayerDayLog(dateKey: key)
        log.usedGraceDay = true
        dailyLogs[key] = log
        if key == Self.dateKey(for: Date()) {
            todayLog = log
        }
        saveDailyLogs()
    }

    // MARK: - Quran reading progress

    private static func loadQuranProgress(from defaults: UserDefaults) -> QuranReadingProgress {
        guard let data = defaults.data(forKey: StorageKey.quranProgress),
              let decoded = try? JSONDecoder().decode(QuranReadingProgress.self, from: data) else {
            return .initial
        }
        return decoded
    }

    private func saveQuranProgress() {
        guard let data = try? encoder.encode(quranProgress) else { return }
        defaults.set(data, forKey: StorageKey.quranProgress)
    }

    func updateQuranProgress(pageNumber: Int, surahNumber: Int, ayahNumber: Int) {
        guard quranProgress.lastPageNumber != pageNumber
              || quranProgress.lastAyahNumber != ayahNumber
              || quranProgress.lastSurahNumber != surahNumber else { return }
        quranProgress = QuranReadingProgress(
            lastSurahNumber: surahNumber,
            lastAyahNumber: ayahNumber,
            lastPageNumber: pageNumber
        )
        saveQuranProgress()
    }
}
