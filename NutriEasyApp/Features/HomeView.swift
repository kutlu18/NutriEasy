import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView()
                DashboardSummaryView(dashboard: appState.dashboard)
                QuickActionsView()
                TodayMealsView(meals: appState.meals)
                NuriInlineCard()
            }
            .padding()
        }
        .background(NutriColor.background)
        .navigationTitle("Bugün")
        .toolbar {
            NavigationLink {
                NuriChatView()
            } label: {
                Image(systemName: "sparkles")
            }
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Merhaba")
                .font(.title.bold())
            Text("Bugün kararları kolaylaştırıyoruz.")
                .foregroundStyle(NutriColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardSummaryView: View {
    var dashboard: TodayDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(dashboard.remainingCalories)")
                    .font(.system(size: 44, weight: .bold))
                Text("kcal kaldı")
                    .foregroundStyle(NutriColor.muted)
            }

            ProgressView(value: Double(dashboard.consumedCalories), total: Double(dashboard.calorieTarget))
                .tint(NutriColor.leaf)

            HStack(spacing: 10) {
                MetricCard(title: "Protein", value: "\(dashboard.consumedMacros.proteinGr)/\(dashboard.macroTargets.proteinGr) g", subtitle: "Bugün", tint: NutriColor.mint)
                MetricCard(title: "Su", value: "\(dashboard.hydration.current)/\(dashboard.hydration.target)", subtitle: dashboard.hydration.unit, tint: .blue)
            }
        }
        .padding()
        .background(NutriColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı ekle")
                .font(.headline)
            HStack(spacing: 10) {
                action("Fotoğraf", "camera", .photoCapture)
                action("Yazı", "text.bubble", .textMeal)
            }
        }
    }

    private func action(_ title: String, _ icon: String, _ route: AppRoute) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NutriColor.surface)
            .foregroundStyle(NutriColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct TodayMealsView: View {
    var meals: [Meal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bugünkü öğünler")
                .font(.headline)
            ForEach(meals) { meal in
                NavigationLink(value: AppRoute.mealDetail(meal.id)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.mealType.title)
                                .font(.caption)
                                .foregroundStyle(NutriColor.leaf)
                            Text(meal.title)
                                .font(.headline)
                                .foregroundStyle(NutriColor.ink)
                        }
                        Spacer()
                        Text("\(meal.totalCalories) kcal")
                            .font(.subheadline.bold())
                            .foregroundStyle(NutriColor.muted)
                    }
                    .padding()
                    .background(NutriColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

private struct NuriInlineCard: View {
    var body: some View {
        NavigationLink {
            NuriChatView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(NutriColor.leaf)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nuri'ye sor")
                        .font(.headline)
                        .foregroundStyle(NutriColor.ink)
                    Text("Akşam ne yemeliyim, proteinim düşük mü?")
                        .font(.caption)
                        .foregroundStyle(NutriColor.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(NutriColor.muted)
            }
            .padding()
            .background(NutriColor.mint.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
