import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    private let onFinish: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 130), spacing: 8)
    ]

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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    nameCard
                    goalCard
                    remindersCard

                    PrimaryButton(
                        LocalizedStrings.start,
                        systemImage: "arrow.right",
                        isDisabled: viewModel.canComplete == false
                    ) {
                        isNameFocused = false
                        Task {
                            await viewModel.completeOnboarding()
                            onFinish()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
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
        }
    }

    private var nameCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.onboardingNameTitle)

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
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStrings.onboardingWelcomeTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.onboardingWelcomeText)
                .font(.body)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
    }

    private var goalCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.onboardingGoalTitle)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(FocusGoal.allCases) { goal in
                    ChoiceChip(
                        title: goal.title,
                        isSelected: goal == viewModel.selectedGoal
                    ) {
                        viewModel.selectedGoal = goal
                    }
                }
            }
        }
    }

    private var remindersCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.onboardingReminderTitle)

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
    OnboardingView(viewModel: OnboardingViewModel(userName: "Максим"))
}
#endif
