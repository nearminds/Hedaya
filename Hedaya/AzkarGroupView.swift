import SwiftUI

/// Maps Azkar groups to Prayer Tree branches so completion marks the tree.
private func branchForGroup(_ group: AzkarGroup) -> BranchType? {
    switch group.id {
    case "morning": return .morningZikr
    case "evening": return .eveningZikr
    case "sleep": return .sleepingZikr
    case "after_prayer", "misc": return .extraZikr
    default:
        if group.tags.contains("Ad3ia") { return .extraDuaa }
        return nil
    }
}

struct AzkarGroupView: View {
    let group: AzkarGroup
    @EnvironmentObject private var prayerTracker: PrayerTrackingStore
    @State private var currentIndex: Int = 0
    @State private var currentCount: Int = 0
    @State private var isCompleted: Bool = false
    @State private var showPulse: Bool = false
    @State private var showCompletionEffect: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var currentZikr: Zikr {
        group.azkar[currentIndex]
    }

    private var progress: Double {
        guard currentZikr.repetitions > 0 else { return 0 }
        return Double(currentCount) / Double(currentZikr.repetitions)
    }

    private var overallProgress: Double {
        let totalAzkar = group.azkar.count
        guard totalAzkar > 0 else { return 0 }
        return (Double(currentIndex) + progress) / Double(totalAzkar)
    }

    private var gradientColors: [Color] { group.gradientColors }
    
    var body: some View {
        ZStack {
            // Background — adapts to dark/light mode
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "0D1A14"), Color(hex: "0A1510"), Color(hex: "0F1410")]
                    : [Color(hex: "F0F7F4"), Color(hex: "E8F5E9"), Color(hex: "F5F5F5")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isCompleted {
                completionView
            } else {
                zikrContentView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(group.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(gradientColors[0])
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    // MARK: - Zikr Content View
    private var zikrContentView: some View {
        VStack(spacing: 0) {
            // Overall progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("الذكر \(currentIndex + 1) من \(group.azkar.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "2D4A3E"))
                    Spacer()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * overallProgress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: overallProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Zikr Text Card
            ScrollView {
                VStack(spacing: 16) {
                    Text(currentZikr.text)
                        .font(.system(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(12)
                        .foregroundStyle(Color(hex: "2C3E50"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)
                    
                    // Reference
                    Text(currentZikr.reference)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "2D4A3E"))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
            }
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 16)
            )
            .padding(.horizontal, 4)
            
            Spacer().frame(height: 20)
            
            // Counter Section
            VStack(spacing: 16) {
                // Counter display
                HStack(spacing: 4) {
                    Text("\(currentCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(gradientColors[0])
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: currentCount)
                    
                    Text("/")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color(hex: "2D4A3E"))
                    
                    Text("\(currentZikr.repetitions)")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "2D4A3E"))
                }
                
                // Tap circle button
                ZStack {
                    // Outer progress ring
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Pulse effect
                    Circle()
                        .fill(gradientColors[0].opacity(0.15))
                        .frame(width: showPulse ? 110 : 90, height: showPulse ? 110 : 90)
                        .animation(.easeOut(duration: 0.3), value: showPulse)
                    
                    // White dot button
                    Circle()
                        .fill(.white)
                        .frame(width: 90, height: 90)
                        .shadow(color: gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .overlay(
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .scaleEffect(showPulse ? 0.95 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: showPulse)
                }
                .onTapGesture {
                    handleTap()
                }
                
                // Navigation buttons
                HStack(spacing: 40) {
                    Button(action: goToPrevious) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                            Text("السابق")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(currentIndex > 0 ? gradientColors[0] : .gray.opacity(0.4))
                    }
                    .disabled(currentIndex == 0)
                    
                    Button(action: goToNext) {
                        HStack(spacing: 6) {
                            Text("التالي")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(currentIndex < group.azkar.count - 1 ? gradientColors[0] : .gray.opacity(0.4))
                    }
                    .disabled(currentIndex >= group.azkar.count - 1)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: gradientColors[0].opacity(0.4), radius: 16, x: 0, y: 6)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(showCompletionEffect ? 1.0 : 0.5)
            .opacity(showCompletionEffect ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCompletionEffect)
            
            VStack(spacing: 12) {
                Text("بارك الله فيك!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color(hex: "2C3E50"))
                
                Text("لقد أتممت \(group.name)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "2D4A3E"))
                
                Text("تقبّل الله منّا ومنكم")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(gradientColors[0])
                    .padding(.top, 8)
            }
            .opacity(showCompletionEffect ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.5).delay(0.3), value: showCompletionEffect)
            
            Spacer()
            
            Button(action: resetAll) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("إعادة")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
            .opacity(showCompletionEffect ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.4).delay(0.6), value: showCompletionEffect)
            
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text("العودة للرئيسية")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(gradientColors[0])
            }
            .opacity(showCompletionEffect ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.4).delay(0.8), value: showCompletionEffect)
            
            Spacer().frame(height: 40)
        }
        .onAppear {
            showCompletionEffect = true
        }
    }
    
    // MARK: - Actions
    private func handleTap() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Pulse animation
        showPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showPulse = false
        }
        
        withAnimation {
            currentCount += 1
        }
        
        // Check if current zikr is completed
        if currentCount >= currentZikr.repetitions {
            // Small delay then move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                if currentIndex < group.azkar.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex += 1
                        currentCount = 0
                    }
                } else {
                    // All azkar completed!
                    if let branch = branchForGroup(group) {
                        prayerTracker.markBranchDone(branch)
                    }
                    withAnimation {
                        isCompleted = true
                    }
                }
            }
        }
    }
    
    private func goToNext() {
        guard currentIndex < group.azkar.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
            currentCount = 0
        }
    }
    
    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex -= 1
            currentCount = 0
        }
    }
    
    private func resetAll() {
        withAnimation {
            currentIndex = 0
            currentCount = 0
            isCompleted = false
            showCompletionEffect = false
        }
    }
}

#Preview {
    NavigationStack {
        AzkarGroupView(group: AzkarData.allGroups[0])
            .environmentObject(PrayerTrackingStore())
    }
}
