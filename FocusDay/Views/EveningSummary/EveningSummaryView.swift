import SwiftData
import SwiftUI

struct EveningSummaryView: View {
    enum FocusedField: Hashable {
        case reflection
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @State private var tasks: [TaskItem] = []
    @State private var mainTask: TaskItem?
    @State private var dailyState: DailyState?
    @State private var didCompleteMainTask = false
    @State private var selectedFeeling: DayFeeling = .excellent
    @State private var selectedReasons: Set<DayInfluenceReason> = []
    @State private var reflectionText = ""
    @State private var message: String?
    @FocusState private var focusedField: FocusedField?

    private let onSaved: () -> Void
    private let unfinishedTasksCountOverride: Int?
    private let calendar = Calendar.current
    private let reflectionCardId = "eveningReflectionCard"

    init(
        onSaved: @escaping () -> Void = {},
        initialFeeling: DayFeeling = .excellent,
        initialReasons: Set<DayInfluenceReason> = [],
        unfinishedTasksCountOverride: Int? = nil
    ) {
        self.onSaved = onSaved
        self.unfinishedTasksCountOverride = unfinishedTasksCountOverride
        _selectedFeeling = State(initialValue: initialFeeling)
        _selectedReasons = State(initialValue: initialReasons)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    backButton
                    header
                    completionCard
                    dayFeelingCard

                    if selectedFeeling.needsInfluenceReasons {
                        influenceReasonsCard
                            .transition(
                                .opacity.combined(
                                    with: reduceMotion ? .identity : .move(edge: .bottom)
                                )
                            )
                    }

                    reflectionCard
                        .id(reflectionCardId)

                    if unfinishedTasksCount > 0 {
                        unfinishedTasksCard
                    }

                    if let message {
                        Text(message)
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
                targetField: .reflection,
                text: reflectionText,
                targetId: reflectionCardId,
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
        .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.24), value: selectedFeeling)
        .task {
            loadTodayData()
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(AppTypography.buttonText)

                Text(LocalizedStrings.back)
                    .font(AppTypography.buttonText)
            }
            .foregroundStyle(AppTheme.primaryBlue)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStrings.eveningSummary)
                .font(AppTypography.screenTitle)
                .foregroundStyle(Color(hex: "0F172A"))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStrings.eveningSummarySubtitle)
                .font(AppTypography.eveningScreenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completionCard: some View {
        EveningSummarySurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Text(LocalizedStrings.eveningQuestion)
                    .font(AppTypography.cardQuestion)
                    .foregroundStyle(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AppToggle(
                    isOn: $didCompleteMainTask,
                    accessibilityLabel: LocalizedStrings.eveningQuestion
                )
            }

            completedTasksBadge
        }
    }

    private var completedTasksBadge: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStrings.completedOutOfTotal(completedTasksCount, tasks.count))
                .font(AppTypography.eveningCompletedCount)
                .foregroundStyle(AppTheme.primaryBlue)
                .monospacedDigit()

            Text(LocalizedStrings.completedTasks)
                .font(AppTypography.controlText)
                .foregroundStyle(Color(hex: "64748B"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(hex: "F2F7FF"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "D8E8FF"), lineWidth: 1)
        }
    }

    private var dayFeelingCard: some View {
        EveningSummarySurfaceCard {
            Text(LocalizedStrings.howWasYourDay)
                .font(AppTypography.cardTitleLarge)
                .foregroundStyle(Color(hex: "0F172A"))

            TwoColumnSelectionGrid(items: DayFeeling.allCases) { feeling in
                EveningFeelingButton(
                    feeling: feeling,
                    isSelected: selectedFeeling == feeling
                ) {
                    selectedFeeling = feeling

                    if feeling.needsInfluenceReasons == false {
                        selectedReasons.removeAll()
                    }
                }
            }
        }
    }

    private var influenceReasonsCard: some View {
        EveningSummarySurfaceCard {
            Text(LocalizedStrings.whatAffectedDay)
                .font(AppTypography.cardTitleLarge)
                .foregroundStyle(Color(hex: "0F172A"))

            TwoColumnSelectionGrid(items: DayInfluenceReason.allCases) { reason in
                EveningReasonButton(
                    reason: reason,
                    isSelected: selectedReasons.contains(reason)
                ) {
                    toggleReason(reason)
                }
            }
        }
    }

    private var reflectionCard: some View {
        EveningSummarySurfaceCard(spacing: 14) {
            Text(LocalizedStrings.dayNoteTitle)
                .font(AppTypography.cardTitleLarge)
                .foregroundStyle(Color(hex: "0F172A"))

            EveningReflectionEditor(
                text: $reflectionText,
                isFocused: $focusedField,
                placeholder: LocalizedStrings.reflectionPlaceholder
            )
        }
    }

    private var unfinishedTasksCard: some View {
        EveningSummarySurfaceCard {
            HStack(spacing: 14) {
                Image(systemName: "checklist")
                    .font(AppTypography.plusIcon)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.primaryBlue.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStrings.unfinishedTasksTitle)
                        .font(AppTypography.secondarySectionTitle)
                        .foregroundStyle(Color(hex: "0F172A"))

                    Text(LocalizedStrings.unfinishedTasksMoveTomorrow(unfinishedTasksCount))
                        .font(AppTypography.screenSubtitle)
                        .foregroundStyle(Color(hex: "64748B"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveSummary()
        } label: {
            Text(LocalizedStrings.finishDay)
                .font(AppTypography.finishDayButton)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(AppTheme.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .shadow(color: AppTheme.primaryBlue.opacity(0.24), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    private var unfinishedTasksCount: Int {
        unfinishedTasksCountOverride ?? tasks.filter { $0.isCompleted == false }.count
    }

    private func toggleReason(_ reason: DayInfluenceReason) {
        if selectedReasons.contains(reason) {
            selectedReasons.remove(reason)
            return
        }

        guard selectedReasons.count < 2 else { return }
        selectedReasons.insert(reason)
    }

    private func loadTodayData() {
        do {
            let taskDescriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\TaskItem.date, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(taskDescriptor)
            tasks = allTasks.filter { calendar.isDate($0.date, inSameDayAs: Date()) }

            let stateDescriptor = FetchDescriptor<DailyState>(
                sortBy: [SortDescriptor(\DailyState.date, order: .reverse)]
            )
            let states = try modelContext.fetch(stateDescriptor)
            let state = states.first { calendar.isDate($0.date, inSameDayAs: Date()) }
            dailyState = state

            if let mainTaskId = state?.mainTaskId {
                mainTask = tasks.first { $0.id == mainTaskId }
                didCompleteMainTask = mainTask?.isCompleted ?? false
            } else {
                mainTask = nil
                didCompleteMainTask = false
            }

            let summaryDescriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(summaryDescriptor)
            if let summary = summaries.first(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
                reflectionText = summary.reflectionText
                selectedFeeling = summary.dayFeeling
                selectedReasons = Set(summary.influenceReasons)
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func saveSummary() {
        focusedField = nil
        appState.beginSaving(.eveningSummary)

        if let mainTask {
            mainTask.isCompleted = didCompleteMainTask
            mainTask.completedAt = didCompleteMainTask ? (mainTask.completedAt ?? Date()) : nil
        }

        if didCompleteMainTask {
            dailyState?.mainTaskId = nil
        }

        if selectedFeeling.needsInfluenceReasons == false {
            selectedReasons.removeAll()
        }

        do {
            let descriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(descriptor)
            let existingSummary = summaries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
            let completedCount = tasks.filter { $0.isCompleted }.count
            let orderedReasons = DayInfluenceReason.allCases.filter { selectedReasons.contains($0) }

            if let existingSummary {
                existingSummary.completedTasksCount = completedCount
                existingSummary.totalTasksCount = tasks.count
                existingSummary.reflectionText = reflectionText
                existingSummary.dayFeeling = selectedFeeling
                existingSummary.influenceReasons = orderedReasons
                existingSummary.finishedAt = Date()
            } else {
                let summary = DailySummary(
                    date: Date(),
                    completedTasksCount: completedCount,
                    totalTasksCount: tasks.count,
                    reflectionText: reflectionText,
                    dayFeeling: selectedFeeling,
                    influenceReasons: orderedReasons,
                    finishedAt: Date()
                )
                modelContext.insert(summary)
            }

            try createNextRepeatingTaskCopies()
            moveUnfinishedTasksToTomorrow()
            dailyState?.mainTaskId = nil

            try modelContext.save()
            WidgetSnapshotService.refresh(modelContext: modelContext)
            message = nil
            onSaved()
            dismiss()
            appState.completeSaving(.eveningSummary)
        } catch {
            appState.cancelFeedback()
            message = error.localizedDescription
        }
    }

    private func createNextRepeatingTaskCopies() throws {
        let todayStart = calendar.startOfDay(for: Date())
        var allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())

        for task in tasks where task.isCompleted && task.isRepeating {
            guard let nextDate = task.nextRepeatDate(after: todayStart, calendar: calendar) else { continue }

            let seriesId = task.repeatSeriesId ?? task.id
            task.repeatSeriesId = seriesId
            task.repeatStartDate = task.repeatStartDate ?? task.date

            let alreadyHasNextTask = allTasks.contains { existingTask in
                let existingSeriesId = existingTask.repeatSeriesId ?? (existingTask.isRepeating ? existingTask.id : nil)
                return existingTask.id != task.id
                    && existingSeriesId == seriesId
                    && calendar.isDate(existingTask.date, inSameDayAs: nextDate)
                    && existingTask.isCompleted == false
            }

            guard alreadyHasNextTask == false else { continue }

            let nextTask = TaskItem(
                title: task.title,
                taskDescription: task.taskDescription,
                date: nextDate,
                priority: task.priority,
                isCompleted: false,
                estimatedMinutes: task.estimatedMinutes,
                category: task.category,
                isRepeating: true,
                repeatType: task.repeatType,
                repeatWeekdays: task.repeatWeekdays,
                repeatStartDate: task.repeatStartDate ?? task.date,
                repeatSeriesId: seriesId
            )
            modelContext.insert(nextTask)
            allTasks.append(nextTask)
        }
    }

    private func moveUnfinishedTasksToTomorrow() {
        let todayStart = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) else { return }

        for task in tasks where task.isCompleted == false {
            if task.isRepeating,
               let nextRepeatDate = task.nextRepeatDate(after: todayStart, calendar: calendar) {
                task.repeatSeriesId = task.repeatSeriesId ?? task.id
                task.repeatStartDate = task.repeatStartDate ?? task.date
                task.date = nextRepeatDate
            } else {
                task.date = tomorrow
            }
        }
    }
}

private struct EveningSummarySurfaceCard<Content: View>: View {
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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

private struct EveningFeelingButton: View {
    let feeling: DayFeeling
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionTile(
            title: feeling.title,
            systemImage: feeling.systemImage,
            color: feeling.color,
            isSelected: isSelected,
            selectedColor: feeling.color,
            unselectedBorderColor: feeling.borderColor,
            selectedBorderColor: feeling.borderColor,
            selectedBackgroundColor: feeling.selectedBackgroundColor,
            action: action
        )
    }
}

private struct EveningReasonButton: View {
    let reason: DayInfluenceReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionTile(
            title: reason.title,
            color: AppTheme.primaryBlue,
            unselectedColor: Color(hex: "64748B"),
            isSelected: isSelected,
            selectedColor: AppTheme.primaryBlue,
            action: action
        )
    }
}

private struct EveningReflectionEditor: View {
    @Binding var text: String
    var isFocused: FocusState<EveningSummaryView.FocusedField?>.Binding
    let placeholder: String

    var body: some View {
        KeyboardAwareTextEditor(
            text: $text,
            focusedField: isFocused,
            field: .reflection,
            placeholder: placeholder,
            font: AppTypography.eveningScreenSubtitle,
            placeholderColor: Color(hex: "8A96B3"),
            horizontalTextPadding: 12,
            verticalTextPadding: 12,
            placeholderHorizontalPadding: 18,
            placeholderVerticalPadding: 17,
            minHeight: 112,
            backgroundColor: Color(hex: "F7FBFF"),
            cornerRadius: 18,
            borderColor: Color(hex: "D8E8FF"),
            borderWidth: 1.2
        )
    }
}

private extension DayFeeling {
    var title: String {
        switch self {
        case .excellent:
            LocalizedStrings.dayFeelingExcellent
        case .calm:
            LocalizedStrings.dayFeelingCalm
        case .hard:
            LocalizedStrings.dayFeelingHard
        case .overloaded:
            LocalizedStrings.dayFeelingOverloaded
        }
    }

    var systemImage: String {
        switch self {
        case .excellent:
            "face.smiling"
        case .calm:
            "leaf.fill"
        case .hard:
            "cloud.fill"
        case .overloaded:
            "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .excellent:
            AppTheme.primaryBlue
        case .calm:
            Color(hex: "22C55E")
        case .hard:
            AppTheme.mediumPriority
        case .overloaded:
            AppTheme.highPriority
        }
    }

    var selectedBackgroundColor: Color {
        switch self {
        case .excellent:
            AppTheme.background
        case .calm:
            Color(hex: "DCFCE7")
        case .hard:
            Color(hex: "FFF8E7")
        case .overloaded:
            Color(hex: "FFE5E5")
        }
    }

    var borderColor: Color {
        switch self {
        case .excellent:
            AppTheme.primaryBlue
        case .calm:
            color.opacity(0.35)
        case .hard:
            color.opacity(0.35)
        case .overloaded:
            color.opacity(0.30)
        }
    }
}

private extension DayInfluenceReason {
    var title: String {
        switch self {
        case .notEnoughTime:
            LocalizedStrings.influenceNotEnoughTime
        case .lowEnergy:
            LocalizedStrings.influenceLowEnergy
        case .distracted:
            LocalizedStrings.influenceDistracted
        case .tooManyTasks:
            LocalizedStrings.influenceTooManyTasks
        }
    }
}

#if DEBUG
#Preview("Завершение дня: отлично") {
    NavigationStack {
        EveningSummaryView(initialFeeling: .excellent)
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}

#Preview("Завершение дня: непросто") {
    NavigationStack {
        EveningSummaryView(initialFeeling: .hard)
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}

#Preview("Завершение дня: перегруженно") {
    NavigationStack {
        EveningSummaryView(
            initialFeeling: .overloaded,
            initialReasons: [.lowEnergy, .tooManyTasks]
        )
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}

#Preview("Завершение дня: без незавершённых") {
    NavigationStack {
        EveningSummaryView(
            initialFeeling: .calm,
            unfinishedTasksCountOverride: 0
        )
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}

#Preview("Завершение дня: есть незавершённые") {
    NavigationStack {
        EveningSummaryView(
            initialFeeling: .hard,
            unfinishedTasksCountOverride: 8
        )
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}
#endif
