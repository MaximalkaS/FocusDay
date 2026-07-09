import SwiftUI

struct CreateTaskView: View {
    enum FocusedField: Hashable {
        case title
        case description
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateTaskViewModel
    @FocusState private var focusedField: FocusedField?

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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    cancelButton
                    header
                    titleFields
                    categoryCard
                    priorityCard
                    durationCard

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

    private var saveButton: some View {
        Button {
            focusedField = nil

            if viewModel.saveTask(modelContext: modelContext) {
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

private struct SelectionTile: View {
    let title: String
    let systemImage: String
    let color: Color
    var unselectedColor: Color?
    let isSelected: Bool
    var selectedColor: Color = AppTheme.primaryBlue
    let action: () -> Void

    private var currentColor: Color {
        isSelected ? selectedColor : (unselectedColor ?? color)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(currentColor)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(AppTypography.choiceButtonText)
                    .foregroundStyle(currentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 8)
            .background(isSelected ? selectedColor.opacity(0.08) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? selectedColor : Color(hex: "D8E3F2"), lineWidth: isSelected ? 1.6 : 1.2)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

private struct TaskDescriptionEditor: View {
    @Binding var text: String
    var isFocused: FocusState<CreateTaskView.FocusedField?>.Binding
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused(isFocused, equals: .description)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppTheme.text)
                .tint(AppTheme.primaryBlue)
                .padding(.horizontal, 11)
                .padding(.vertical, 13)
                .scrollContentBackground(.hidden)

            if text.isEmpty {
                Text(placeholder)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color(hex: "7A8599"))
                    .padding(.horizontal, 17)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 132)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "BBD6FF"), lineWidth: 1.2)
        }
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
