// MARK: - My Worship Path — Container & main views

import SwiftUI

struct MyWorshipPathView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = WorshipPathStore()
    @State private var screen: PathScreen = .intro

    private enum PathScreen {
        case intro
        case onboarding
        case plan
        case tree
    }

    var body: some View {
        Group {
            switch screen {
            case .intro:
                WorshipPathIntroView(onStart: { screen = .onboarding }, onSkip: { dismiss() })
            case .onboarding:
                WorshipPathOnboardingView(store: store, onComplete: { profile in
                    DebugLog.log("WorshipPath", "Onboarding onComplete, switching to .plan")
                    store.completeOnboarding(with: profile)
                    screen = .plan
                })
            case .plan:
                WorshipPathPlanView(store: store, onContinue: { screen = .tree })
            case .tree:
                PrayerTrackingView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if store.profile.hasCompletedOnboarding {
                screen = .tree
            }
        }
    }
}

struct WorshipPathIntroView: View {
    var onStart: () -> Void
    var onSkip: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("﷽")
                    .font(.system(size: 28))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: "5EC98A") : Color(hex: "1B5E3A"))
                Text("مسيرتك في العبادة")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "1B7A4A"))
                    .multilineTextAlignment(.center)
                Text("خطوة بخطوة، وفق وقتك ونيتك، بدون ضغط ولا مقارنة.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("هنا نرتب معاً ما تريد أن تركز عليه من صلاة وذكر وقراءة وصدقة، ونضع خطة بسيطة تتكيف مع أيامك.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                VStack(spacing: 14) {
                    Button(action: onStart) {
                        Text("ابدأ مسيرتي")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1B7A4A"), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    Button(action: onSkip) {
                        Text("تخطى الآن")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "0D1A14"), Color(hex: "0A1510"), Color(hex: "0F1410")]
                    : [Color(hex: "F0F7F4"), Color(hex: "E8F5E9"), Color(hex: "F5F5F5")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorshipPathPlanView: View {
    @ObservedObject var store: WorshipPathStore
    var onContinue: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("خطتك في العبادة")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "1B7A4A"))
                    .padding(.horizontal)
                Text("بناءً على اختياراتك")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: 12) {
                    Text("الضروريات اليومية")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text("هذه أساس يومك. إن فاتك يوم، الخطة تتكيف ولا نلوم.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    ForEach(store.dailyEssentials()) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "2ECC71"))
                            Text(item.titleAr).font(.system(size: 16))
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 12) {
                    Text("إضافات اختيارية")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    ForEach(store.optionalBonuses()) { item in
                        Text("• \(item.titleAr)").font(.system(size: 15))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground).opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                Text("لديك أيام راحة مضمونة. إذا غبت، نعدّل الهدف ولا نعيد العد من الصفر.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .padding(.horizontal)
                Button(action: onContinue) {
                    Text("متابعة إلى الشجرة")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "1B7A4A"), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            .padding(.vertical, 24)
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
}

