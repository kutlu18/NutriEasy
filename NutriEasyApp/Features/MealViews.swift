import SwiftUI

struct PhotoCaptureView: View {
    @EnvironmentObject private var appState: AppState
    @State private var navigate = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(NutriColor.leaf)
            Text("Fotoğrafla öğün girişi")
                .font(.title.bold())
            Text("Fotoğraf akışı eklendiğinde bu ekranda fotoğraf çekilecek veya galeriden seçilecek.")
                .multilineTextAlignment(.center)
                .foregroundStyle(NutriColor.muted)
            PrimaryButton(title: "Örnek analiz başlat", systemImage: "sparkles") {
                Task {
                    await appState.analyzeMeal(from: "photo", mealType: .lunch)
                    navigate = true
                }
            }
            .disabled(appState.isAnalyzingMeal)
        }
        .padding()
        .navigationTitle("Fotoğraf")
        .navigationDestination(isPresented: $navigate) {
            MealAnalysisView()
        }
    }
}

struct TextMealInputView: View {
    @EnvironmentObject private var appState: AppState
    @State private var text = "Grilled chicken, rice and yogurt"
    @State private var mealType: MealType = .lunch
    @State private var navigate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Öğün", selection: $mealType) {
                ForEach(MealType.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            TextEditor(text: $text)
                .frame(minHeight: 180)
                .padding(8)
                .background(NutriColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if appState.isAnalyzingMeal {
                ProgressView("Analiz ediliyor...")
                    .tint(NutriColor.leaf)
            }

            if let error = appState.mealFlowError {
                InlineWarning(text: error)
            }

            PrimaryButton(title: "Analiz et", systemImage: "sparkles") {
                Task {
                    await appState.analyzeMeal(from: text, mealType: mealType)
                    navigate = appState.selectedAnalysis != nil
                }
            }
            .disabled(appState.isAnalyzingMeal)

            Spacer()
        }
        .padding()
        .background(NutriColor.background)
        .navigationTitle("Yazarak ekle")
        .navigationDestination(isPresented: $navigate) {
            MealAnalysisView()
        }
    }
}

struct MealAnalysisView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if let analysis = appState.selectedAnalysis {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Analiz sonucu")
                        .font(.largeTitle.bold())

                    if let error = appState.mealFlowError {
                        InlineWarning(text: error)
                    }

                    MetricCard(title: "Toplam", value: "\(analysis.totalCalories) kcal", subtitle: "Güven: \(analysis.confidence.title)", tint: NutriColor.mint)
                    HStack(spacing: 10) {
                        MetricCard(title: "Protein", value: "\(analysis.macros.proteinGr) g", subtitle: "Tahmini", tint: NutriColor.amber)
                        MetricCard(title: "Karbonhidrat", value: "\(analysis.macros.carbsGr) g", subtitle: "Tahmini", tint: NutriColor.coral)
                    }
                    ForEach(analysis.detectedItems) { item in
                        MealItemRow(item: item)
                    }
                    ForEach(analysis.warnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(NutriColor.amber)
                    }
                    PrimaryButton(title: appState.isSavingMeal ? "Kaydediliyor" : "Öğünü kaydet", systemImage: "checkmark") {
                        Task {
                            await appState.saveAnalysis()
                            dismiss()
                        }
                    }
                    .disabled(appState.isSavingMeal)
                    Button("Doğal dille düzelt") {}
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                    Text("Analiz bulunamadı")
                        .font(.headline)
                        .foregroundStyle(NutriColor.muted)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
            }
        }
        .background(NutriColor.background)
        .navigationTitle("Analiz")
    }
}

struct MealDetailView: View {
    @EnvironmentObject private var appState: AppState
    var mealID: Meal.ID

    var meal: Meal? {
        appState.meals.first { $0.id == mealID }
    }

    var body: some View {
        ScrollView {
            if let meal {
                VStack(alignment: .leading, spacing: 16) {
                    Text(meal.title)
                        .font(.largeTitle.bold())
                    MetricCard(title: meal.mealType.title, value: "\(meal.totalCalories) kcal", subtitle: "\(meal.macros.proteinGr) g protein", tint: NutriColor.mint)
                    ForEach(meal.items) { item in
                        MealItemRow(item: item)
                    }
                    Button(role: .destructive) {} label: {
                        Label("Öğünü sil", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .background(NutriColor.background)
    }
}

struct MealItemRow: View {
    var item: MealItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text("\(item.quantity, specifier: "%.0f") \(item.unit)")
                    .font(.caption)
                    .foregroundStyle(NutriColor.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.calories) kcal")
                    .font(.subheadline.bold())
                Text("P \(item.proteinGr) C \(item.carbsGr) F \(item.fatGr)")
                    .font(.caption)
                    .foregroundStyle(NutriColor.muted)
            }
        }
        .padding()
        .background(NutriColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct InlineWarning: View {
    var text: String

    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(NutriColor.amber)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NutriColor.amber.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
