import SwiftUI

struct TodayView: View {
    @AppStorage(UserDefaultsKeys.userName) private var userName = ""
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: TodayViewModel
    @State private var taskToEdit: TaskItem?
    @State private var taskPendingDeletion: TaskItem?
    @State private var activeMenuTaskID: UUID?
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
                            withAnimation(.easeInOut(duration: 0.28)) {
                                viewModel.toggleMainTaskCompletion()
                            }
                            appState.taskDataDidChange()
                        },
                        onChoose: {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                viewModel.chooseMainTask()
                            }
                        },
                        onRemoveMain: {
                            withAnimation(.easeInOut(duration: 0.24)) {
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
            .tabBarContentPadding()
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task {
                viewModel.configure(modelContext: modelContext)
            }
            .onChange(of: appState.taskListRevision) { _, _ in
                viewModel.loadToday()
            }
            .overlay(alignment: .top) {
                SaveFeedbackOverlay(
                    status: appState.status(for: [.eveningSummary, .progress, .taskDeletion])
                )
                    .padding(.top, 8)
            }
        }
        .sheet(item: $taskToEdit) { task in
            CreateTaskView(task: task) {
                withAnimation(.easeInOut(duration: 0.24)) {
                    viewModel.loadToday()
                }
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
        .animation(.easeInOut(duration: 0.2), value: taskPendingDeletion != nil)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greetingTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(viewModel.formattedDate)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            Button(action: onAddTask) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStrings.addTask)
            }

            if viewModel.additionalTasks.isEmpty {
                Text(LocalizedStrings.noAdditionalTasks)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.additionalTasks) { task in
                        TaskRowView(
                            task: task,
                            isMain: viewModel.mainTask?.id == task.id,
                            isActionMenuPresented: actionMenuBinding(for: task.id),
                            onToggle: {
                                viewModel.toggleCompletion(for: task)
                                appState.taskDataDidChange()
                            },
                            onMakeMain: {
                                viewModel.setMainTask(task)
                            },
                            onRemoveMain: {
                                viewModel.removeMainTask()
                            },
                            onEdit: {
                                taskToEdit = task
                            },
                            onDelete: {
                                requestDeletion(of: task)
                            }
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: viewModel.mainTask?.id)
            }
        }
    }

    private var progressCard: some View {
        FocusDayCard {
            HStack {
                SectionHeader(title: LocalizedStrings.taskProgress)
                Text(LocalizedStrings.completedOutOfTotal(viewModel.completedTasksCount, viewModel.totalTasksCount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
            }

            ProgressLineView(value: viewModel.progressValue)
        }
    }

    private var eveningLink: some View {
        NavigationLink {
            EveningSummaryView {
                viewModel.loadToday()
                appState.taskDataDidChange()
            }
        } label: {
            Label(LocalizedStrings.goToEveningSummary, systemImage: "flag")
                .font(.headline)
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
        withAnimation(.easeInOut(duration: 0.2)) {
            taskPendingDeletion = task
        }
    }

    private func cancelDeletion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            taskPendingDeletion = nil
        }
    }

    private func deleteTask(_ task: TaskItem) {
        appState.beginSaving(.taskDeletion)

        let didDelete = withAnimation(.easeInOut(duration: 0.24)) {
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

    private var greetingTitle: String {
        let cleanedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedName.isEmpty == false else { return LocalizedStrings.greeting }
        return LocalizedStrings.personalizedGreeting(cleanedName)
    }

    private func actionMenuBinding(for taskID: UUID?) -> Binding<Bool> {
        Binding(
            get: {
                guard let taskID else { return false }
                return activeMenuTaskID == taskID
            },
            set: { isPresented in
                if isPresented {
                    activeMenuTaskID = taskID
                } else if activeMenuTaskID == taskID {
                    activeMenuTaskID = nil
                }
            }
        )
    }
}

#if DEBUG
#Preview {
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
