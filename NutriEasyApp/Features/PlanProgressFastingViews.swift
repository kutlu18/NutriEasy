import SwiftUI

struct DailyPlanView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bugünün planı")
                        .font(.largeTitle.bold())
                    ForEach(MockData.plannedMeals) { meal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(meal.mealType.title)
                                    .font(.caption)
                                    .foregroundStyle(NutriColor.leaf)
                                Spacer()
                                Text("\(meal.calories) kcal")
                                    .font(.subheadline.bold())
                            }
                            Text(meal.title)
                                .font(.headline)
                            Text(meal.description)
                                .font(.subheadline)
                                .foregroundStyle(NutriColor.muted)
                            Button("Alternatif öner") {}
                                .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(NutriColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .background(NutriColor.background)
            .navigationTitle("Plan")
        }
    }
}

struct ProgressDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("İlerleme")
                        .font(.largeTitle.bold())
                    HStack(spacing: 10) {
                        MetricCard(title: "Seri", value: "5 gün", subtitle: "Kayıt tutuldu", tint: NutriColor.mint)
                        MetricCard(title: "Ortalama", value: "1780 kcal", subtitle: "7 gün", tint: NutriColor.amber)
                    }
                    MetricCard(title: "Nuri içgörüsü", value: "Protein iyi gidiyor", subtitle: "Akşam karbonhidrat porsiyonlarını biraz küçültmek hedefe yaklaştırır.", tint: NutriColor.coral)
                }
                .padding()
            }
            .background(NutriColor.background)
            .navigationTitle("Takip")
        }
    }
}

struct FastingView: View {
    @State private var isActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(isActive ? "Oruç aktif" : "Oruç hazır")
                    .font(.largeTitle.bold())
                Text("16:8 planı")
                    .foregroundStyle(NutriColor.muted)
                ZStack {
                    Circle()
                        .stroke(NutriColor.mint.opacity(0.5), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: isActive ? 0.42 : 0.0)
                        .stroke(NutriColor.leaf, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(isActive ? "6s 40dk kaldı" : "Başlat")
                        .font(.title2.bold())
                }
                .frame(width: 220, height: 220)

                PrimaryButton(title: isActive ? "Orucu bitir" : "Orucu başlat", systemImage: isActive ? "stop.fill" : "play.fill") {
                    isActive.toggle()
                }
                Spacer()
            }
            .padding()
            .background(NutriColor.background)
            .navigationTitle("Oruç")
        }
    }
}
