import SwiftUI

struct ContentView: View {
    let groups = AzkarData.allGroups
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hedaya_appearance") private var appearanceMode: Int = 0
    @State private var azanCheckTimer: Timer?
    @State private var showQuranReader = false
    @State private var showAppearanceSettings = false

    // First 2 groups are morning & evening; rest are other azkar
    private var dailyGroups: [AzkarGroup] { Array(groups.prefix(2)) }
    private var otherGroups: [AzkarGroup] { Array(groups.dropFirst(2)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Compact header
                    VStack(spacing: 4) {
                        Text("﷽")
                            .font(.system(size: 28))
                            .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B5E3A"))
                        Text("هداية")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(hex: "4CAF82"), Color(hex: "7ED957")]
                                        : [Color(hex: "1B7A4A"), Color(hex: "2ECC71")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("حَصِّن يومك بذكر الله")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Today's status card
                    TodayStatusCard()
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                    let gridColumns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

                    // Section: وردك اليومي
                    SectionHeader(title: "وردك اليومي")
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        // Quran card — full width
                        Button { showQuranReader = true } label: {
                            QuranCard(isDone: prayerTracker.todayLog.quranDone)
                        }
                        .buttonStyle(.plain)
                        .gridCellColumns(2)
                        .accessibilityLabel(prayerTracker.todayLog.quranDone ? "القرآن الكريم، تم الورد اليوم" : "القرآن الكريم، اقرأ وردك اليوم")

                        // Morning & evening azkar
                        ForEach(dailyGroups) { group in
                            NavigationLink(destination: AzkarGroupView(group: group)) {
                                GroupCard(group: group)
                            }
                            .accessibilityLabel(group.name)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    // Section: أذكار وأدعية
                    SectionHeader(title: "أذكار وأدعية")
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(Array(otherGroups.enumerated()), id: \.element.id) { index, group in
                            let isLastOdd = otherGroups.count % 2 == 1 && index == otherGroups.count - 1
                            NavigationLink(destination: AzkarGroupView(group: group)) {
                                GroupCard(group: group)
                            }
                            .gridCellColumns(isLastOdd ? 2 : 1)
                            .accessibilityLabel(group.name)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    // Section: أدوات
                    SectionHeader(title: "أدوات")
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        NavigationLink(destination: GeneralSebhaView()) {
                            GeneralSebhaCard()
                        }
                        .gridCellColumns(2)
                        .accessibilityLabel("سبحة عامة، عدّاد ذكر")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.bottom, 30)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HomeBottomBar()
            }
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "0D1A14"), Color(hex: "0A1510"), Color(hex: "0F1410")]
                        : [Color(hex: "F0F7F4"), Color(hex: "E8F5E9"), Color(hex: "F5F5F5")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAppearanceSettings = true } label: {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 17))
                            .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B7A4A"))
                    }
                    .accessibilityLabel("إعدادات المظهر")
                }
            }
        }
        .sheet(isPresented: $showAppearanceSettings) {
            AppearanceSettingsSheet(appearanceMode: $appearanceMode)
        }
        .sheet(isPresented: $showQuranReader) {
            QuranView()
                .environmentObject(prayerTracker)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                prayerTracker.refreshTodayLog()
                checkAndPlayAzanIfNeeded()
                azanCheckTimer?.invalidate()
                let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    checkAndPlayAzanIfNeeded()
                }
                RunLoop.main.add(timer, forMode: .common)
                azanCheckTimer = timer
            } else {
                azanCheckTimer?.invalidate()
                azanCheckTimer = nil
            }
        }
    }

    private func checkAndPlayAzanIfNeeded() {
        let playAzanSound = UserDefaults.standard.object(forKey: AzanNotificationManager.playAzanSoundKey) as? Bool ?? true
        AzanNotificationManager.playAzanIfNeeded(prayerTimes: prayerTracker.prayerTimes, playAzanSound: playAzanSound)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 4)
    }
}

// MARK: - Today Status Card

struct TodayStatusCard: View {
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore

    private var nextPrayer: (name: String, time: Date)? {
        guard let times = prayerTracker.prayerTimes else { return nil }
        let now = Date()
        let prayers: [(PrayerName, String)] = [
            (.fajr, "الفجر"), (.dhuhr, "الظهر"), (.asr, "العصر"), (.maghrib, "المغرب"), (.isha, "العشاء")
        ]
        for (prayer, arabic) in prayers {
            let t = times.time(for: prayer)
            if t > now { return (arabic, t) }
        }
        return nil
    }

    private var streakInfo: (days: Int, level: String)? {
        guard prayerTracker.streakDays > 0 else { return nil }
        return (prayerTracker.streakDays, prayerTracker.currentLevel.arabicName)
    }

    private var essentialsProgress: (done: Int, total: Int)? {
        let essentials = prayerTracker.dailyEssentialsForDisplay()
        guard !essentials.isEmpty else { return nil }
        let done = essentials.filter { prayerTracker.isEssentialSatisfied($0, in: prayerTracker.todayLog) }.count
        return (done, essentials.count)
    }

    private var hasContent: Bool {
        nextPrayer != nil || streakInfo != nil || essentialsProgress != nil
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "ar")
        return f
    }()

    var body: some View {
        if hasContent {
            NavigationLink(destination: MyWorshipPathView()) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .trailing, spacing: 10) {
                        if let next = nextPrayer {
                            StatusRow(
                                label: "الصلاة القادمة",
                                icon: "moon.stars.fill",
                                iconColor: Color(hex: "2ECC71"),
                                value: "\(next.name)  \(Self.timeFormatter.string(from: next.time))"
                            )
                        }

                        if let streak = streakInfo {
                            StatusRow(
                                label: "سلسلتك",
                                icon: "flame.fill",
                                iconColor: Color(hex: "E67E22"),
                                value: "\(streak.days) يوم · \(streak.level)"
                            )
                        }

                        if let prog = essentialsProgress {
                            VStack(alignment: .trailing, spacing: 6) {
                                StatusRow(
                                    label: "أساسيات اليوم",
                                    icon: "checkmark.circle.fill",
                                    iconColor: prog.done == prog.total ? Color(hex: "2ECC71") : Color.secondary,
                                    value: "\(prog.done) / \(prog.total)"
                                )
                                // Progress bar — environment is RTL so we flip it back to LTR
                                Capsule()
                                    .fill(Color(hex: "1B7A4A").opacity(0.2))
                                    .frame(height: 5)
                                    .overlay(alignment: .leading) {
                                        GeometryReader { geo in
                                            Capsule()
                                                .fill(Color(hex: "2ECC71"))
                                                .frame(width: prog.total > 0 ? geo.size.width * CGFloat(prog.done) / CGFloat(prog.total) : 0)
                                        }
                                    }
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "2D4A3E").opacity(0.3))
                        .padding(.top, 2)
                        .padding(.leading, 8)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(hex: "1B7A4A").opacity(0.1), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "1B7A4A").opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("حالة اليوم")
            .accessibilityHint("يفتح مسيرتك في العبادة")
        }
    }

}

// MARK: - Status Row (label + icon + value, RTL table layout)

private struct StatusRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            // Value on the left (trailing in RTL = visual left)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)
            Spacer()
            // Label + icon on the right (leading in RTL = visual right)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.secondary)
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Home bottom bar (single مسيرتي pill)

struct HomeBottomBar: View {
    var body: some View {
        NavigationLink(destination: MyWorshipPathView()) {
            HomeBarPill(icon: "leaf.circle.fill", title: "مسيرتي")
        }
        .accessibilityLabel("مسيرتي")
        .accessibilityHint("يفتح متابعة العبادة اليومية")
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

private struct HomeBarPill: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(Color(hex: "1B7A4A"))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: "1B7A4A").opacity(0.12))
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - General Sebha Card
struct GeneralSebhaCard: View {
    private let gradientColors: [Color] = [Color(hex: "1B7A4A"), Color(hex: "2ECC71")]
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            Text("سبحة عامة")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("عدّاد ذكر")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Quran Card
struct QuranCard: View {
    let isDone: Bool
    private let gradientColors: [Color] = [Color(hex: "8B6914"), Color(hex: "D4A017")]

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: isDone ? "book.circle.fill" : "book.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            Text("القرآن الكريم")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(isDone ? "✓ تم الورد" : "اقرأ وردك اليوم")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: AzkarGroup

    var body: some View {
        let colors = group.gradientColors
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 60, height: 60)

                Image(systemName: group.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            Text(group.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(group.tags.contains("Ad3ia") ? "\(group.azkar.count) أدعية" : "\(group.azkar.count) أذكار")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: colors[0].opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Appearance Settings Sheet

struct AppearanceSettingsSheet: View {
    @Binding var appearanceMode: Int
    @Environment(\.dismiss) private var dismiss

    private let options: [(label: String, icon: String, value: Int)] = [
        ("تلقائي", "circle.lefthalf.filled", 0),
        ("فاتح", "sun.max.fill", 1),
        ("داكن", "moon.fill", 2),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ForEach(options, id: \.value) { option in
                    Button {
                        appearanceMode = option.value
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "1B7A4A"))
                                .frame(width: 28)
                            Text(option.label)
                                .font(.system(size: 17))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if appearanceMode == option.value {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "1B7A4A"))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(appearanceMode == option.value
                                    ? Color(hex: "1B7A4A").opacity(0.1)
                                    : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .navigationTitle("المظهر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                        .foregroundStyle(Color(hex: "1B7A4A"))
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PrayerTrackingStore())
}
