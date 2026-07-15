import SwiftUI
import UIKit

struct MainTaskCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let task: TaskItem?
    let backgroundImageName: String?
    @Binding var isActionMenuPresented: Bool
    let onToggle: () -> Void
    let onChoose: () -> Void
    let onRemoveMain: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let cornerRadius: CGFloat = 8

    init(
        task: TaskItem?,
        backgroundImageName: String? = "mainTaskBackground",
        isActionMenuPresented: Binding<Bool>,
        onToggle: @escaping () -> Void,
        onChoose: @escaping () -> Void,
        onRemoveMain: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.backgroundImageName = backgroundImageName
        _isActionMenuPresented = isActionMenuPresented
        self.onToggle = onToggle
        self.onChoose = onChoose
        self.onRemoveMain = onRemoveMain
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 16) {
                header

                if let task {
                    taskDetails(task)
                        .transition(AppMotion.appearTransition(reduceMotion))
                }

                PrimaryButton(
                    LocalizedStrings.chooseMainTask,
                    systemImage: "scope",
                    action: onChoose
                )
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .animation(AppMotion.smooth(reduceMotion), value: task?.id)
        .zIndex(isActionMenuPresented ? 50 : 0)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "target")
                .font(AppTypography.titleIcon)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(hasBackgroundImage ? 0.78 : 0.9))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStrings.mainTaskOfDay)
                    .font(AppTypography.progressCardValue)
                    .foregroundStyle(primaryTextColor)

                Text(task?.title ?? LocalizedStrings.noMainTask)
                    .font(task == nil ? AppTypography.screenSubtitle : AppTypography.sectionTitleSemibold)
                    .foregroundStyle(task == nil ? secondaryTextColor : primaryTextColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            if let task {
                TaskActionMenuButton(
                    task: task,
                    isMain: true,
                    isPresented: $isActionMenuPresented,
                    onMakeMain: {},
                    onRemoveMain: onRemoveMain,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            }
        }
    }

    private func taskDetails(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                CompletionCheckbox(
                    isCompleted: task.isCompleted,
                    color: task.priority.displayColor,
                    size: 24
                )
                    .frame(width: 44, height: 44)
                    .background(hasBackgroundImage ? Color.white.opacity(0.9) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted ? LocalizedStrings.markNotCompleted : LocalizedStrings.markCompleted
            )

            VStack(alignment: .leading, spacing: 5) {
                if task.taskDescription.isEmpty == false {
                    Text(task.taskDescription)
                        .font(AppTypography.screenSubtitle)
                        .foregroundStyle(secondaryTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        Label(task.category.title, systemImage: "folder")
                        Label(LocalizedStrings.minutes(task.estimatedMinutes), systemImage: "clock")
                        repeatIndicator(for: task)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Label(task.category.title, systemImage: "folder")

                        HStack(spacing: 12) {
                            Label(LocalizedStrings.minutes(task.estimatedMinutes), systemImage: "clock")
                            repeatIndicator(for: task)
                        }
                    }
                }
                .font(AppTypography.taskMetadata)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func repeatIndicator(for task: TaskItem) -> some View {
        if task.isRepeating {
            Label(LocalizedStrings.repeatingTask, systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(AppTheme.primaryBlue)
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let backgroundImageName, UIImage(named: backgroundImageName) != nil {
            GeometryReader { proxy in
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
        } else {
            AppTheme.card
        }
    }

    private var hasBackgroundImage: Bool {
        guard let backgroundImageName else { return false }
        return UIImage(named: backgroundImageName) != nil
    }

    private var primaryTextColor: Color {
        AppTheme.text
    }

    private var secondaryTextColor: Color {
        Color(hex: "64748B")
    }

}

#if DEBUG
#Preview("Главная задача с изображением") {
    MainTaskCard(
        task: TaskItem(
            title: "Подготовить план дня",
            taskDescription: "15 минут без лишней нагрузки",
            priority: .high,
            estimatedMinutes: 15
        ),
        isActionMenuPresented: .constant(false),
        onToggle: {},
        onChoose: {},
        onRemoveMain: {},
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Главная задача без изображения") {
    MainTaskCard(
        task: TaskItem(title: "Подготовить план дня", priority: .medium),
        backgroundImageName: nil,
        isActionMenuPresented: .constant(false),
        onToggle: {},
        onChoose: {},
        onRemoveMain: {},
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(AppTheme.screenBackground)
}
#endif
