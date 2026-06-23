import SwiftUI

struct CreateTaskView: View {
    private enum FocusedField: Hashable {
        case title
        case description
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateTaskViewModel
    @FocusState private var focusedField: FocusedField?

    private let onSaved: () -> Void
    private let columns = [
        GridItem(.adaptive(minimum: 104), spacing: 8)
    ]

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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    titleFields
                    categoryCard
                    priorityCard
                    durationCard

                    if let validationMessage = viewModel.validationMessage {
                        Text(validationMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }

                    PrimaryButton(
                        LocalizedStrings.save,
                        systemImage: "checkmark",
                        isDisabled: viewModel.canSave == false
                    ) {
                        focusedField = nil

                        if viewModel.saveTask(modelContext: modelContext) {
                            onSaved()
                            dismiss()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedStrings.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.screenTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.createTaskSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleFields: some View {
        FocusDayCard {
            TextField(
                "",
                text: $viewModel.title,
                prompt: Text(LocalizedStrings.taskTitlePlaceholder)
                    .foregroundStyle(AppTheme.placeholderText)
            )
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.sentences)
                .font(.headline)
                .textFieldStyle(AppTextFieldStyle())

            TextEditor(text: $viewModel.taskDescription)
                .focused($focusedField, equals: .description)
                .appTextEditorStyle(
                    text: viewModel.taskDescription,
                    placeholder: LocalizedStrings.taskDescriptionPlaceholder,
                    minHeight: 110
                )
        }
    }

    private var categoryCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.category)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(TaskCategory.allCases) { category in
                    ChoiceChip(
                        title: category.title,
                        isSelected: category == viewModel.selectedCategory
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private var priorityCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.priority)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(TaskPriority.allCases) { priority in
                    ChoiceChip(
                        title: priority.title,
                        isSelected: priority == viewModel.selectedPriority
                    ) {
                        viewModel.selectedPriority = priority
                    }
                }
            }
        }
    }

    private var durationCard: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.duration)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.availableDurations, id: \.self) { duration in
                    ChoiceChip(
                        title: LocalizedStrings.minutes(duration),
                        isSelected: duration == viewModel.selectedDuration
                    ) {
                        viewModel.selectedDuration = duration
                    }
                }
            }
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
#endif
