import SwiftUI

struct FoodHubView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Yemek ekle")
                        .font(.largeTitle.bold())

                    Text("Metin girişi, hızlı ekleme ve besin araması aynı alanda toplanır.")
                        .foregroundStyle(NutriColor.muted)

                    NavigationLink {
                        TextMealInputView()
                    } label: {
                        FoodShortcutCard(title: "Yazarak ekle", subtitle: "AI ile basit öğün analizi", systemImage: "text.bubble")
                    }

                    NavigationLink {
                        FoodSearchView()
                    } label: {
                        FoodShortcutCard(title: "Food search", subtitle: "Kendi besin veritabanında ara", systemImage: "magnifyingglass")
                    }

                    NavigationLink {
                        QuickAddView()
                    } label: {
                        FoodShortcutCard(title: "Quick add", subtitle: "Sık kullanılan öğünleri hızlı ekle", systemImage: "plus.circle")
                    }
                }
                .padding()
            }
            .background(NutriColor.background)
            .navigationTitle("Food")
        }
    }
}

struct FoodSearchView: View {
    @State private var query = ""

    private let suggestions: [FoodSearchResult] = [
        FoodSearchResult(name: "Greek yogurt", calories: 97, protein: 10, carbs: 4, fat: 5),
        FoodSearchResult(name: "Grilled chicken breast", calories: 165, protein: 31, carbs: 0, fat: 4),
        FoodSearchResult(name: "Brown rice", calories: 111, protein: 3, carbs: 23, fat: 1),
        FoodSearchResult(name: "Oatmeal", calories: 68, protein: 2, carbs: 12, fat: 1)
    ]

    var filteredSuggestions: [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return suggestions }
        return suggestions.filter { $0.name.lowercased().contains(trimmed) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Food search")
                    .font(.largeTitle.bold())

                TextField("Ara", text: $query)
                    .textFieldStyle(.roundedBorder)

                if filteredSuggestions.isEmpty {
                    EmptyStateView(
                        title: "Sonuç yok",
                        subtitle: "Bu sorgu için şimdilik eşleşme bulunamadı.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    ForEach(filteredSuggestions) { food in
                        FoodSearchRow(food: food)
                    }
                }
            }
            .padding()
        }
        .background(NutriColor.background)
        .navigationTitle("Search")
    }
}

struct QuickAddView: View {
    private let items: [QuickAddItem] = [
        QuickAddItem(title: "Yumurta + peynir", calories: 290, protein: 21),
        QuickAddItem(title: "Tavuk salata", calories: 340, protein: 31),
        QuickAddItem(title: "Yoğurt + yulaf", calories: 220, protein: 14),
        QuickAddItem(title: "Meyve + badem", calories: 180, protein: 4)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick add")
                    .font(.largeTitle.bold())
                Text("Sık kullanılan öğünleri tek dokunuşla eklemek için başlangıç kalıbı.")
                    .foregroundStyle(NutriColor.muted)

                ForEach(items) { item in
                    Button {
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text("\(item.calories) kcal · \(item.protein) g protein")
                                    .font(.caption)
                                    .foregroundStyle(NutriColor.muted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(NutriColor.leaf)
                        }
                        .padding()
                        .background(NutriColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(NutriColor.background)
        .navigationTitle("Quick add")
    }
}

private struct FoodShortcutCard: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(NutriColor.leaf)
                .frame(width: 36, height: 36)
                .background(NutriColor.mint.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(NutriColor.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(NutriColor.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(NutriColor.muted)
        }
        .padding()
        .background(NutriColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct FoodSearchRow: View {
    var food: FoodSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(food.name)
                .font(.headline)
            Text("\(food.calories) kcal · P \(food.protein) · C \(food.carbs) · F \(food.fat)")
                .font(.caption)
                .foregroundStyle(NutriColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(NutriColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct QuickAddItem: Identifiable {
    let id = UUID().uuidString
    let title: String
    let calories: Int
    let protein: Int
}

private struct FoodSearchResult: Identifiable {
    let id = UUID().uuidString
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}
