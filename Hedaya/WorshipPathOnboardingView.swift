// MARK: - My Worship Path — Onboarding questions

import SwiftUI

struct WorshipPathOnboardingView: View {
    @ObservedObject var store: WorshipPathStore
    var onComplete: (WorshipProfile) -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var step = 0
    @State private var profile: WorshipProfile
    private let totalSteps = 7

    init(store: WorshipPathStore, onComplete: @escaping (WorshipProfile) -> Void) {
        self.store = store
        self.onComplete = onComplete
        _profile = State(initialValue: store.profile)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i <= step ? Color(hex: "1B7A4A") : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("لا إجابة صحيحة واحدة—اختر ما يناسبك")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    questionContent
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)
            bottomBar
        }
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "0D1A14"), Color(hex: "0A1510")]
                    : [Color(hex: "F0F7F4"), Color(hex: "E8F5E9")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarTitleDisplayMode(.inline)

    }

    @ViewBuilder
    private var questionContent: some View {
        switch step {
        case 0: consistencyQuestion
        case 1: timeQuestion
        case 2: intentionQuestion
        case 3: worshipAreasQuestion
        case 4: paceQuestion
        case 5: trackingQuestion
        case 6: lifeContextQuestion
        default: consistencyQuestion
        }
    }

    private var consistencyQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("كيف ترى انتظامك حالياً في الصلاة والذكر؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(ConsistencyLevel.allCases, id: \.rawValue) { level in
                choiceButton(consistencyLabel(level), selected: profile.consistencyLevel == level) { profile.consistencyLevel = level }
            }
        }
    }

    private var timeQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("كم دقيقة تقريباً يمكنك تخصيصها يومياً للعبادة؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(TimeAvailability.allCases, id: \.rawValue) { t in
                choiceButton(timeLabel(t), selected: profile.timeAvailability == t) { profile.timeAvailability = t }
            }
        }
    }

    private var intentionQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ما أبرز ما تريده من هذه المسيرة؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(PrimaryIntention.allCases, id: \.rawValue) { i in
                choiceButton(intentionLabel(i), selected: profile.primaryIntention == i) { profile.primaryIntention = i }
            }
        }
    }

    private var worshipAreasQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ما الذي تريد أن نركّز عليه معك؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(WorshipArea.allCases, id: \.rawValue) { area in
                Toggle(worshipAreaLabel(area), isOn: Binding(
                    get: { profile.worshipAreas.contains(area) },
                    set: { if $0 { profile.worshipAreas.append(area) } else { profile.worshipAreas.removeAll { $0 == area } } }
                ))
                .tint(Color(hex: "1B7A4A"))
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var paceQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ما وتيرة تناسبك؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(Pace.allCases, id: \.rawValue) { p in
                choiceButton(paceLabel(p), selected: profile.pace == p) { profile.pace = p }
            }
        }
    }

    private var trackingQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("كيف تشعر حيال متابعة نفسك؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(TrackingFeeling.allCases, id: \.rawValue) { t in
                choiceButton(trackingLabel(t), selected: profile.trackingFeeling == t) { profile.trackingFeeling = t }
            }
        }
    }

    private var lifeContextQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("هل تريد أن نأخذ وضعك في الاعتبار؟")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)
            ForEach(LifeContext.allCases, id: \.rawValue) { l in
                choiceButton(lifeContextLabel(l), selected: profile.lifeContext == l) { profile.lifeContext = l }
            }
        }
    }

    private func choiceButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 16)).foregroundStyle(Color.primary)
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "1B7A4A")) }
            }
            .padding()
            .background(selected ? Color(hex: "1B7A4A").opacity(0.12) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button("تخطى") {
                DebugLog.log("Onboarding", "Skip button TAPPED (step=\(self.step))")
                finishOrAdvance()
            }
            .font(.system(size: 15))
            .foregroundStyle(Color.secondary)
            .buttonStyle(.plain)
            Spacer()
            Button(step < totalSteps - 1 ? "التالي" : "إنهاء") {
                DebugLog.log("Onboarding", "Finish/Next button TAPPED (step=\(self.step))")
                finishOrAdvance()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: "1B7A4A"), in: RoundedRectangle(cornerRadius: 12))
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func finishOrAdvance() {
        DebugLog.log("Onboarding", "finishOrAdvance called: step=\(self.step), totalSteps=\(self.totalSteps), isLastStep=\(self.step >= self.totalSteps - 1)")
        if step < totalSteps - 1 {
            step += 1
            DebugLog.log("Onboarding", "Advanced to step \(self.step)")
        } else {
            DebugLog.log("Onboarding", "Calling onComplete with profile (lifeContext=\(String(describing: self.profile.lifeContext?.rawValue)))")
            onComplete(profile)
            DebugLog.log("Onboarding", "onComplete returned")
        }
    }

    private func consistencyLabel(_ l: ConsistencyLevel) -> String {
        switch l {
        case .veryRegular: return "منتظم جداً"
        case .sometimes: return "أحياناً أنتظم"
        case .startStop: return "أبدأ ثم أتوقف"
        case .freshStart: return "أريد أن أبدأ من جديد"
        }
    }
    private func timeLabel(_ t: TimeAvailability) -> String {
        switch t {
        case .veryLittle: return "قليل جداً (حوالي ٥–١٠)"
        case .medium: return "متوسط (١٥–٣٠)"
        case .more: return "أكثر (٣٠+)"
        case .varies: return "يختلف من يوم لآخر"
        }
    }
    private func intentionLabel(_ i: PrimaryIntention) -> String {
        switch i {
        case .discipline: return "انضباط وترتيب"
        case .closeness: return "قرب من الله"
        case .learning: return "تعلم ووعي"
        case .habit: return "بناء عادة مستدامة"
        }
    }
    private func worshipAreaLabel(_ a: WorshipArea) -> String {
        switch a {
        case .salah: return "الصلاة (فرض وسنة)"
        case .quran: return "القرآن"
        case .dhikr: return "الذكر"
        case .dua: return "الدعاء"
        case .sadaqah: return "الصدقة"
        case .zakat: return "الزكاة"
        case .goodDeeds: return "نوايا حسنة / أعمال صالحة"
        }
    }
    private func paceLabel(_ p: Pace) -> String {
        switch p {
        case .gentle: return "هادئة (خطوات صغيرة ثابتة)"
        case .balanced: return "متوازنة"
        case .ambitious: return "طموحة (مع مرونة)"
        }
    }
    private func trackingLabel(_ t: TrackingFeeling) -> String {
        switch t {
        case .motivating: return "تشجّعني وتنظمني"
        case .sometimesHeavy: return "أحياناً تثقل عليّ"
        case .preferMinimal: return "لا أحب التتبع كثيراً"
        }
    }
    private func lifeContextLabel(_ l: LifeContext) -> String {
        switch l {
        case .busyParent: return "أم/أب مشغول"
        case .student: return "طالب"
        case .traveler: return "مسافر أحياناً"
        case .none: return "لا يهم الآن"
        }
    }
}
