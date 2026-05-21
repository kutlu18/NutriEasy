import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                ProgressView(value: Double(step + 1), total: 5)
                    .tint(NutriColor.leaf)

                Group {
                    switch step {
                    case 0:
                        GoalStep(goal: $appState.user.selectedGoal)
                    case 1:
                        ProfileStep(user: $appState.user)
                    case 2:
                        ActivityStep(activity: $appState.user.activityLevel)
                    case 3:
                        LoggingPreferenceStep(method: $appState.user.preferredLoggingMethod)
                    default:
                        SetupSummaryStep(user: appState.user)
                    }
                }

                Spacer(minLength: 0)

                PrimaryButton(title: step == 4 ? "NutriEasy'e başla" : "Devam et") {
                    if step == 4 {
                        appState.completeOnboarding()
                    } else {
                        step += 1
                    }
                }
            }
            .padding()
            .background(NutriColor.background.ignoresSafeArea())
            .navigationTitle("NutriEasy")
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            step -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }
}

struct GoalStep: View {
    @Binding var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hedefin ne?")
                .font(.largeTitle.bold())
            Text("Günlük hedeflerini buna göre hesaplayacağız.")
                .foregroundStyle(NutriColor.muted)
            ForEach(Goal.allCases) { item in
                Button { goal = item } label: {
                    SelectionTile(title: item.title, systemImage: icon(for: item), selected: goal == item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func icon(for goal: Goal) -> String {
        switch goal {
        case .weightLoss: "flame"
        case .gainMuscle: "figure.strengthtraining.traditional"
        case .maintain: "leaf"
        case .fasting: "moon"
        }
    }
}

struct ProfileStep: View {
    @Binding var user: UserProfile

    var body: some View {
        Form {
            Section("Seni biraz tanıyalım") {
                Picker("Cinsiyet", selection: $user.gender) {
                    ForEach(Gender.allCases) { Text($0.title).tag($0) }
                }
                Stepper("Yaş: \(user.age)", value: $user.age, in: 16...80)
                Stepper("Boy: \(user.heightCm) cm", value: $user.heightCm, in: 130...220)
                Stepper("Kilo: \(user.weightKg) kg", value: $user.weightKg, in: 35...180)
                Stepper("Hedef kilo: \(user.targetWeightKg ?? user.weightKg) kg", value: Binding(
                    get: { user.targetWeightKg ?? user.weightKg },
                    set: { user.targetWeightKg = $0 }
                ), in: 35...180)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

struct ActivityStep: View {
    @Binding var activity: ActivityLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Günün nasıl geçiyor?")
                .font(.largeTitle.bold())
            ForEach(ActivityLevel.allCases) { item in
                Button { activity = item } label: {
                    SelectionTile(title: item.title, systemImage: "figure.walk", selected: activity == item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LoggingPreferenceStep: View {
    @Binding var method: LoggingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sana en kolay gelen yol hangisi?")
                .font(.largeTitle.bold())
            ForEach(LoggingMethod.allCases) { item in
                Button { method = item } label: {
                    SelectionTile(title: item.title, systemImage: icon(for: item), selected: method == item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func icon(for method: LoggingMethod) -> String {
        switch method {
        case .photo: "camera"
        case .text: "text.bubble"
        case .mixed: "sparkles"
        }
    }
}

struct SetupSummaryStep: View {
    var user: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hedeflerin hazır")
                .font(.largeTitle.bold())
            MetricCard(title: "Günlük kalori", value: "1900 kcal", subtitle: user.selectedGoal.title, tint: NutriColor.mint)
            MetricCard(title: "Protein", value: "125 g", subtitle: "Kas kütlesini korumaya odaklı", tint: NutriColor.amber)
            MetricCard(title: "Giriş tercihi", value: user.preferredLoggingMethod.title, subtitle: "Ana ekranda öne çıkarılacak", tint: NutriColor.coral)
        }
    }
}
