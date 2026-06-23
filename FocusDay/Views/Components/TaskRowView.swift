import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isMain: Bool
    @Binding var isActionMenuPresented: Bool
    let onToggle: () -> Void
    let onMakeMain: () -> Void
    let onRemoveMain: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)

            Rectangle()
                .fill(task.priority.displayColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            HStack(alignment: .top, spacing: 10) {
                completionButton

                VStack(alignment: .leading, spacing: 7) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text.opacity(task.isCompleted ? 0.55 : 1))
                        .strikethrough(task.isCompleted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if task.taskDescription.isEmpty == false {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText.opacity(task.isCompleted ? 0.62 : 1))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    taskMetadata
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                TaskActionMenuButton(
                    task: task,
                    isMain: isMain,
                    isPresented: $isActionMenuPresented,
                    onMakeMain: onMakeMain,
                    onRemoveMain: onRemoveMain,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(task.priority.displayColor.opacity(0.14), lineWidth: 1)
        }
    }

    private var completionButton: some View {
        Button(action: onToggle) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(task.priority.displayColor)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            task.isCompleted ? LocalizedStrings.markNotCompleted : LocalizedStrings.markCompleted
        )
    }

    private var taskMetadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                categoryMetadata
                durationMetadata
                mainTaskIndicator
            }

            VStack(alignment: .leading, spacing: 5) {
                categoryMetadata

                HStack(spacing: 10) {
                    durationMetadata
                    mainTaskIndicator
                }
            }
        }
        .font(.caption)
        .foregroundStyle(AppTheme.mutedText)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var categoryMetadata: some View {
        Label(task.category.title, systemImage: task.category.symbolName)
    }

    private var durationMetadata: some View {
        Label(LocalizedStrings.minutes(task.estimatedMinutes), systemImage: "clock")
    }

    @ViewBuilder
    private var mainTaskIndicator: some View {
        if isMain {
            Image(systemName: "star.fill")
                .foregroundStyle(AppTheme.primaryBlue)
                .accessibilityLabel(LocalizedStrings.mainTaskBadge)
        }
    }
}

extension TaskPriority {
    var displayColor: Color {
        switch self {
        case .low:
            AppTheme.lowPriority
        case .medium:
            AppTheme.mediumPriority
        case .high:
            AppTheme.highPriority
        }
    }
}

struct TaskActionMenuButton: View {
    let task: TaskItem
    let isMain: Bool
    @Binding var isPresented: Bool
    let onMakeMain: () -> Void
    let onRemoveMain: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStrings.taskActions)
        .popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .trailing
        ) {
            TaskActionMenu(
                taskIsCompleted: task.isCompleted,
                isMain: isMain,
                onMakeMain: onMakeMain,
                onRemoveMain: onRemoveMain,
                onEdit: onEdit,
                onDelete: onDelete
            )
            .presentationCompactAdaptation(.popover)
        }
    }
}

struct TaskActionMenu: View {
    let taskIsCompleted: Bool
    let isMain: Bool
    let onMakeMain: () -> Void
    let onRemoveMain: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            if isMain {
                actionButton(
                    LocalizedStrings.removeFromMainTasks,
                    systemImage: "target",
                    action: onRemoveMain
                )
                menuDivider
            } else if taskIsCompleted == false {
                actionButton(
                    LocalizedStrings.makeMainTask,
                    systemImage: "target",
                    action: onMakeMain
                )
                menuDivider
            }

            actionButton(
                LocalizedStrings.edit,
                systemImage: "pencil",
                action: onEdit
            )

            menuDivider

            actionButton(
                LocalizedStrings.deleteTaskAction,
                systemImage: "trash",
                isDestructive: true,
                action: onDelete
            )
        }
        .padding(10)
        .frame(width: 264)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.22), radius: 16, x: 0, y: 7)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.96, anchor: .topTrailing)
        .presentationBackground(Color.white)
        .presentationCornerRadius(16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) {
                hasAppeared = true
            }
        }
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.async {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isDestructive ? AppTheme.highPriority : AppTheme.primaryBlue)
                    .frame(width: 40, height: 40)
                    .background(
                        isDestructive
                            ? Color(hex: "FFE5E5")
                            : AppTheme.primaryBlue.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDestructive ? AppTheme.highPriority : AppTheme.text)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(AppTheme.softBlue.opacity(0.65))
            .frame(height: 1)
            .padding(.horizontal, 8)
    }
}

struct TaskDeleteConfirmationDialog: View {
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.highPriority)

            Text(LocalizedStrings.deleteTaskTitle)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.deleteTaskMessage)
                .font(.subheadline)
                .foregroundStyle(AppTheme.placeholderText)

            HStack(spacing: 10) {
                dialogButton(
                    LocalizedStrings.cancel,
                    color: AppTheme.primaryBlue,
                    isFilled: false,
                    action: onCancel
                )
                dialogButton(
                    LocalizedStrings.delete,
                    color: AppTheme.highPriority,
                    isFilled: true,
                    action: onDelete
                )
            }
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 8)
    }

    private func dialogButton(
        _ title: String,
        color: Color,
        isFilled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isFilled ? Color.white : color)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(isFilled ? color : color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension TaskCategory {
    var symbolName: String {
        switch self {
        case .study:
            "book.closed"
        case .sport:
            "figure.run"
        case .work:
            "briefcase"
        case .habits:
            "repeat"
        case .personal:
            "person"
        }
    }
}

#if DEBUG
#Preview("Задача без описания") {
    TaskRowView.previewTask(title: "Позвонить", priority: .low)
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Задача с коротким описанием") {
    TaskRowView.previewTask(
        title: "Подготовить отчёт",
        description: "Проверить итоговые цифры.",
        priority: .medium
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Задача с длинным описанием") {
    TaskRowView.previewTask(
        title: "Подготовить презентацию",
        description: "Собрать ключевые результаты проекта, проверить диаграммы, добавить выводы команды и подготовить заметки для подробного выступления перед коллегами.",
        priority: .high
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview(
    "Длинная задача: iPhone SE",
    traits: .fixedLayout(width: 320, height: 568)
) {
    TaskRowView.previewTask(
        title: "Подготовить подробную презентацию результатов большого проекта за квартал",
        description: "Проверить все исходные данные, собрать диаграммы, сформулировать выводы, добавить следующие шаги и подготовить комментарии для каждого раздела презентации.",
        priority: .high
    )
    .padding(12)
    .background(AppTheme.screenBackground)
    .environment(\.dynamicTypeSize, .accessibility1)
}

#Preview("Открытое меню") {
    TaskActionMenu(
        taskIsCompleted: false,
        isMain: false,
        onMakeMain: {},
        onRemoveMain: {},
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Открытое меню: тёмная тема") {
    TaskActionMenu(
        taskIsCompleted: false,
        isMain: false,
        onMakeMain: {},
        onRemoveMain: {},
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(Color(hex: "111827"))
    .preferredColorScheme(.dark)
}

private extension TaskRowView {
    static func previewTask(
        title: String,
        description: String = "",
        priority: TaskPriority
    ) -> TaskRowView {
        TaskRowView(
            task: TaskItem(
                title: title,
                taskDescription: description,
                priority: priority,
                estimatedMinutes: 30,
                category: .study
            ),
            isMain: false,
            isActionMenuPresented: .constant(false),
            onToggle: {},
            onMakeMain: {},
            onRemoveMain: {},
            onEdit: {},
            onDelete: {}
        )
    }
}
#endif
