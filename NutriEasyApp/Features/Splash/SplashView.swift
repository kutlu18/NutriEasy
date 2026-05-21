import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(NutriColor.leaf)

            Text("NutriEasy")
                .font(.largeTitle.bold())
                .foregroundStyle(NutriColor.ink)

            Text("Beslenme takibi, akıllı öğün girişi ve Nuri desteği.")
                .multilineTextAlignment(.center)
                .foregroundStyle(NutriColor.muted)

            ProgressView()
                .tint(NutriColor.leaf)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(NutriColor.background.ignoresSafeArea())
        .task {
            await appState.bootstrapApp()
        }
    }
}
