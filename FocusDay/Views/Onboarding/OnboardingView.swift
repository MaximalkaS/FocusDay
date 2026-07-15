import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var activeReminderPicker: SettingsReminderPicker?
    @FocusState private var isNameFocused: Bool
    private let onFinish: () -> Void

    @MainActor
    init(onFinish: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel())
        self.onFinish = onFinish
    }

    @MainActor
    init(viewModel: OnboardingViewModel, onFinish: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.screenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        nameCard
                        goalCard
                        remindersCard
                        startButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                    .dismissKeyboardOnBackgroundTap {
                        isNameFocused = false
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedStrings.done) {
                        isNameFocused = false
                    }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.onboardingWelcomeTitle)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStrings.onboardingWelcomeText)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameCard: some View {
        SettingsSurfaceCard {
            Text(LocalizedStrings.onboardingNameTitle)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppTheme.text)

            SettingsNameField(text: $viewModel.userName, isFocused: $isNameFocused)
        }
    }

    private var goalCard: some View {
        SettingsSurfaceCard {
            Text(LocalizedStrings.onboardingGoalTitle)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppTheme.text)

            TwoColumnSelectionGrid(
                items: FocusGoal.allCases,
                horizontalSpacing: 10,
                verticalSpacing: 12
            ) { goal in
                SettingsGoalOptionCard(
                    goal: goal,
                    isSelected: goal == viewModel.selectedGoal
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.selectedGoal = goal
                    }
                }
            }
        }
    }

    private var remindersCard: some View {
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

                AppToggle(
                    isOn: $viewModel.areNotificationsEnabled,
                    accessibilityLabel: LocalizedStrings.notifications
                )
            }

            VStack(spacing: 0) {
                SettingsReminderTimeRow(
                    systemImage: "sun.max.fill",
                    iconColor: AppTheme.primaryBlue,
                    title: LocalizedStrings.morningReminderTitle,
                    subtitle: LocalizedStrings.morningReminder,
                    time: viewModel.morningReminderTime
                ) {
                    isNameFocused = false
                    activeReminderPicker = .morning
                }

                Divider()
                    .overlay(Color(hex: "D7E8FA"))
                    .padding(.leading, 64)

                SettingsReminderTimeRow(
                    systemImage: "moon.stars.fill",
                    iconColor: AppTheme.primaryBlue,
                    title: LocalizedStrings.eveningReminderTitle,
                    subtitle: LocalizedStrings.eveningReminder,
                    time: viewModel.eveningReminderTime
                ) {
                    isNameFocused = false
                    activeReminderPicker = .evening
                }
            }
            .opacity(viewModel.areNotificationsEnabled ? 1 : 0.48)
            .disabled(viewModel.areNotificationsEnabled == false)
        }
    }

    private var startButton: some View {
        Button {
            isNameFocused = false
            Task {
                await viewModel.completeOnboarding()
                onFinish()
            }
        } label: {
            Text(LocalizedStrings.start)
                .font(AppTypography.primaryButton)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 58)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(hex: "0A6BFF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.primaryBlue.opacity(0.24), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.canComplete == false)
        .opacity(viewModel.canComplete ? 1 : 0.58)
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
    OnboardingView(viewModel: OnboardingViewModel(userName: "Максим"))
}

#Preview(
    "Онбординг: iPhone SE",
    traits: .fixedLayout(width: 320, height: 760)
) {
    OnboardingView(viewModel: OnboardingViewModel(userName: ""))
}

#Preview("Цели: остаток на всю ширину") {
    SettingsSurfaceCard {
        Text(LocalizedStrings.onboardingGoalTitle)
            .font(AppTypography.sectionTitle)
            .foregroundStyle(AppTheme.text)

        TwoColumnSelectionGrid(items: FocusGoal.allCases) { goal in
            SettingsGoalOptionCard(goal: goal, isSelected: goal == .personal) {}
        }
    }
    .padding(16)
    .background(AppTheme.screenBackground)
}

#Preview("Sheet времени онбординга") {
    SettingsReminderTimePickerSheet(
        title: LocalizedStrings.morningReminderTitle,
        time: .constant(Date())
    )
}
#endif
