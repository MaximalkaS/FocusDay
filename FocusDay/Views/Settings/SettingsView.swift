import SwiftUI

struct SettingsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel
    @State private var activeReminderPicker: SettingsReminderPicker?
    @FocusState private var isNameFocused: Bool

    private let floatingSavePanelReservedHeight: CGFloat = 104

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
                VStack(alignment: .leading, spacing: 16) {
                    header
                    profileCard
                    goalSection
                    notificationCard

                    if let saveErrorMessage = viewModel.saveErrorMessage {
                        Text(saveErrorMessage)
                            .font(AppTypography.validation)
                            .foregroundStyle(Color(hex: "FF5A5F"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .dismissKeyboardOnBackgroundTap {
                    isNameFocused = false
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(
                .bottom,
                MainTabLayout.scrollContentBottomInset + floatingSavePanelAdditionalInset,
                for: .scrollContent
            )
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedStrings.done) {
                        isNameFocused = false
                    }
                }
            }
            .animation(AppMotion.quick(reduceMotion), value: viewModel.hasUnsavedChanges)
            .overlay(alignment: .top) {
                SaveFeedbackOverlay(status: appState.status(for: .settings))
                    .padding(.top, 8)
            }
            .overlay(alignment: .bottom) {
                if viewModel.hasUnsavedChanges {
                    floatingSavePanel
                        .padding(.bottom, MainTabLayout.barBodyHeight + 14)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(item: $activeReminderPicker) { picker in
                SettingsReminderTimePickerSheet(
                    title: picker.title,
                    time: reminderTimeBinding(for: picker)
                )
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var floatingSavePanelAdditionalInset: CGFloat {
        viewModel.hasUnsavedChanges ? floatingSavePanelReservedHeight : 0
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStrings.settings)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(LocalizedStrings.settingsSubtitle)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileCard: some View {
        SettingsSurfaceCard {
            Text(LocalizedStrings.profile)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppTheme.text)

            SettingsNameField(text: $viewModel.userName, isFocused: $isNameFocused)
        }
    }

    private var goalSection: some View {
        SettingsSurfaceCard {
            Text(LocalizedStrings.onboardingGoalTitle)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppTheme.text)

            TwoColumnSelectionGrid(
                items: FocusGoal.allCases,
                horizontalSpacing: 10,
                verticalSpacing: 12
            ) { goal in
                goalButton(goal)
            }
        }
    }

    private var notificationCard: some View {
        SettingsSurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStrings.notifications)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppTheme.text)

                    Text(LocalizedStrings.notificationsSubtitle)
                        .font(AppTypography.screenSubtitle)
                        .foregroundStyle(Color(hex: "64748B"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $viewModel.areNotificationsEnabled)
                    .labelsHidden()
                    .tint(AppTheme.primaryBlue)
            }

            VStack(spacing: 0) {
                SettingsReminderTimeRow(
                    systemImage: "sun.max.fill",
                    iconColor: AppTheme.primaryBlue,
                    title: LocalizedStrings.morningReminderTitle,
                    subtitle: LocalizedStrings.morningReminderSubtitle,
                    time: viewModel.morningReminderTime
                ) {
                    activeReminderPicker = .morning
                }

                Divider()
                    .overlay(Color(hex: "D7E8FA"))
                    .padding(.leading, 64)

                SettingsReminderTimeRow(
                    systemImage: "moon.stars.fill",
                    iconColor: AppTheme.primaryBlue,
                    title: LocalizedStrings.eveningReminderTitle,
                    subtitle: LocalizedStrings.eveningReminderSubtitle,
                    time: viewModel.eveningReminderTime
                ) {
                    activeReminderPicker = .evening
                }
            }
            .opacity(viewModel.areNotificationsEnabled ? 1 : 0.48)
            .disabled(viewModel.areNotificationsEnabled == false)
        }
    }

    private var floatingSavePanel: some View {
        saveButton
            .padding(.horizontal, 16)
    }

    private var saveButton: some View {
        Button {
            saveSettings()
        } label: {
            Text(LocalizedStrings.saveChanges)
                .font(AppTypography.primaryButton)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(AppTheme.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.primaryBlue.opacity(0.24), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving || viewModel.hasUnsavedChanges == false)
        .opacity(viewModel.isSaving ? 0.72 : 1)
    }

    private func goalButton(_ goal: FocusGoal) -> some View {
        SettingsGoalOptionCard(
            goal: goal,
            isSelected: viewModel.selectedGoal == goal
        ) {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.selectedGoal = goal
            }
        }
    }

    private func saveSettings() {
        guard viewModel.isSaving == false, viewModel.hasUnsavedChanges else { return }
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

    private func reminderTimeBinding(for picker: SettingsReminderPicker) -> Binding<Date> {
        switch picker {
        case .morning:
            $viewModel.morningReminderTime
        case .evening:
            $viewModel.eveningReminderTime
        }
    }
}

#if DEBUG
#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            userName: "Алексей",
            morningReminderTime: SettingsPreviewFactory.date(hour: 9),
            eveningReminderTime: SettingsPreviewFactory.date(hour: 20),
            areNotificationsEnabled: true
        )
    )
        .environmentObject(AppState())
}

#Preview("Выбранная цель с галочкой") {
    VStack(spacing: 16) {
        SettingsGoalOptionCard(goal: .study, isSelected: true) {}
        SettingsGoalOptionCard(goal: .sport, isSelected: false) {}
    }
    .padding(24)
    .frame(width: 320)
    .background(AppTheme.screenBackground)
}

#Preview(
    "Настройки: компактный экран",
    traits: .fixedLayout(width: 320, height: 760)
) {
    MainTabView(initialTab: .settings)
        .modelContainer(PreviewData.previewContainer())
}

#Preview(
    "Настройки: длинный контент",
    traits: .fixedLayout(width: 320, height: 568)
) {
    MainTabView(initialTab: .settings)
        .modelContainer(PreviewData.previewContainer())
        .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview(
    "Уведомление: длинный подзаголовок SE",
    traits: .fixedLayout(width: 320, height: 220)
) {
    SettingsSurfaceCard {
        SettingsReminderTimeRow(
            systemImage: "sun.max.fill",
            iconColor: AppTheme.primaryBlue,
            title: LocalizedStrings.morningReminderTitle,
            subtitle: "Очень длинный текст подзаголовка, который должен переноситься и не сжимать кнопку выбора времени",
            time: SettingsPreviewFactory.date(hour: 9)
        ) {}
    }
    .padding(16)
    .background(AppTheme.screenBackground)
}

#Preview("Sheet выбора утреннего времени") {
    ReminderPickerSheetPreview(
        title: LocalizedStrings.morningReminderTitle,
        initialHour: 9
    )
}

#Preview("Sheet выбора вечернего времени") {
    ReminderPickerSheetPreview(
        title: LocalizedStrings.eveningReminderTitle,
        initialHour: 20
    )
}

private enum SettingsPreviewFactory {
    static func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

private struct ReminderPickerSheetPreview: View {
    let title: String
    @State private var time: Date

    init(title: String, initialHour: Int) {
        self.title = title
        _time = State(initialValue: SettingsPreviewFactory.date(hour: initialHour))
    }

    var body: some View {
        Color(hex: "F6F9FE")
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                SettingsReminderTimePickerSheet(title: title, time: $time)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
    }
}
#endif
