// MARK: - Quran Reader

import SwiftUI

// MARK: - Entry sheet: surah list

struct QuranView: View {
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var surahs: [QuranSurah] = []
    @State private var searchText = ""
    @State private var readerTarget: QuranReaderTarget?

    private var filtered: [QuranSurah] {
        if searchText.isEmpty { return surahs }
        let q = searchText
        return surahs.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.englishName.localizedCaseInsensitiveContains(q) ||
            "\($0.id)".contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { surah in
                Button {
                    readerTarget = .surah(surah.id)
                } label: {
                    SurahRowView(
                        surah: surah,
                        isLastRead: prayerTracker.quranProgress.lastSurahNumber == surah.id
                    )
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "ابحث عن سورة")
            .navigationTitle("القرآن الكريم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B7A4A"))
                }
                if prayerTracker.todayLog.quranDone {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("تم الورد", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? Color(hex: "D4A017") : Color(hex: "B8860B"))
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                let progress = prayerTracker.quranProgress
                if (progress.lastSurahNumber > 1 || progress.lastAyahNumber > 1),
                   let lastSurah = surahs.first(where: { $0.id == progress.lastSurahNumber }) {
                    continueBanner(surah: lastSurah, ayah: progress.lastAyahNumber)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(item: $readerTarget) { target in
            QuranReaderView(initialTarget: target)
                .environmentObject(prayerTracker)
        }
        .onAppear {
            if surahs.isEmpty { surahs = QuranDataLoader.allSurahs }
        }
    }

    private func continueBanner(surah: QuranSurah, ayah: Int) -> some View {
        Button { readerTarget = .page(prayerTracker.quranProgress.lastPageNumber) } label: {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(colorScheme == .dark ? Color(hex: "D4A017") : Color(hex: "B8860B"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("تابع القراءة")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text("\(surah.name) — آية \(ayah)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 13))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B7A4A"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(colorScheme == .dark ? Color(hex: "1A1408") : Color(hex: "FFF8E7"))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation target (which page to open)

enum QuranReaderTarget: Identifiable {
    case surah(Int)   // open at first page of this surah number
    case page(Int)    // open at this Mushaf page number (1-based)
    var id: String {
        switch self { case .surah(let n): return "s\(n)"; case .page(let n): return "p\(n)" }
    }
}

// MARK: - Surah row

struct SurahRowView: View {
    let surah: QuranSurah
    let isLastRead: Bool

    private var revelationLabel: String {
        surah.revelationType == "Meccan" ? "مكية" : "مدنية"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isLastRead ? Color(hex: "B8860B") : Color.clear)
                    .overlay(Circle().stroke(Color(hex: "B8860B"), lineWidth: isLastRead ? 0 : 1.5))
                    .frame(width: 36, height: 36)
                Text("\(surah.id)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isLastRead ? .white : Color(hex: "B8860B"))
            }
            VStack(alignment: .trailing, spacing: 3) {
                HStack {
                    if isLastRead {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "B8860B"))
                    }
                    Text(surah.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
                Text("\(surah.ayahCount) آيات • \(revelationLabel)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Full-screen Mushaf reader

struct QuranReaderView: View {
    let initialTarget: QuranReaderTarget
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let pages = QuranDataLoader.allPages
    private var goldColor: Color {
        colorScheme == .dark ? Color(hex: "D4A017") : Color(hex: "B8860B")
    }

    /// Warm cream in light mode; dark sepia in dark mode.
    private var pageBg: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.10, blue: 0.07) : Color(hex: "FDFAF4")
    }
    private var warmBg: Color { pageBg }

    @State private var currentIndex: Int = 0
    @State private var focusMode = false
    @State private var showSurahPicker = false

    private var currentPage: QuranPage? {
        guard currentIndex < pages.count else { return nil }
        return pages[currentIndex]
    }

    private var currentJuz: Int {
        let starts = [1,22,42,62,82,102,121,142,162,182,201,221,242,261,281,
                      301,322,342,362,381,401,421,441,461,481,501,521,542,562,582]
        let p = currentPage?.id ?? 1
        return (starts.lastIndex(where: { $0 <= p }) ?? 0) + 1
    }

    private func juzArabic(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).compactMap { c in c.wholeNumberValue.map { d[$0] } }.joined()
    }

    var body: some View {
        ZStack {
            warmBg.ignoresSafeArea()

            // Paged content — RTL so page 1 is on the right, swipe left = next page
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    MushafPageView(page: page, goldColor: goldColor, pageBg: pageBg)
                        .tag(index)
                        .overlay(
                            GeometryReader { geo in
                                HStack(spacing: 0) {
                                    // Left zone — next page (RTL: left = forward)
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentIndex < pages.count - 1 {
                                                withAnimation { currentIndex += 1 }
                                            }
                                        }
                                        .frame(width: geo.size.width / 3)
                                    // Middle zone — toggle focus mode
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) { focusMode.toggle() }
                                        }
                                    // Right zone — previous page (RTL: right = back)
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentIndex > 0 {
                                                withAnimation { currentIndex -= 1 }
                                            }
                                        }
                                        .frame(width: geo.size.width / 3)
                                }
                            }
                        )
                        .onAppear {
                            if let first = page.firstAyah {
                                prayerTracker.updateQuranProgress(
                                    pageNumber: page.id,
                                    surahNumber: first.surahNumber,
                                    ayahNumber: first.id
                                )
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
            .ignoresSafeArea()

            // Chrome — hidden in focus mode
            if !focusMode {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomBar
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSurahPicker) {
            SurahPickerView { surahNumber in
                currentIndex = QuranDataLoader.pageIndex(forSurah: surahNumber)
                showSurahPicker = false
            }
            .environmentObject(prayerTracker)
        }
        .onAppear {
            switch initialTarget {
            case .surah(let n): currentIndex = QuranDataLoader.pageIndex(forSurah: n)
            case .page(let n):  currentIndex = QuranDataLoader.pageIndex(forMushafPage: n)
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemFill), in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(currentPage?.primarySurahName ?? "")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Text("صفحة \(currentPage?.id ?? 1)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("الجزء \(juzArabic(currentJuz))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                showSurahPicker = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemFill), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(warmBg.opacity(0.95))
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        let done = prayerTracker.todayLog.quranDone
        return VStack(spacing: 0) {
            // Reading progress bar
            GeometryReader { geo in
                let progress = pages.isEmpty ? 0.0 : Double(currentIndex + 1) / Double(pages.count)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                    Rectangle()
                        .fill(goldColor.opacity(0.75))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 2)

            // Page navigation strip
            HStack(spacing: 16) {
                // Next page (higher index = further into Quran)
                Button {
                    if currentIndex < pages.count - 1 {
                        withAnimation { currentIndex += 1 }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(currentIndex < pages.count - 1 ? Color.primary : Color.secondary)
                }
                .disabled(currentIndex >= pages.count - 1)

                Spacer()

                Text("صفحة \(currentPage?.id ?? 1) من \(pages.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                // Previous page (lower index = earlier in Quran)
                Button {
                    if currentIndex > 0 {
                        withAnimation { currentIndex -= 1 }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(currentIndex > 0 ? Color.primary : Color.secondary)
                }
                .disabled(currentIndex <= 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(warmBg.opacity(0.95))

            // Ward button
            Button {
                if !done {
                    prayerTracker.markQuranDone()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } label: {
                HStack(spacing: 8) {
                    if done { Image(systemName: "checkmark.circle.fill").font(.system(size: 17)) }
                    Text(done ? "✓ تم تسجيل الورد اليوم" : "أتممت ورد القرآن اليوم")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(done ? (colorScheme == .dark ? Color(hex: "4CAF82") : Color(hex: "3D4E2A")) : goldColor)
            }
            .buttonStyle(.plain)
            .disabled(done)
            .accessibilityLabel(done ? "تم تسجيل الورد اليوم" : "تسجيل إتمام ورد القرآن")
        }
    }
}

// MARK: - Content height preference key

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - One Mushaf page

private struct MushafPageView: View {
    let page: QuranPage
    let goldColor: Color
    let pageBg: Color

    private let baseFontSize: CGFloat = 17
    @State private var fontSize: CGFloat = 17

    var body: some View {
        GeometryReader { geo in
            let topPad: CGFloat = 72
            let botPad: CGFloat = 100
            let available = geo.size.height - topPad - botPad

            ScrollView {
                pageContent(fontSize: fontSize)
                    .padding(.horizontal, 20)
                    .padding(.top, topPad)
                    .padding(.bottom, botPad)
                    .background(
                        GeometryReader { inner in
                            Color.clear.preference(
                                key: ContentHeightKey.self,
                                value: inner.size.height - topPad - botPad
                            )
                        }
                    )
            }
            .background(pageBg)
            .onPreferenceChange(ContentHeightKey.self) { naturalH in
                guard naturalH > 10, available > 10 else { return }
                let ratio = available / naturalH
                let candidate = (baseFontSize * ratio).rounded()
                let clamped = max(13, min(22, candidate))
                if abs(clamped - fontSize) > 0.4 { fontSize = clamped }
            }
        }
    }

    private func pageContent(fontSize: CGFloat) -> some View {
        VStack(spacing: fontSize * 0.7) {
            ForEach(Array(page.segments.enumerated()), id: \.offset) { _, segment in
                SegmentView(segment: segment, goldColor: goldColor, fontSize: fontSize)
            }
        }
    }
}

// MARK: - One segment (run of ayahs from the same surah)

/// Surahs whose first ayah is muqattaat (disconnected letters) — rendered centered.
private let muqattaatSurahs: Set<Int> = [
    2,3,7,10,11,12,13,14,15,19,20,26,27,28,29,30,31,32,36,38,40,41,42,43,44,45,46,50,68
]

private let quranFont = "AmiriQuran-Regular"

private struct SegmentView: View {
    let segment: QuranPageSegment
    let goldColor: Color
    let fontSize: CGFloat

    private func arabicNumeral(_ n: Int) -> String {
        let d = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).compactMap { c in c.wholeNumberValue.map { d[$0] } }.joined()
    }

    private var hasMuqattaat: Bool {
        segment.showSurahHeader && muqattaatSurahs.contains(segment.surahNumber)
    }

    private func flowingText(for ayahs: [QuranAyah]) -> Text {
        ayahs.reduce(Text("")) { result, ayah in
            result
                + Text(ayah.text)
                + Text(" \u{200F}﴿\(arabicNumeral(ayah.id))﴾\u{200F} ")
                    .foregroundColor(goldColor)
        }
    }

    private var lineSpacing: CGFloat { max(2, fontSize * 0.18) }

    var body: some View {
        VStack(spacing: fontSize * 0.5) {
            if segment.showSurahHeader {
                Text(segment.surahName)
                    .font(.custom(quranFont, size: fontSize * 0.85).weight(.bold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().frame(height: 1)
                            Spacer()
                            Rectangle().frame(height: 1)
                        }
                        .foregroundStyle(goldColor.opacity(0.45))
                    )

                if segment.showBasmala {
                    Text("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ")
                        .font(.custom(quranFont, size: fontSize * 0.9))
                        .foregroundStyle(goldColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }

            if segment.surahNumber == 1 {
                VStack(spacing: fontSize * 0.4) {
                    ForEach(segment.ayahs) { ayah in
                        Text(ayah.text)
                            .font(.custom(quranFont, size: fontSize))
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineSpacing(lineSpacing)
                    }
                }
            } else if hasMuqattaat, let first = segment.ayahs.first {
                Text(first.text)
                    .font(.custom(quranFont, size: fontSize * 1.2))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if segment.ayahs.count > 1 {
                    flowingText(for: Array(segment.ayahs.dropFirst()))
                        .font(.custom(quranFont, size: fontSize))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(lineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                flowingText(for: segment.ayahs)
                    .font(.custom(quranFont, size: fontSize))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Surah picker sheet

struct SurahPickerView: View {
    let onSelect: (Int) -> Void
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var surahs: [QuranSurah] = []
    @State private var search = ""

    private var filtered: [QuranSurah] {
        if search.isEmpty { return surahs }
        let q = search
        return surahs.filter {
            $0.name.localizedCaseInsensitiveContains(q) || $0.englishName.localizedCaseInsensitiveContains(q) || "\($0.id)".contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { surah in
                Button {
                    onSelect(surah.id)
                } label: {
                    SurahRowView(
                        surah: surah,
                        isLastRead: prayerTracker.quranProgress.lastSurahNumber == surah.id
                    )
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "ابحث عن سورة")
            .navigationTitle("اختر سورة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B7A4A"))
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if surahs.isEmpty { surahs = QuranDataLoader.allSurahs }
        }
    }
}
