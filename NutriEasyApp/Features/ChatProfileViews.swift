import SwiftUI

struct NuriChatView: View {
    @EnvironmentObject private var appState: AppState
    @State private var input = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(appState.chatMessages) { message in
                        HStack {
                            if message.role == .user { Spacer() }
                            Text(message.text)
                                .padding(12)
                                .background(message.role == .user ? NutriColor.leaf : NutriColor.surface)
                                .foregroundStyle(message.role == .user ? .white : NutriColor.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if message.role == .assistant { Spacer() }
                        }
                    }
                }
                .padding()
            }

            HStack(spacing: 10) {
                TextField("Nuri'ye sor", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button {
                    appState.sendChat(input)
                    input = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(NutriColor.leaf)
            }
            .padding()
            .background(NutriColor.background)
        }
        .background(NutriColor.background)
        .navigationTitle("Nuri")
    }
}

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(NutriColor.leaf)
                        VStack(alignment: .leading) {
                            Text(appState.user.name)
                                .font(.headline)
                            Text(appState.user.email)
                                .font(.caption)
                                .foregroundStyle(NutriColor.muted)
                        }
                    }
                }

                Section("Hedefler") {
                    LabeledContent("Hedef", value: appState.user.selectedGoal.title)
                    LabeledContent("Aktivite", value: appState.user.activityLevel.title)
                    LabeledContent("Öğün girişi", value: appState.user.preferredLoggingMethod.title)
                }

                Section {
                    NavigationLink("Bildirimler") { NotificationSettingsView() }
                    Button("Çıkış yap") {
                        appState.signOut()
                    }
                }
            }
            .navigationTitle("Profil")
        }
    }
}

struct NotificationSettingsView: View {
    @State private var mealReminder = true
    @State private var waterReminder = true
    @State private var dailySummary = true

    var body: some View {
        Form {
            Toggle("Öğün hatırlatıcıları", isOn: $mealReminder)
            Toggle("Su hatırlatıcıları", isOn: $waterReminder)
            Toggle("Gün sonu özeti", isOn: $dailySummary)
        }
        .navigationTitle("Bildirimler")
    }
}
