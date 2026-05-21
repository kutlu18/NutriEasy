import SwiftUI

enum NutriColor {
    static let background = Color(red: 0.97, green: 0.98, blue: 0.95)
    static let surface = Color.white
    static let ink = Color(red: 0.09, green: 0.12, blue: 0.11)
    static let muted = Color(red: 0.45, green: 0.49, blue: 0.47)
    static let leaf = Color(red: 0.18, green: 0.55, blue: 0.34)
    static let mint = Color(red: 0.77, green: 0.91, blue: 0.80)
    static let coral = Color(red: 0.93, green: 0.42, blue: 0.34)
    static let amber = Color(red: 0.95, green: 0.66, blue: 0.22)
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String = "arrow.right"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(NutriColor.leaf)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var subtitle: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(NutriColor.muted)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(NutriColor.ink)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(NutriColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SelectionTile: View {
    var title: String
    var subtitle: String? = nil
    var systemImage: String
    var selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 34, height: 34)
                .background(selected ? NutriColor.leaf : NutriColor.mint.opacity(0.35))
                .foregroundStyle(selected ? .white : NutriColor.leaf)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(NutriColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(NutriColor.muted)
                }
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(NutriColor.leaf)
            }
        }
        .padding()
        .background(NutriColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? NutriColor.leaf : Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
