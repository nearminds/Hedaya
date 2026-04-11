// MARK: - My Worship Path — Data models

import Foundation

enum ConsistencyLevel: String, Codable, CaseIterable {
    case veryRegular = "very_regular"
    case sometimes = "sometimes"
    case startStop = "start_stop"
    case freshStart = "fresh_start"
}

enum TimeAvailability: String, Codable, CaseIterable {
    case veryLittle = "very_little"
    case medium = "medium"
    case more = "more"
    case varies = "varies"
}

enum PrimaryIntention: String, Codable, CaseIterable {
    case discipline = "discipline"
    case closeness = "closeness"
    case learning = "learning"
    case habit = "habit"
}

enum WorshipArea: String, Codable, CaseIterable {
    case salah
    case quran
    case dhikr
    case dua
    case sadaqah
    case zakat
    case goodDeeds
}

enum Pace: String, Codable, CaseIterable {
    case gentle = "gentle"
    case balanced = "balanced"
    case ambitious = "ambitious"
}

enum TrackingFeeling: String, Codable, CaseIterable {
    case motivating = "motivating"
    case sometimesHeavy = "sometimes_heavy"
    case preferMinimal = "prefer_minimal"
}

enum LifeContext: String, Codable, CaseIterable {
    case busyParent = "busy_parent"
    case student = "student"
    case traveler = "traveler"
    case none = "none"
}

struct WorshipProfile: Codable, Equatable {
    var consistencyLevel: ConsistencyLevel?
    var timeAvailability: TimeAvailability?
    var primaryIntention: PrimaryIntention?
    var worshipAreas: [WorshipArea]
    var pace: Pace?
    var trackingFeeling: TrackingFeeling?
    var lifeContext: LifeContext?
    var completedAt: Date?

    init(
        consistencyLevel: ConsistencyLevel? = nil,
        timeAvailability: TimeAvailability? = nil,
        primaryIntention: PrimaryIntention? = nil,
        worshipAreas: [WorshipArea] = [],
        pace: Pace? = nil,
        trackingFeeling: TrackingFeeling? = nil,
        lifeContext: LifeContext? = nil,
        completedAt: Date? = nil
    ) {
        self.consistencyLevel = consistencyLevel
        self.timeAvailability = timeAvailability
        self.primaryIntention = primaryIntention
        self.worshipAreas = worshipAreas
        self.pace = pace
        self.trackingFeeling = trackingFeeling
        self.lifeContext = lifeContext
        self.completedAt = completedAt
    }

    var hasCompletedOnboarding: Bool { completedAt != nil }

    /// Build daily essentials from worship areas and pace. Single source of truth for both
    /// WorshipPathStore (plan views) and PrayerTrackingStore (tree/streak logic).
    func dailyEssentials() -> [PlanEssentialItem] {
        let areas = worshipAreas.isEmpty ? WorshipArea.allCases : worshipAreas
        let resolvedPace = self.pace ?? .balanced
        var items: [PlanEssentialItem] = []
        if areas.contains(.salah) {
            items.append(PlanEssentialItem(titleAr: "صلاة الفجر", actionType: .fajr))
            items.append(PlanEssentialItem(titleAr: "صلاة الظهر", actionType: .dhuhr))
            items.append(PlanEssentialItem(titleAr: "صلاة العصر", actionType: .asr))
            items.append(PlanEssentialItem(titleAr: "صلاة المغرب", actionType: .maghrib))
            items.append(PlanEssentialItem(titleAr: "صلاة العشاء", actionType: .isha))
        }
        if areas.contains(.quran) { items.append(PlanEssentialItem(titleAr: "ورد قرآن قصير", actionType: .quran)) }
        if areas.contains(.dhikr) {
            items.append(PlanEssentialItem(titleAr: "أذكار الصباح", actionType: .dhikrSabah))
            items.append(PlanEssentialItem(titleAr: "أذكار المساء", actionType: .dhikrMasa))
        }
        if areas.contains(.dua) && (resolvedPace == .balanced || resolvedPace == .ambitious) {
            items.append(PlanEssentialItem(titleAr: "دعاء بعد الصلاة", actionType: .dua))
        }
        if resolvedPace == .gentle {
            return Array(items.prefix(6))
        }
        return items
    }
}

enum LoggedActionType: String, Codable, CaseIterable {
    case salah
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case quran
    case dhikr
    case dhikrSabah   // أذكار الصباح
    case dhikrMasa    // أذكار المساء
    case dua
    case sadaqah
    case zakat
    case goodDeed
    case qiyamAlLayl   // قيام الليل
    case extraDhikr    // ذكر إضافي
    case extraDua      // دعاء إضافي
    // السنن الرواتب (individually)
    case sunnahFajr    // سنة الفجر
    case sunnahDhuhr   // سنة الظهر
    case sunnahAsr     // سنة العصر
    case sunnahMaghrib // سنة المغرب
    case sunnahIsha    // سنة العشاء
}

struct LoggedAction: Codable, Identifiable {
    let id: UUID
    var type: LoggedActionType
    var subtype: String?
    var completedAt: Date?

    init(id: UUID = UUID(), type: LoggedActionType, subtype: String? = nil, completedAt: Date? = nil) {
        self.id = id
        self.type = type
        self.subtype = subtype
        self.completedAt = completedAt
    }
}

struct DailyLog: Codable, Identifiable {
    var id: String { dateKey }
    let dateKey: String
    var actions: [LoggedAction]
    var reflectionNote: String?
    var usedGraceDay: Bool

    init(dateKey: String, actions: [LoggedAction] = [], reflectionNote: String? = nil, usedGraceDay: Bool = false) {
        self.dateKey = dateKey
        self.actions = actions
        self.reflectionNote = reflectionNote
        self.usedGraceDay = usedGraceDay
    }
}

enum PathLevel: String, Codable, CaseIterable {
    case seeds
    case roots
    case growth
    case steadfast
    case blossom

    var arabicName: String {
        switch self {
        case .seeds:     return "البذور"
        case .roots:     return "الجذور"
        case .growth:    return "النمو"
        case .steadfast: return "الثبات"
        case .blossom:   return "الإزهار"
        }
    }
}

struct ProgressState: Codable {
    var currentLevel: PathLevel
    var levelProgress: Double
    var streakDays: Int
    var mercyDaysUsedThisWeek: Int
    var mercyDaysAllowedPerWeek: Int
    var weekStartKey: String?
    var levelWindowStartKey: String?
    var badges: [String]
    var lastPlanAdaptationAt: Date?

    static let `default` = ProgressState(
        currentLevel: .seeds,
        levelProgress: 0,
        streakDays: 0,
        mercyDaysUsedThisWeek: 0,
        mercyDaysAllowedPerWeek: 2,
        weekStartKey: nil,
        levelWindowStartKey: nil,
        badges: [],
        lastPlanAdaptationAt: nil
    )
}

struct PlanEssentialItem: Identifiable {
    let id = UUID()
    let titleAr: String
    let actionType: LoggedActionType
}

struct PlanBonusItem: Identifiable {
    let id = UUID()
    let titleAr: String
    let actionType: LoggedActionType?
}
