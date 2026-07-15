import SwiftUI

struct CreateTaskView: View {
    enum FocusedField: Hashable {
        case title
        case description
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var premiumAccess = PremiumAccessManager.shared
    @StateObject private var viewModel: CreateTaskViewModel
    @State private var isShowingPremiumPlaceholder = false
    @FocusState private var focusedField: FocusedField?

    private let descriptionFieldsCardId = "descriptionFieldsCard"
    private let onSaved: () -> Void

    @MainActor
    init(
        task: TaskItem? = nil,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: CreateTaskViewModel(task: task))
        self.onSaved = onSaved
    }

    @MainActor
    init(viewModel: CreateTaskViewModel, onSaved: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        cancelButton
                        header
                        titleFields
                        categoryCard
                        priorityCard
                        durationCard
                        repeatCard

                        if let validationMessage = viewModel.validationMessage {
                            Text(validationMessage)
                                .font(AppTypography.validation)
                                .foregroundStyle(AppTheme.danger)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                    .dismissKeyboardOnBackgroundTap {
                        focusedField = nil
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .keyboardAwareTextEditorScroll(
                    focusedField: focusedField,
                    targetField: .description,
                    text: viewModel.taskDescription,
                    targetId: descriptionFieldsCardId,
                    proxy: proxy
                )
            }
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedStrings.done) {
                        focusedField = nil
                    }
                }
            }
            .alert(LocalizedStrings.premiumFeatureTitle, isPresented: $isShowingPremiumPlaceholder) {
                Button(LocalizedStrings.gotIt, role: .cancel) {}
            } message: {
                Text(LocalizedStrings.premiumFeatureMessage)
            }
            .onChange(of: premiumAccess.currentPlan) { _, _ in
                if premiumAccess.canUseRepeatingTasks == false {
                    viewModel.isRepeating = false
                }
            }
        }
    }

    private var cancelButton: some View {
        Button(LocalizedStrings.cancel) {
            dismiss()
        }
        .font(AppTypography.buttonText)
        .foregroundStyle(AppTheme.primaryBlue)
        .frame(minHeight: 44, alignment: .leading)
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.screenTitle)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStrings.createTaskSubtitle)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleFields: some View {
        CreateTaskSurfaceCard(spacing: 14) {
            TextField(
                "",
                text: $viewModel.title,
                prompt: Text(LocalizedStrings.taskTitlePlaceholder)
                    .foregroundStyle(Color(hex: "7A8599"))
            )
            .focused($focusedField, equals: .title)
            .textInputAutocapitalization(.sentences)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppTheme.text)
            .tint(AppTheme.primaryBlue)
            .padding(.horizontal, 16)
            .frame(minHeight: 60)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "BBD6FF"), lineWidth: 1.2)
            }

            TaskDescriptionEditor(
                text: $viewModel.taskDescription,
                isFocused: $focusedField,
                placeholder: LocalizedStrings.taskDescriptionPlaceholder
            )
        }
        .id(descriptionFieldsCardId)
    }

    private var categoryCard: some View {
        CreateTaskSurfaceCard {
            CreateTaskSectionTitle(LocalizedStrings.category)

            TwoColumnSelectionGrid(items: TaskCategory.allCases) { category in
                categoryButton(category)
            }
        }
    }

    private var priorityCard: some View {
        CreateTaskSurfaceCard {
            CreateTaskSectionTitle(LocalizedStrings.priority)

            TwoColumnSelectionGrid(items: TaskPriority.allCases) { priority in
                SelectionTile(
                    title: priority.title,
                    systemImage: priority.selectionIcon,
                    color: AppTheme.primaryBlue,
                    unselectedColor: Color(hex: "64748B"),
                    isSelected: priority == viewModel.selectedPriority
                ) {
                    viewModel.selectedPriority = priority
                }
            }
        }
    }

    private var durationCard: some View {
        CreateTaskSurfaceCard {
            CreateTaskSectionTitle(LocalizedStrings.duration)

            TwoColumnSelectionGrid(items: viewModel.availableDurations) { duration in
                durationButton(duration)
            }
        }
    }

    private func categoryButton(_ category: TaskCategory) -> some View {
        SelectionTile(
            title: category.title,
            systemImage: category.selectionIcon,
            color: category.selectionColor,
            isSelected: category == viewModel.selectedCategory,
            selectedColor: category.selectionColor
        ) {
            viewModel.selectedCategory = category
        }
    }

    private func durationButton(_ duration: Int) -> some View {
        SelectionTile(
            title: LocalizedStrings.minutes(duration),
            systemImage: "clock",
            color: AppTheme.primaryBlue,
            unselectedColor: Color(hex: "64748B"),
            isSelected: duration == viewModel.selectedDuration
        ) {
            viewModel.selectedDuration = duration
        }
    }

    private var repeatCard: some View {
        CreateTaskSurfaceCard(spacing: 16) {
            repeatHeader

            if premiumAccess.canUseRepeatingTasks == false {
                PremiumLockedFeatureMessage(message: LocalizedStrings.repeatingTasksPremiumMessage)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            } else if viewModel.isRepeating {
                repeatSettings
                    .transition(.opacity.combined(with: .offset(y: 8)))
            } else {
                RepeatInfoRow(
                    systemImage: "calendar",
                    text: LocalizedStrings.repeatOnceInfo,
                    iconColor: Color(hex: "64748B")
                )
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(AppMotion.smooth(reduceMotion), value: viewModel.isRepeating)
        .animation(AppMotion.smooth(reduceMotion), value: viewModel.selectedRepeatType)
    }

    private var repeatHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(AppTypography.titleIcon)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 48, height: 48)
                .background(AppTheme.background)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(LocalizedStrings.repeatSectionTitle)
                        .font(AppTypography.sectionTitleSemibold)
                        .foregroundStyle(Color(hex: "0F172A"))

                    if premiumAccess.canUseRepeatingTasks == false {
                        PremiumBadge()
                    }
                }

                Text(LocalizedStrings.repeatSectionSubtitle)
                    .font(AppTypography.compactMedium)
                    .foregroundStyle(Color(hex: "64748B"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AppToggle(
                isOn: repeatToggleBinding,
                accessibilityLabel: LocalizedStrings.repeatToggleLabel
            )
        }
    }

    private var repeatToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isRepeating },
            set: { newValue in
                if newValue && premiumAccess.canUseRepeatingTasks == false {
                    viewModel.isRepeating = false
                    isShowingPremiumPlaceholder = true
                } else {
                    viewModel.isRepeating = newValue
                }
            }
        )
    }

    private var repeatSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStrings.repeatHowTitle)
                .font(AppTypography.sectionTitleSemibold)
                .foregroundStyle(AppTheme.text)

            TwoColumnSelectionGrid(items: TaskRepeatType.selectableCases) { repeatType in
                repeatTypeButton(repeatType)
            }

            if viewModel.selectedRepeatType == .customDays {
                customWeekdaysSection
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }

            RepeatInfoRow(
                systemImage: viewModel.selectedRepeatType == .customDays ? "calendar.badge.clock" : "arrow.triangle.2.circlepath",
                text: repeatSummaryText,
                iconColor: AppTheme.primaryBlue
            )
        }
    }

    private func repeatTypeButton(_ repeatType: TaskRepeatType) -> some View {
        SelectionTile(
            title: repeatType.title,
            systemImage: nil,
            color: AppTheme.primaryBlue,
            unselectedColor: Color(hex: "64748B"),
            isSelected: repeatType == viewModel.selectedRepeatType,
            selectedColor: AppTheme.primaryBlue,
            selectedBackgroundColor: AppTheme.background
        ) {
            withAnimation(AppMotion.smooth(reduceMotion)) {
                viewModel.selectedRepeatType = repeatType
            }
        }
    }

    private var customWeekdaysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStrings.repeatSelectDaysTitle)
                .font(AppTypography.buttonText)
                .foregroundStyle(AppTheme.text)

            LazyVGrid(columns: repeatWeekdayColumns, spacing: 8) {
                ForEach(RepeatWeekday.allCases.sorted()) { weekday in
                    RepeatWeekdayChip(
                        title: weekday.title,
                        isSelected: viewModel.selectedRepeatWeekdays.contains(weekday)
                    ) {
                        withAnimation(AppMotion.quick(reduceMotion)) {
                            viewModel.toggleRepeatWeekday(weekday)
                        }
                    }
                }
            }
        }
    }

    private var repeatWeekdayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    private var repeatSummaryText: String {
        switch viewModel.selectedRepeatType {
        case .none:
            return LocalizedStrings.repeatOnceInfo
        case .daily:
            return LocalizedStrings.repeatDailyInfo
        case .weekdays:
            return LocalizedStrings.repeatWeekdaysInfo
        case .weekly:
            return LocalizedStrings.repeatWeeklyInfo
        case .customDays:
            let selectedDays = RepeatWeekday.allCases
                .sorted()
                .filter { viewModel.selectedRepeatWeekdays.contains($0) }
                .map(\.title)

            return selectedDays.isEmpty
                ? LocalizedStrings.repeatSelectAtLeastOneDay
                : LocalizedStrings.repeatCustomInfo(selectedDays)
        }
    }

    private var saveButton: some View {
        Button {
            focusedField = nil

            if viewModel.saveTask(
                modelContext: modelContext,
                canUseRepeatingTasks: premiumAccess.canUseRepeatingTasks
            ) {
                onSaved()
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(AppTypography.buttonText)

                Text(LocalizedStrings.save)
                    .font(AppTypography.primaryButton)
            }
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
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppTheme.primaryBlue.opacity(0.24), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.canSave == false)
        .opacity(viewModel.canSave ? 1 : 0.55)
    }
}

private struct RepeatInfoRow: View {
    let systemImage: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(AppTypography.buttonText)
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)

            Text(text)
                .font(AppTypography.compactMedium)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F6F9FE"))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct RepeatWeekdayChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.compactSemibold)
                .foregroundStyle(isSelected ? Color.white : Color(hex: "64748B"))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36)
                .background(isSelected ? AppTheme.primaryBlue : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? AppTheme.primaryBlue : Color(hex: "D8E3F2"), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct CreateTaskSurfaceCard<Content: View>: View {
    let spacing: CGFloat
    private let content: Content

    init(
        spacing: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

private struct CreateTaskSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(AppTypography.sectionTitle)
            .foregroundStyle(AppTheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TaskDescriptionEditor: View {
    @Binding var text: String
    var isFocused: FocusState<CreateTaskView.FocusedField?>.Binding
    let placeholder: String

    var body: some View {
        KeyboardAwareTextEditor(
            text: $text,
            focusedField: isFocused,
            field: .description,
            placeholder: placeholder,
            font: AppTypography.bodyMedium,
            placeholderColor: Color(hex: "7A8599"),
            horizontalTextPadding: 11,
            verticalTextPadding: 13,
            placeholderHorizontalPadding: 17,
            placeholderVerticalPadding: 18,
            minHeight: 132,
            backgroundColor: Color.white,
            cornerRadius: 12,
            borderColor: Color(hex: "BBD6FF"),
            borderWidth: 1.2
        )
    }
}

private extension TaskCategory {
    var selectionIcon: String {
        switch self {
        case .study:
            "book"
        case .sport:
            "figure.run"
        case .work:
            "briefcase"
        case .habits:
            "arrow.triangle.2.circlepath"
        case .personal:
            "person"
        }
    }

    var selectionColor: Color {
        switch self {
        case .study:
            AppTheme.primaryBlue
        case .sport:
            Color(hex: "22C55E")
        case .work:
            AppTheme.purple
        case .habits:
            Color(hex: "FF8A00")
        case .personal:
            Color(hex: "14B8C4")
        }
    }
}

private extension TaskPriority {
    var selectionIcon: String {
        switch self {
        case .low:
            "arrow.down.circle.fill"
        case .medium:
            "minus.circle.fill"
        case .high:
            "arrow.up.right.circle.fill"
        }
    }
}

#if DEBUG
#Preview {
    CreateTaskView()
        .modelContainer(PreviewData.previewContainer())
}

#Preview("Редактирование задачи") {
    CreateTaskView(
        task: TaskItem(
            title: "Подготовить длинный отчёт",
            taskDescription: "Проверить цифры перед отправкой",
            priority: .high,
            estimatedMinutes: 60,
            category: .work
        )
    )
    .modelContainer(PreviewData.previewContainer())
}

#Preview(
    "Новая задача iPhone SE",
    traits: .fixedLayout(width: 320, height: 760)
) {
    CreateTaskView()
        .modelContainer(PreviewData.previewContainer())
}
#endif
