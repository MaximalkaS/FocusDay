import SwiftUI

struct TodayView: View {
    @AppStorage(UserDefaultsKeys.userName) private var userName = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: TodayViewModel
    @State private var taskToEdit: TaskItem?
    @State private var taskPendingDeletion: TaskItem?
    @State private var activeMenuTaskID: UUID?
    @State private var isShowingEveningSummary = false
    private let onAddTask: () -> Void

    @MainActor
    init(onAddTask: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: TodayViewModel())
        self.onAddTask = onAddTask
    }

    @MainActor
    init(
        viewModel: TodayViewModel,
        onAddTask: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onAddTask = onAddTask
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    MoodSelectionCard(
                        selectedMood: viewModel.selectedMood,
                        onSelect: viewModel.updateMood
                    )

                    EnergySelectionCard(
                        selectedEnergyLevel: viewModel.selectedEnergyLevel,
                        onSelect: viewModel.updateEnergyLevel
                    )

                    MainTaskCard(
                        task: viewModel.mainTask,
                        isActionMenuPresented: actionMenuBinding(for: viewModel.mainTask?.id),
                        onToggle: {
                            let streakCelebration = withAnimation(AppMotion.smooth(reduceMotion)) {
                                viewModel.toggleMainTaskCompletion()
                            }
                            appState.taskDataDidChange()
                            presentStreakCelebrationIfNeeded(streakCelebration)
                        },
                        onChoose: {
                            withAnimation(AppMotion.smooth(reduceMotion)) {
                                viewModel.chooseMainTask()
                            }
                        },
                        onRemoveMain: {
                            withAnimation(AppMotion.smooth(reduceMotion)) {
                                viewModel.removeMainTask()
                            }
                        },
                        onEdit: {
                            taskToEdit = viewModel.mainTask
                        },
                        onDelete: {
                            if let mainTask = viewModel.mainTask {
                                requestDeletion(of: mainTask)
                            }
                        }
                    )

                    taskListCard
                    progressCard
                    eveningLink
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .tabBarContentPadding()
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                viewModel.configure(modelContext: modelContext)
            }
            .onChange(of: appState.taskListRevision) { _, _ in
                viewModel.loadToday()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                viewModel.loadToday()
                appState.taskDataDidChange()
            }
            .overlay(alignment: .top) {
                SaveFeedbackOverlay(
                    status: appState.status(for: [.eveningSummary, .progress, .taskDeletion]),
                    successText: appState.status(for: .eveningSummary) == .hidden
                        ? LocalizedStrings.changesSaved
                        : LocalizedStrings.dayCompleted
                )
                    .padding(.top, 8)
            }
            .overlayPreferenceValue(TaskActionMenuAnchorPreferenceKey.self) { anchors in
                taskActionMenuOverlay(anchors)
            }
        }
        .sheet(item: $taskToEdit) { task in
            CreateTaskView(task: task) {
                withAnimation(AppMotion.quick(reduceMotion)) {
                    viewModel.loadToday()
                }
                appState.taskDataDidChange()
            }
        }
        .sheet(isPresented: $isShowingEveningSummary) {
            EveningSummaryView {
                viewModel.loadToday()
                appState.taskDataDidChange()
            }
        }
        .overlay {
            if let taskPendingDeletion {
                ZStack {
                    Color.black.opacity(0.22)
                        .ignoresSafeArea()
                        .onTapGesture {
                            cancelDeletion()
                        }

                    TaskDeleteConfirmationDialog(
                        onCancel: cancelDeletion,
                        onDelete: {
                            deleteTask(taskPendingDeletion)
                        }
                    )
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(AppMotion.quick(reduceMotion), value: taskPendingDeletion != nil)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingTitle)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(compactFormattedDate)
                    .font(AppTypography.screenSubtitle)
                    .foregroundStyle(Color(hex: "64748B"))
            }

            Spacer(minLength: 4)

            Button(action: onAddTask) {
                Image(systemName: "plus")
                    .font(AppTypography.plusIcon)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.primaryBlue)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 9, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel(LocalizedStrings.addTask)
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var taskListCard: some View {
        FocusDayCard {
            HStack(spacing: 12) {
                SectionHeader(title: LocalizedStrings.additionalTasks)

                Spacer()

                Button(action: onAddTask) {
                    HStack(spacing: 6) {
                        Text(LocalizedStrings.add)
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStrings.addTask)
            }

            if viewModel.additionalTasks.isEmpty {
                EmptyAdditionalTasksView()
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.additionalTasks) { task in
                        TaskRowView(
                            task: task,
                            isMain: viewModel.mainTask?.id == task.id,
                            isActionMenuPresented: actionMenuBinding(for: task.id),
                            onToggle: {
                                let streakCelebration = withAnimation(AppMotion.quick(reduceMotion)) {
                                    viewModel.toggleCompletion(for: task)
                                }
                                appState.taskDataDidChange()
                                presentStreakCelebrationIfNeeded(streakCelebration)
                            },
                            onMakeMain: {
                                withAnimation(AppMotion.smooth(reduceMotion)) {
                                    viewModel.setMainTask(task)
                                }
                            },
                            onRemoveMain: {
                                withAnimation(AppMotion.smooth(reduceMotion)) {
                                    viewModel.removeMainTask()
                                }
                            },
                            onEdit: {
                                taskToEdit = task
                            },
                            onDelete: {
                                requestDeletion(of: task)
                            }
                        )
                        .transition(AppMotion.appearTransition(reduceMotion))
                    }
                }
                .animation(AppMotion.smooth(reduceMotion), value: viewModel.additionalTasks.map(\.id))
            }
        }
    }

    private var progressCard: some View {
        FocusDayCard {
            HStack {
                SectionHeader(title: LocalizedStrings.taskProgress)
                Text(LocalizedStrings.completedOutOfTotal(viewModel.completedTasksCount, viewModel.totalTasksCount))
                    .font(AppTypography.sectionTitleSemibold)
                    .foregroundStyle(AppTheme.primaryBlue)
            }

            ProgressLineView(value: viewModel.progressValue)
        }
    }

    private var eveningLink: some View {
        Button {
            isShowingEveningSummary = true
        } label: {
            Label(LocalizedStrings.goToEveningSummary, systemImage: "flag")
                .font(AppTypography.primaryButton)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(hex: "2F80ED")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func requestDeletion(of task: TaskItem) {
        withAnimation(AppMotion.quick(reduceMotion)) {
            taskPendingDeletion = task
        }
    }

    private func cancelDeletion() {
        withAnimation(AppMotion.quick(reduceMotion)) {
            taskPendingDeletion = nil
        }
    }

    private func deleteTask(_ task: TaskItem) {
        appState.beginSaving(.taskDeletion)

        let didDelete = withAnimation(AppMotion.smooth(reduceMotion)) {
            viewModel.deleteTask(task)
        }

        taskPendingDeletion = nil

        if didDelete {
            appState.taskDataDidChange()
            appState.completeSaving(.taskDeletion)
        } else {
            appState.cancelFeedback()
        }
    }

    private func presentStreakCelebrationIfNeeded(_ streakCelebration: StreakCelebration?) {
        guard let streakCelebration else { return }

        withAnimation(.easeOut(duration: reduceMotion ? 0.14 : 0.22)) {
            appState.presentStreakCelebration(streakCelebration)
        }
    }

    private func task(for id: UUID) -> TaskItem? {
        if viewModel.mainTask?.id == id {
            return viewModel.mainTask
        }

        return viewModel.additionalTasks.first { $0.id == id }
    }

    @ViewBuilder
    private func taskActionMenuOverlay(_ anchors: [UUID: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            if let activeMenuTaskID,
               let anchor = anchors[activeMenuTaskID],
               let task = task(for: activeMenuTaskID) {
                let buttonFrame = proxy[anchor]
                let isMainTask = viewModel.mainTask?.id == task.id
                let menuHeight = TaskActionMenu.preferredHeight(
                    taskIsCompleted: task.isCompleted,
                    isMain: isMainTask
                )
                let placement = taskActionMenuPlacement(
                    buttonFrame: buttonFrame,
                    menuHeight: menuHeight,
                    containerSize: proxy.size
                )

                ZStack(alignment: .topLeading) {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeTaskActionMenu()
                        }

                    TaskActionMenu(
                        taskIsCompleted: task.isCompleted,
                        isMain: isMainTask,
                        onDismiss: closeTaskActionMenu,
                        onMakeMain: {
                            withAnimation(AppMotion.smooth(reduceMotion)) {
                                viewModel.setMainTask(task)
                            }
                        },
                        onRemoveMain: {
                            withAnimation(AppMotion.smooth(reduceMotion)) {
                                viewModel.removeMainTask()
                            }
                        },
                        onEdit: {
                            taskToEdit = task
                        },
                        onDelete: {
                            requestDeletion(of: task)
                        },
                        arrowOffsetY: placement.arrowY
                    )
                    .frame(width: TaskActionMenu.preferredWidth)
                    .position(x: placement.x, y: placement.y)
                    .transition(AppMotion.appearTransition(reduceMotion))
                }
                .zIndex(100)
            }
        }
        .allowsHitTesting(activeMenuTaskID != nil)
    }

    private func closeTaskActionMenu() {
        withAnimation(AppMotion.quick(reduceMotion)) {
            activeMenuTaskID = nil
        }
    }

    private func taskActionMenuPlacement(
        buttonFrame: CGRect,
        menuHeight: CGFloat,
        containerSize: CGSize
    ) -> (x: CGFloat, y: CGFloat, arrowY: CGFloat) {
        let margin: CGFloat = 12
        let gap: CGFloat = 12
        let menuWidth = TaskActionMenu.preferredWidth
        let rawX = buttonFrame.minX - gap - menuWidth / 2
        let minX = margin + menuWidth / 2
        let maxX = max(minX, containerSize.width - margin - menuWidth / 2)
        let x = min(max(rawX, minX), maxX)

        let rawTop = buttonFrame.midY - 44
        let maxTop = max(margin, containerSize.height - menuHeight - margin)
        let top = min(max(rawTop, margin), maxTop)
        let arrowY = min(max(buttonFrame.midY - top, 28), menuHeight - 28)

        return (x, top + menuHeight / 2, arrowY)
    }

    private var greetingTitle: String {
        let cleanedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return LocalizedStrings.personalizedGreeting(timeBasedGreeting, name: cleanedName)
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return LocalizedStrings.morningGreeting
        case 12..<18:
            return LocalizedStrings.afternoonGreeting
        default:
            return LocalizedStrings.eveningGreeting
        }
    }

    private var compactFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.dateFormat = LocalizedStrings.compactDateFormat
        let formattedDate = formatter.string(from: Date())
        return formattedDate.prefix(1).uppercased() + formattedDate.dropFirst()
    }

    private func actionMenuBinding(for taskID: UUID?) -> Binding<Bool> {
        Binding(
            get: {
                guard let taskID else { return false }
                return activeMenuTaskID == taskID
            },
            set: { isPresented in
                withAnimation(AppMotion.quick(reduceMotion)) {
                    if isPresented {
                        activeMenuTaskID = taskID
                    } else if activeMenuTaskID == taskID {
                        activeMenuTaskID = nil
                    }
                }
            }
        )
    }
}

private struct EmptyAdditionalTasksView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        Text(LocalizedStrings.noAdditionalTasks)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(AppTheme.mutedText)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.98)
            .onAppear {
                withAnimation(AppMotion.quick(reduceMotion)) {
                    isVisible = true
                }
            }
    }
}

#if DEBUG
#Preview("Сегодня: пояснения энергии и настроения") {
    TodayView()
        .modelContainer(PreviewData.previewContainer())
        .environmentObject(AppState())
}

#Preview(
    "Длинный список задач",
    traits: .fixedLayout(width: 320, height: 568)
) {
    MainTabView()
        .modelContainer(PreviewData.longListPreviewContainer())
}

#Preview(
    "Список без задач",
    traits: .fixedLayout(width: 320, height: 568)
) {
    MainTabView()
        .modelContainer(PreviewData.emptyPreviewContainer())
}
#endif
