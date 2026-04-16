// MARK: - Prayer Tracking — Tree UI (roots, trunk, branches)
// Uses TreeArt.svg when present (from Downloads); else SpriteKit scene. Overlays for state and taps.

import CoreLocation
import SpriteKit
import SVGView
import SwiftUI

private let prayerTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "h:mm"
    f.locale = Locale(identifier: "ar")
    return f
}()

private let islamicDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .islamicUmmAlQura)
    f.locale = Locale(identifier: "ar")
    f.dateFormat = "d MMMM yyyy"
    return f
}()

private func formatPrayerTime(_ date: Date) -> String {
    prayerTimeFormatter.string(from: date)
}

private func formatIslamicDate(_ date: Date) -> String {
    islamicDateFormatter.string(from: date)
}

struct PrayerTrackingView: View {
    @StateObject private var locationManager = PrayerLocationManager()
    @EnvironmentObject private var store: PrayerTrackingStore
    @Environment(\.colorScheme) private var colorScheme

    /// Converts coordinate to an Equatable key so we can use it with onChange(of:).
    private func coordinateKey(_ coord: CLLocationCoordinate2D?) -> String? {
        guard let c = coord else { return nil }
        return "\(c.latitude),\(c.longitude)"
    }

    var body: some View {
        Group {
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                locationDeniedView
            } else if store.prayerTimes == nil && locationManager.coordinate == nil {
                locationLoadingView
            } else {
                treeView
            }
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
        .onAppear {
            locationManager.requestLocation()
            store.coordinate = locationManager.coordinate
            store.refreshTodayLog()  // ensure correct day when opening tree (e.g. after midnight)
        }
        .onChange(of: coordinateKey(locationManager.coordinate)) { _ in
            store.coordinate = locationManager.coordinate
        }
        .onChange(of: coordinateKey(store.coordinate)) { _ in
            store.refreshTodayLog()
        }
    }

    private var locationLoadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.2)
            Text("جاري تحديد موقعك لأوقات الصلاة")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var locationDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "2ECC71").opacity(0.8))
            Text("السماح بالموقع لمعرفة أوقات الصلاة")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("فتح الإعدادات") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(hex: "2ECC71"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var treeView: some View {
        PrayerTreeGraphicContainerView(store: store)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Maps tree dhikr branches to Azkar groups for "read first" navigation.
private func azkarGroupForBranch(_ branch: BranchType) -> AzkarGroup? {
    let id: String?
    switch branch {
    case .morningZikr: id = "morning"
    case .eveningZikr: id = "evening"
    case .sleepingZikr: id = "sleep"
    default: id = nil
    }
    guard let id else { return nil }
    return AzkarData.allGroups.first { $0.id == id }
}

// MARK: - Container so we can hold debug state and add toolbar
private struct PrayerTreeGraphicContainerView: View {
    @ObservedObject var store: PrayerTrackingStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDebugOverlay = false
    @State private var showCalculationSettings = false
    @State private var azkarGroupToPresent: AzkarGroup?
    @State private var showQuranReader = false

    private var hasTreeArt: Bool {
        Bundle.main.url(forResource: "TreeArt", withExtension: "svg") != nil
    }

    private static let dayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE، d MMMM"
        f.locale = Locale(identifier: "ar")
        return f
    }()

    private var formattedDate: String {
        Self.dayDateFormatter.string(from: Date())
    }

    /// When motivating or no profile: show full stats (streak number, progress bar). When sometimesHeavy or preferMinimal: minimal (no large streak, no bar).
    private var useFullStats: Bool {
        guard let feeling = store.trackingFeeling else { return true }
        return feeling == .motivating
    }

    private var todayFocusStrip: some View {
        let essentials = store.dailyEssentialsForDisplay()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("تركيزك اليوم")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                ForEach(essentials) { item in
                    let done = store.isEssentialSatisfied(item, in: store.todayLog)
                    Button {
                        handleEssentialTap(item)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundStyle(done ? Color(hex: "2ECC71") : Color.secondary)
                            Text(item.titleAr)
                                .font(.system(size: 13))
                                .foregroundStyle(done ? Color.secondary : Color.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground).opacity(0.5))
    }

    private func handleEssentialTap(_ item: PlanEssentialItem) {
        switch item.actionType {
        case .dhikrSabah:
            if let group = azkarGroupForBranch(.morningZikr) { azkarGroupToPresent = group }
        case .dhikrMasa:
            if let group = azkarGroupForBranch(.eveningZikr) { azkarGroupToPresent = group }
        case .quran:
            showQuranReader = true
        default:
            break
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: full (motivating) or minimal (sometimesHeavy/preferMinimal)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                    HStack(spacing: 6) {
                        Text(store.currentLevel.arabicName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "2ECC71"))
                        if useFullStats {
                            Text("•")
                                .foregroundStyle(Color.secondary)
                            Text("\(store.streakDays) أيام على المسيرة")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.primary)
                        } else {
                            Text("•")
                                .foregroundStyle(Color.secondary)
                            Text("أيام على المسيرة")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                Spacer()
                if useFullStats {
                    ProgressView(value: store.levelProgress)
                        .tint(Color(hex: "2ECC71"))
                        .frame(width: 56)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground).opacity(0.7))

            if !store.dailyEssentialsForDisplay().isEmpty {
                todayFocusStrip
            }

            Group {
                if hasTreeArt {
                    PrayerTreeGraphicView(store: store, showDebugOverlay: $showDebugOverlay, onBranchTap: handleBranchTap, onQuranTap: { showQuranReader = true })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 8)
                } else {
                    ScrollView {
                        PrayerTreeGraphicView(store: store, showDebugOverlay: $showDebugOverlay, onBranchTap: handleBranchTap, onQuranTap: { showQuranReader = true })
                            .frame(minHeight: 560)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("متابعة الصلاة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCalculationSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color(hex: "2ECC71"))
                }
            }
        }
        .sheet(isPresented: $showCalculationSettings) {
            PrayerCalculationSettingsView(store: store)
                .preferredColorScheme(colorScheme == .dark ? .dark : .light)
        }
        .sheet(item: $azkarGroupToPresent) { group in
            NavigationStack {
                AzkarGroupView(group: group)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("إغلاق") { azkarGroupToPresent = nil }
                                .foregroundStyle(Color(hex: "2ECC71"))
                        }
                    }
            }
            .environmentObject(store)
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(colorScheme == .dark ? .dark : .light)
        }
        .sheet(isPresented: $showQuranReader) {
            QuranView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme == .dark ? .dark : .light)
        }
    }

    private func handleBranchTap(_ branch: BranchType) {
        if let group = azkarGroupForBranch(branch) {
            azkarGroupToPresent = group
        } else {
            store.markBranchDone(branch)
        }
    }
}

// MARK: - Calculation method settings sheet
private struct PrayerCalculationSettingsView: View {
    @ObservedObject var store: PrayerTrackingStore
    @Environment(\.dismiss) private var dismiss
    @State private var playAzanSound: Bool = (UserDefaults.standard.object(forKey: AzanNotificationManager.playAzanSoundKey) as? Bool) ?? true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $playAzanSound) {
                        Text("تشغيل صوت الأذان")
                            .foregroundStyle(Color.primary)
                    }
                    .onChange(of: playAzanSound) { newValue in
                        UserDefaults.standard.set(newValue, forKey: AzanNotificationManager.playAzanSoundKey)
                        AzanNotificationManager.scheduleIfNeeded(prayerTimes: store.prayerTimes, playAzanSound: newValue)
                    }
                } header: {
                    Text("الأذان")
                } footer: {
                    Text("عند تفعيله، سيتم تشغيل صوت الأذان عند وقت كل صلاة إذا كان الجهاز غير صامت")
                }

                Section {
                    ForEach(PrayerCalculationMethod.allCases, id: \.rawValue) { method in
                        Button {
                            store.calculationMethod = method
                            dismiss()
                        } label: {
                            HStack {
                                Text(method.titleAr)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if store.calculationMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "2ECC71"))
                                }
                            }
                        }
                    }
                } header: {
                    Text("طريقة حساب أوقات الصلاة")
                } footer: {
                    Text("اختر الطريقة المستخدمة في منطقتك للحصول على أوقات أدق")
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "2ECC71"))
                }
            }
        }
    }
}

// MARK: - Tree graphic (TreeArt.svg or SpriteKit + overlays)
private struct PrayerTreeGraphicView: View {
    @ObservedObject var store: PrayerTrackingStore
    @Binding var showDebugOverlay: Bool
    var onBranchTap: (BranchType) -> Void = { _ in }
    var onQuranTap: () -> Void = {}
    @State private var scene: PrayerTreeScene?
    @State private var tapHandler: PrayerTreeTapHandler?

    private var treeArtURL: URL? {
        Bundle.main.url(forResource: "TreeArt", withExtension: "svg")
    }

    private var useSVG: Bool { treeArtURL != nil }

    private static func branchPositionForSVG(_ branch: BranchType, layout: TreeLayout, size: CGSize) -> CGPoint {
        let w = size.width
        let h = size.height
        switch branch {
        case .morningZikr: return layout.branchLeafCenter(at: 2)
        case .sleepingZikr: return CGPoint(x: w * 0.86, y: h * 0.58)
        case .eveningZikr: return layout.branchLeafCenter(at: 4)
        case .extraDuaa: return layout.branchLeafCenter(at: 5)
        case .extraSalah: return layout.branchLeafCenter(at: 7)
        default: return layout.branchLeafCenter(at: 0)
        }
    }

    var body: some View {
        Group {
            if useSVG, let url = treeArtURL {
                // SVG: expand to fill and center. Use .fill so tree occupies screen (may crop edges).
                ZStack {
                    SVGView(contentsOf: url)
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay {
                    GeometryReader { geo in
                        let layout = TreeLayout(size: geo.size, forSVG: true)
                        ZStack(alignment: .topLeading) {
                            // Islamic date + current time — top-right above prayer trackers
                            IslamicDateTimeView(locationDescription: store.locationDescription)
                                .frame(width: geo.size.width * 0.6)
                                .position(x: geo.size.width / 2, y: geo.size.height - 120)

                            // Quran tracker near trunk
                            let trunkRect = layout.trunkRect
                            Button {
                                onQuranTap()
                            } label: {
                                Text(store.todayLog.quranDone ? "✓ ورد القرآن" : "ورد القرآن")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(store.todayLog.quranDone ? Color(hex: "2ECC71") : Color.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(store.todayLog.quranDone ? Color(hex: "2ECC71").opacity(0.7) : Color.white.opacity(0.25), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .position(x: trunkRect.midX, y: trunkRect.midY)

                            // Branch trackers near leaves: morning zekr, evening zekr, sleeping zekr, duaa, qiyam
                            let branchTypes: [BranchType] = [.morningZikr, .sleepingZikr, .eveningZikr, .extraDuaa, .extraSalah]
                            ForEach(Array(branchTypes.enumerated()), id: \.element) { _, branch in
                                let pt = PrayerTreeGraphicView.branchPositionForSVG(branch, layout: layout, size: geo.size)
                                let done = store.todayLog.branchesCompleted.contains(branch)
                                let isLeft = pt.x < geo.size.width / 2
                                HStack(spacing: 0) {
                                    if isLeft {
                                        Button {
                                            if !done { onBranchTap(branch) }
                                        } label: {
                                            BranchTrackerPill(title: branch.titleAr, isDone: done)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(done)
                                        .padding(.leading, 6)
                                        Spacer()
                                    } else {
                                        Spacer()
                                        Button {
                                            if !done { onBranchTap(branch) }
                                        } label: {
                                            BranchTrackerPill(title: branch.titleAr, isDone: done)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(done)
                                        .padding(.trailing, 6)
                                    }
                                }
                                .frame(width: geo.size.width)
                                .position(x: geo.size.width / 2, y: pt.y)
                            }

                            // Prayer trackers + sunrise (6 items: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
                            let rootSlotWidth: CGFloat = 48
                            let rootSlotHeight: CGFloat = layout.rootNodeSize + 52
                            ForEach(0..<6, id: \.self) { slot in
                                let pt = layout.rootNodeCenter(count: 6, at: slot)
                                if slot == 1, let times = store.prayerTimes {
                                    SunriseTrackerView(
                                        timeText: formatPrayerTime(times.sunrise),
                                        isSunnahDone: store.todayLog.sunriseSunnahDone,
                                        onSunnahTap: { store.markSunriseSunnahDone() }
                                    )
                                    .frame(width: rootSlotWidth, height: rootSlotHeight)
                                    .position(x: pt.x, y: pt.y - 6)
                                } else {
                                    let prayerIndex = slot < 1 ? slot : slot - 1
                                    let prayer = PrayerName.allCases[prayerIndex]
                                    RootNodeOverlayView(
                                        prayer: prayer,
                                        timeText: store.prayerTimes.map { formatPrayerTime($0.time(for: prayer)) },
                                        isGlowing: store.isGlowing(for: prayer),
                                        isCompleted: store.todayLog.prayersCompleted.contains(prayer),
                                        isSunnahDone: store.todayLog.sunnahCompleted.contains(prayer),
                                        showSunnah: prayer.hasSunnah,
                                        sunnahShaded: !prayer.hasSunnah,
                                        onFardTap: { store.markPrayerDone(prayer) },
                                        onSunnahTap: { store.markSunnahDone(prayer) }
                                    )
                                    .frame(width: rootSlotWidth, height: rootSlotHeight)
                                    .position(x: pt.x, y: pt.y - 6)
                                }
                            }
                        }
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
            } else {
                GeometryReader { geo in
                    let layout = TreeLayout(size: geo.size, forSVG: false)
                    ZStack(alignment: .topLeading) {
                        if let scene = scene {
                            SpriteView(scene: scene)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                        overlayStateOnly(layout: layout)
                        #if DEBUG
                        if showDebugOverlay {
                            debugOverlay(layout: layout)
                        }
                        #endif
                    }
                    .contentShape(Rectangle())
                    #if DEBUG
                    .onLongPressGesture(minimumDuration: 1.2) {
                        showDebugOverlay.toggle()
                    }
                    #endif
                }
            }
        }
        .onAppear {
            if scene == nil && !useSVG {
                let s = PrayerTreeScene(size: CGSize(width: 400, height: 560))
                let h = PrayerTreeTapHandler(store: store, onBranchTap: onBranchTap)
                s.tapDelegate = h
                scene = s
                tapHandler = h
            }
        }
    }

    private func overlayStateOnly(layout: TreeLayout) -> some View {
        Group {
            let rootSlotWidth: CGFloat = 48
            let rootSlotHeight: CGFloat = layout.rootNodeSize + 52
            ForEach(0..<6, id: \.self) { slot in
                let pt = layout.rootNodeCenter(count: 6, at: slot)
                if slot == 1, let times = store.prayerTimes {
                    SunriseTrackerView(
                        timeText: formatPrayerTime(times.sunrise),
                        isSunnahDone: store.todayLog.sunriseSunnahDone
                    )
                    .frame(width: rootSlotWidth, height: rootSlotHeight)
                    .position(x: pt.x, y: pt.y - 6)
                    .allowsHitTesting(false)
                } else {
                    let prayer = PrayerName.allCases[slot < 1 ? slot : slot - 1]
                    RootNodeOverlayView(
                        prayer: prayer,
                        timeText: store.prayerTimes.map { formatPrayerTime($0.time(for: prayer)) },
                        isGlowing: store.isGlowing(for: prayer),
                        isCompleted: store.todayLog.prayersCompleted.contains(prayer),
                        isSunnahDone: store.todayLog.sunnahCompleted.contains(prayer),
                        showSunnah: prayer.hasSunnah,
                        sunnahShaded: !prayer.hasSunnah
                    )
                    .frame(width: rootSlotWidth, height: rootSlotHeight)
                    .position(x: pt.x, y: pt.y - 6)
                    .allowsHitTesting(false)
                }
            }
            let trunkRect = layout.trunkRect
            Text(store.todayLog.quranDone ? "✓ ورد القرآن" : "ورد القرآن اليوم")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(store.todayLog.quranDone ? .white : Color(hex: "E8EDE0"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: trunkRect.width + 8, height: trunkRect.height)
                .position(x: trunkRect.midX, y: trunkRect.midY)
                .allowsHitTesting(false)
            ForEach(Array(BranchType.allCases.enumerated()), id: \.element) { index, branch in
                let pt = layout.branchLabelCenter(at: index)
                Text(branch.titleAr)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "3D4E2A")))
                    .position(x: pt.x, y: pt.y)
                    .allowsHitTesting(false)
            }
        }
    }

    private func overlayButtonsForSVG(layout: TreeLayout) -> some View {
        Group {
            ForEach(Array(PrayerName.allCases.enumerated()), id: \.element) { index, prayer in
                let pt = layout.rootNodeCenter(at: index)
                Button {
                    store.markPrayerDone(prayer)
                } label: {
                    RootNodeOverlayView(
                        prayer: prayer,
                        timeText: store.prayerTimes.map { formatPrayerTime($0.time(for: prayer)) },
                        isGlowing: store.isGlowing(for: prayer),
                        isCompleted: store.todayLog.prayersCompleted.contains(prayer),
                        isSunnahDone: store.todayLog.sunnahCompleted.contains(prayer)
                    )
                }
                .buttonStyle(.plain)
                .disabled(store.todayLog.prayersCompleted.contains(prayer))
                .frame(width: layout.rootNodeSize, height: layout.rootNodeSize + 20)
                .position(x: pt.x, y: pt.y + 10)
            }
            let trunkRect = layout.trunkRect
            Button {
                onQuranTap()
            } label: {
                Text(store.todayLog.quranDone ? "✓ ورد القرآن" : "ورد القرآن اليوم")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(store.todayLog.quranDone ? Color(hex: "2ECC71") : Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .frame(width: trunkRect.width + 8, height: trunkRect.height)
            .position(x: trunkRect.midX, y: trunkRect.midY)
            ForEach(Array(BranchType.allCases.enumerated()), id: \.element) { index, branch in
                let pt = layout.branchLeafCenter(at: index)
                let done = store.todayLog.branchesCompleted.contains(branch)
                Button {
                    if !done { onBranchTap(branch) }
                } label: { Color.clear.frame(width: layout.branchNodeSize + 8, height: layout.branchNodeSize + 8) }
                .buttonStyle(.plain)
                .disabled(done)
                .position(x: pt.x, y: pt.y)
            }
            ForEach(Array(BranchType.allCases.enumerated()), id: \.element) { index, branch in
                let pt = layout.branchLabelCenter(at: index)
                Text(branch.titleAr)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "3D4E2A")))
                    .position(x: pt.x, y: pt.y)
                    .allowsHitTesting(false)
            }
        }
    }

    private func debugOverlay(layout: TreeLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(PrayerTreeElementID.rootIDs.enumerated()), id: \.element) { index, id in
                let pt = layout.rootNodeCenter(at: index)
                Rectangle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .position(x: pt.x, y: pt.y)
                Text(id)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.orange)
                    .position(x: pt.x, y: pt.y - 28)
            }
            let trunkRect = layout.trunkRect
            Rectangle()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: trunkRect.width + 8, height: trunkRect.height)
                .position(x: trunkRect.midX, y: trunkRect.midY)
            Text("trunk")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.orange)
                .position(x: trunkRect.midX, y: trunkRect.midY)
            ForEach(Array(PrayerTreeElementID.branchIDs.enumerated()), id: \.element) { index, id in
                let pt = layout.branchLeafCenter(at: index)
                Rectangle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .position(x: pt.x, y: pt.y)
                Text(id.replacingOccurrences(of: "branch-", with: ""))
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.orange)
                    .position(x: pt.x, y: pt.y - 24)
            }
            VStack {
                Text("Debug: tap areas")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Long-press tree again to hide")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange.opacity(0.8))
            }
            .padding(8)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 8)
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Islamic date and current time
private struct IslamicDateTimeView: View {
    var locationDescription: String? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(spacing: 2) {
                Text(formatPrayerTime(context.date))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(formatIslamicDate(context.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                if let loc = locationDescription {
                    Text("📍 \(loc)")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Sunrise tracker (matches RootNodeOverlayView layout for alignment)
private struct SunriseTrackerView: View {
    let timeText: String
    let isSunnahDone: Bool
    var onSunnahTap: (() -> Void)? = nil

    private var shadedMainCircle: some View {
        Circle()
            .stroke(Color(hex: "3D4E2A").opacity(0.25), lineWidth: 2)
            .frame(width: 36, height: 36)
    }

    private var sunnahCircle: some View {
        ZStack {
            Circle()
                .stroke(isSunnahDone ? Color(hex: "2ECC71") : Color(hex: "3D4E2A").opacity(0.6), lineWidth: 1.5)
                .frame(width: 16, height: 16)
            if isSunnahDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "2ECC71"))
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 3) {
                shadedMainCircle
                    .frame(width: 44, height: 44)
                Text("الشروق")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(timeText)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)

            if let tap = onSunnahTap {
                Button { tap() } label: { sunnahCircle }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .frame(width: 24, height: 24)
                    .disabled(isSunnahDone)
            } else {
                sunnahCircle
            }
        }
    }
}

// MARK: - Branch tracker pill (for zekr, duaa, qiyam near leaves)
private struct BranchTrackerPill: View {
    let title: String
    let isDone: Bool

    var body: some View {
        Text(isDone ? "✓ \(title)" : title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isDone ? Color(hex: "2ECC71") : Color.primary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDone ? Color(hex: "2ECC71").opacity(0.8) : Color.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Root overlay (prayer tracker: circle, name, time; sunnah below)
private struct RootNodeOverlayView: View {
    let prayer: PrayerName
    var timeText: String? = nil
    let isGlowing: Bool
    let isCompleted: Bool
    var isSunnahDone: Bool = false
    var showSunnah: Bool = true
    /// When true, show sunnah circle greyed out (e.g. Asr has no sunnah)
    var sunnahShaded: Bool = false
    var onFardTap: (() -> Void)? = nil
    var onSunnahTap: (() -> Void)? = nil
    @State private var pulse = false

    private var fardCircle: some View {
        ZStack {
            Circle()
                .stroke(
                    isCompleted ? Color(hex: "2ECC71") : (isGlowing ? Color(hex: "2ECC71") : Color(hex: "3D4E2A")),
                    lineWidth: isGlowing ? 3 : 2
                )
                .frame(width: 36, height: 36)
                .scaleEffect(isGlowing && pulse ? 1.15 : 1.0)
                .opacity(isGlowing && pulse ? 0.5 : 1.0)
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "2ECC71"))
            }
        }
    }

    private var sunnahCircle: some View {
        ZStack {
            Circle()
                .stroke(isSunnahDone ? Color(hex: "2ECC71") : (sunnahShaded ? Color(hex: "3D4E2A").opacity(0.25) : Color(hex: "3D4E2A").opacity(0.6)), lineWidth: 1.5)
                .frame(width: 16, height: 16)
            if isSunnahDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "2ECC71"))
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Prayer tracker: circle, name, time — aligned vertically
            VStack(spacing: 3) {
                if let tap = onFardTap {
                    Button { tap() } label: { fardCircle }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .frame(width: 44, height: 44)
                        .disabled(!isGlowing)
                } else {
                    fardCircle
                }
                Text(prayer.titleAr)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                if let t = timeText {
                    Text(t)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Sunnah tracker: always show for alignment; shaded when no sunnah (Asr)
            if showSunnah || sunnahShaded {
                if sunnahShaded {
                    sunnahCircle
                        .frame(width: 24, height: 24)
                } else if let tap = onSunnahTap {
                    Button { tap() } label: { sunnahCircle }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .frame(width: 24, height: 24)
                        .disabled(isSunnahDone)
                } else {
                    sunnahCircle
                }
            }
        }
        .onAppear {
            if isGlowing {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
    }
}

// MARK: - Tree layout (coordinates for drawing and hit targets)
private struct TreeLayout {
    let size: CGSize
    let cx: CGFloat
    private let rootY: CGFloat
    private let trunkBottomY: CGFloat
    private let trunkTopY: CGFloat
    private let branchStartY: CGFloat
    /// When true, positions match TreeArt.svg (branches on right/left, roots at bottom).
    let forSVG: Bool

    let rootNodeSize: CGFloat = 38
    let trunkWidthBottom: CGFloat
    let trunkWidthTop: CGFloat
    let branchNodeSize: CGFloat = 36
    let leafSize: CGSize = CGSize(width: 36, height: 36)

    init(size: CGSize, forSVG: Bool = false) {
        self.size = size
        self.forSVG = forSVG
        cx = size.width / 2
        rootY = size.height - 32
        trunkBottomY = size.height - 40
        trunkTopY = size.height * 0.40
        branchStartY = size.height * 0.36
        trunkWidthBottom = min(52, size.width * 0.22)
        trunkWidthTop = min(28, size.width * 0.12)
    }

    /// Tapered trunk rect (wider at bottom). Used for hit-test and label.
    var trunkRect: CGRect {
        let tx = forSVG ? size.width * 0.48 : cx
        return CGRect(
            x: tx - trunkWidthBottom / 2,
            y: trunkTopY,
            width: trunkWidthBottom,
            height: trunkBottomY - trunkTopY
        )
    }

    func rootNodeCenter(at index: Int) -> CGPoint {
        rootNodeCenter(count: 5, at: index)
    }

    func rootNodeCenter(count: Int, at index: Int) -> CGPoint {
        let spread = min(size.width * 0.88, 260)
        let step = count > 1 ? spread / CGFloat(count - 1) : 0
        let centerX = forSVG ? size.width * 0.52 : cx
        let x = centerX - spread / 2 + step * CGFloat(index)
        return CGPoint(x: x, y: rootY)
    }

    /// Where the root meets the trunk (bottom of trunk).
    func rootBase(at index: Int) -> CGPoint {
        let progress = (CGFloat(index) + 0.5) / 5
        let x = cx - trunkWidthBottom / 2 + trunkWidthBottom * progress * 0.85
        return CGPoint(x: x, y: trunkBottomY)
    }

    /// Tip of the root (where the circle sits).
    func rootTip(at index: Int) -> CGPoint {
        let pt = rootNodeCenter(at: index)
        return CGPoint(x: pt.x, y: pt.y + rootNodeSize / 2 + 2)
    }

    /// Control point for curved root (organic bend).
    func rootCurveControl(at index: Int) -> CGPoint {
        let start = rootBase(at: index)
        let end = rootTip(at: index)
        let drift = CGFloat([-1, 0.5, 0, -0.5, 1][index]) * 18
        return CGPoint(x: (start.x + end.x) / 2 + drift, y: (start.y + end.y) / 2 + 8)
    }

    func branchLeafCenter(at index: Int) -> CGPoint {
        if forSVG {
            return branchLeafCenterSVG(at: index)
        }
        let leftCount = 4
        let isLeft = index < leftCount
        let sideIndex = isLeft ? index : index - leftCount
        let angleStep: CGFloat = .pi / 5.5
        let startAngle: CGFloat = isLeft ? .pi * 0.72 : .pi * 0.28
        let angle = startAngle + angleStep * CGFloat(sideIndex)
        let radius: CGFloat = min(size.width * 0.36, 110)
        let x = cx + cos(angle) * radius
        let y = branchStartY - sin(angle) * radius
        return CGPoint(x: x, y: y)
    }

    /// Positions matching TreeArt.svg: left column (6 pills), right column (2 pills over tree).
    private func branchLeafCenterSVG(at index: Int) -> CGPoint {
        let w = size.width
        let h = size.height
        let leftX = w * 0.14   // Left column - near screen edge, outside tree canopy
        let rightX = w * 0.86  // Right column - near screen edge, outside tree canopy
        switch index {
        case 6: return CGPoint(x: leftX, y: h * 0.14)   // ذكر إضافي — top left
        case 0: return CGPoint(x: leftX, y: h * 0.22)   // صلاة سنة
        case 7: return CGPoint(x: leftX, y: h * 0.30)   // صلاة إضافية
        case 1: return CGPoint(x: leftX, y: h * 0.38)   // صدقة
        case 2: return CGPoint(x: leftX, y: h * 0.46)   // أذكار الصباح
        case 3: return CGPoint(x: leftX, y: h * 0.54)   // أذكار النوم
        case 5: return CGPoint(x: rightX, y: h * 0.32)   // دعاء إضافي — right, over tree
        case 4: return CGPoint(x: rightX, y: h * 0.45)   // أذكار المساء
        default: return CGPoint(x: cx, y: branchStartY)
        }
    }

    /// Angle (radians) of branch for leaf orientation.
    func branchAngle(at index: Int) -> CGFloat {
        let center = branchLeafCenter(at: index)
        return atan2(branchStartY - center.y, center.x - cx)
    }

    func branchStart(at index: Int) -> CGPoint {
        let progress = (CGFloat(index) + 0.5) / 8
        let y = trunkTopY + (branchStartY - trunkTopY) * 0.3 + progress * 25
        return CGPoint(x: cx, y: y)
    }

    /// Control point for curved branch.
    func branchCurveControl(at index: Int) -> CGPoint {
        let start = branchStart(at: index)
        let end = branchLeafCenter(at: index)
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2
        let sign: CGFloat = end.x < cx ? -1 : 1
        return CGPoint(x: midX + sign * 25, y: midY - 15)
    }

    /// Label position below branch node (for infographic callout).
    func branchLabelCenter(at index: Int) -> CGPoint {
        let node = branchLeafCenter(at: index)
        return CGPoint(x: node.x, y: node.y + branchNodeSize / 2 + 22)
    }
}

// MARK: - Infographic tree (black trunk/branches, varied node shapes, labels)
private struct TreeDrawingView: View {
    let layout: TreeLayout
    @ObservedObject var store: PrayerTrackingStore

    private let treeBlack = Color(hex: "1C1C1C")
    private let oliveGreen = Color(hex: "556B2F")
    private let oliveBorder = Color(hex: "3D4E2A")

    var body: some View {
        ZStack {
            // Subtle decorative background (hand-drawn feel)
            Canvas { context, size in
                let decoColor = Color(hex: "8F9E6B").opacity(0.12)
                for i in 0..<6 {
                    let x = size.width * (0.1 + CGFloat(i % 3) * 0.35)
                    let y = size.height * (0.15 + CGFloat(i % 2) * 0.5)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x, y: y, width: 20, height: 28))
                    context.stroke(path, with: .color(decoColor), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }

            Canvas { context, _ in
                drawRoots(context: context)
                drawTrunk(context: context)
                drawBranches(context: context)
                drawBranchNodes(context: context)
                drawNodeConnectors(context: context)
            }
        }
    }

    private func drawRoots(context: GraphicsContext) {
        let stroke = StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        for i in 0..<5 {
            let start = layout.rootBase(at: i)
            let end = layout.rootTip(at: i)
            let control = layout.rootCurveControl(at: i)
            var path = Path()
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
            context.stroke(path, with: .color(treeBlack), style: stroke)
        }
    }

    private func drawTrunk(context: GraphicsContext) {
        let cx = layout.cx
        let t = layout.trunkRect
        let topY = t.minY
        let bottomY = t.maxY
        let wTop = layout.trunkWidthTop
        let wBottom = layout.trunkWidthBottom

        var path = Path()
        path.move(to: CGPoint(x: cx - wTop / 2, y: topY))
        path.addLine(to: CGPoint(x: cx + wTop / 2, y: topY))
        path.addLine(to: CGPoint(x: cx + wBottom / 2, y: bottomY))
        path.addLine(to: CGPoint(x: cx - wBottom / 2, y: bottomY))
        path.closeSubpath()

        let fillColor = store.todayLog.quranDone ? oliveGreen.opacity(0.9) : treeBlack
        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(treeBlack.opacity(0.9)), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
    }

    private func drawBranches(context: GraphicsContext) {
        let stroke = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        for i in 0..<8 {
            let start = layout.branchStart(at: i)
            let end = layout.branchLeafCenter(at: i)
            let control = layout.branchCurveControl(at: i)
            var path = Path()
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
            context.stroke(path, with: .color(treeBlack), style: stroke)
        }
    }

    /// Varied infographic node shape by index: rounded rect, hexagon, diamond, scallop, etc.
    private func nodeShapePath(at index: Int, center: CGPoint, size: CGFloat) -> Path {
        let s = size / 2
        let r = s * 0.4
        var path: Path
        switch index % 4 {
        case 0:
            path = Path(roundedRect: CGRect(x: -s + r, y: -s + r, width: size - 2 * r, height: size - 2 * r), cornerSize: CGSize(width: r, height: r))
        case 1:
            let h = s * 0.9
            path = Path { p in
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3 - .pi / 2
                    let pt = CGPoint(x: cos(angle) * h, y: sin(angle) * h)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
        case 2:
            path = Path { p in
                p.move(to: CGPoint(x: 0, y: -s))
                p.addLine(to: CGPoint(x: s, y: 0))
                p.addLine(to: CGPoint(x: 0, y: s))
                p.addLine(to: CGPoint(x: -s, y: 0))
                p.closeSubpath()
            }
        default:
            path = Path(ellipseIn: CGRect(x: -s * 0.9, y: -s * 0.7, width: s * 1.8, height: s * 1.4))
        }
        path = path.applying(CGAffineTransform(translationX: center.x, y: center.y))
        return path
    }

    private func drawBranchNodes(context: GraphicsContext) {
        let size = layout.branchNodeSize
        for (index, branch) in BranchType.allCases.enumerated() {
            let center = layout.branchLeafCenter(at: index)
            let done = store.todayLog.branchesCompleted.contains(branch)
            let path = nodeShapePath(at: index, center: center, size: size)
            if done {
                context.fill(path, with: .color(oliveGreen))
                context.stroke(path, with: .color(oliveBorder), style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
            } else {
                context.fill(path, with: .color(.white))
                context.stroke(path, with: .color(oliveBorder), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
        }
    }

    private func drawNodeConnectors(context: GraphicsContext) {
        let stroke = StrokeStyle(lineWidth: 1, lineCap: .round)
        for i in 0..<8 {
            let from = layout.branchLeafCenter(at: i)
            let to = layout.branchLabelCenter(at: i)
            var path = Path()
            path.move(to: CGPoint(x: from.x, y: from.y + layout.branchNodeSize / 2))
            path.addLine(to: CGPoint(x: to.x, y: to.y - 10))
            context.stroke(path, with: .color(treeBlack.opacity(0.6)), style: stroke)
        }
    }
}

// MARK: - Root node (one per prayer) — infographic style
private struct RootNodeView: View {
    let prayer: PrayerName
    let isGlowing: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    private let oliveGreen = Color(hex: "556B2F")
    private let oliveBorder = Color(hex: "3D4E2A")

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(oliveGreen)
                            .frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(isGlowing ? oliveGreen.opacity(0.5) : Color(hex: "E8EDE0"))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(oliveBorder, lineWidth: 1.5)
                            )
                        if isGlowing {
                            Circle()
                                .stroke(oliveGreen, lineWidth: 2.5)
                                .frame(width: 34, height: 34)
                                .scaleEffect(pulse ? 1.15 : 1.0)
                                .opacity(pulse ? 0.5 : 0.9)
                        }
                        Text(prayer.titleAr)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isGlowing ? oliveBorder : Color.secondary)
                            .lineLimit(1)
                    }
                }
                Text(prayer.titleAr)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .onAppear {
            if isGlowing {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Flow layout for branch pills (unused after tree; keep for possible list fallback)
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        PrayerTrackingView()
            .environmentObject(PrayerTrackingStore())
    }
}
