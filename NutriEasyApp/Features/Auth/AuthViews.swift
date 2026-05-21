import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var mode: AuthMode = .signIn
    @State private var email = "umut@example.com"
    @State private var password = "12345678"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Hesabına giriş yap")
                    .font(.largeTitle.bold())

                Text("Supabase Auth hazır olduğunda bu ekran gerçek oturum açma akışına bağlanacak.")
                    .foregroundStyle(NutriColor.muted)

                Picker("Mod", selection: $mode) {
                    ForEach(AuthMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("E-posta", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Şifre", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                PrimaryButton(title: mode.buttonTitle, systemImage: "arrow.right") {
                    appState.signInMock()
                }

                Button("Demo ile devam et") {
                    appState.signInMock()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NutriColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding()
            .background(NutriColor.background.ignoresSafeArea())
        }
    }
}

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn
    case signUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn: "Giriş"
        case .signUp: "Kayıt"
        }
    }

    var buttonTitle: String {
        switch self {
        case .signIn: "Giriş yap"
        case .signUp: "Hesap oluştur"
        }
    }
}
