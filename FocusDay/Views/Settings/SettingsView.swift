import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel
    @FocusState private var isNameFocused: Bool

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel())
    }

    @MainActor
    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    profileCard
                    goalCard
                    reminderCard

                    PrimaryButton(
                        LocalizedStrings.save,
                        systemImage: "checkmark",
                        isDisabled: viewModel.isSaving
                    ) {
                        guard viewModel.isSaving == false else { return }
                        isNameFocused = false
                        appState.beginSaving(.settings)

                        Task {
                            let didSave = await viewModel.saveSettings()

                            if didSave {
                                appState.completeSaving(.settings)
                            } else {
                                appState.cancelFeedback()
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .tabBarContentPadding()
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedStrings.done) {
                        isNameFocused = false
                    }
                }
            }
            .overlay(alignment: .top) {
                SaveFeedbackOverlay(status: appState.status(for: .settings))
                    .padding(.top, 8)
            }
        }
    }

    private var profileCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.profile)

            TextField(
                "",
                text: $viewModel.userName,
                prompt: Text(LocalizedStrings.namePlaceholder)
                    .foregroundStyle(AppTheme.placeholderText)
            )
            .focused($isNameFocused)
            .textContentType(.name)
            .textInputAutocapitalization(.words)
            .textFieldStyle(AppTextFieldStyle())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.settings)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.settingsSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.selectedGoal)

            Picker(LocalizedStrings.selectedGoal, selection: $viewModel.selectedGoal) {
                ForEach(FocusGoal.allCases) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var reminderCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.notifications)

            DatePicker(
                LocalizedStrings.morningReminder,
                selection: $viewModel.morningReminderTime,
                displayedComponents: .hourAndMinute
            )

            DatePicker(
                LocalizedStrings.eveningReminder,
                selection: $viewModel.eveningReminderTime,
                displayedComponents: .hourAndMinute
            )
        }
    }
}

#if DEBUG
#Preview {
    SettingsView(viewModel: SettingsViewModel(userName: "Максим"))
        .environmentObject(AppState())
}

#Preview(
    "Настройки: длинный контент",
    traits: .fixedLayout(width: 320, height: 568)
) {
    MainTabView(initialTab: .settings)
        .modelContainer(PreviewData.previewContainer())
        .environment(\.dynamicTypeSize, .accessibility2)
}
#endif
