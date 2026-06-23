import SwiftData
import SwiftUI

struct EveningSummaryView: View {
    private enum FocusedField: Hashable {
        case reflection
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var tasks: [TaskItem] = []
    @State private var mainTask: TaskItem?
    @State private var dailyState: DailyState?
    @State private var didCompleteMainTask = false
    @State private var reflectionText = ""
    @State private var message: String?
    @FocusState private var focusedField: FocusedField?

    private let onSaved: () -> Void
    private let calendar = Calendar.current

    init(onSaved: @escaping () -> Void = {}) {
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                FocusDayCard {
                    Toggle(LocalizedStrings.eveningQuestion, isOn: $didCompleteMainTask)
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)

                    Text(LocalizedStrings.completedOutOfTotal(completedTasksCount, tasks.count))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(LocalizedStrings.completedTasks)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }

                FocusDayCard {
                    SectionHeader(title: LocalizedStrings.whatWorkedToday)

                    TextEditor(text: $reflectionText)
                        .focused($focusedField, equals: .reflection)
                        .appTextEditorStyle(
                            text: reflectionText,
                            placeholder: LocalizedStrings.reflectionPlaceholder,
                            minHeight: 140
                        )
                }

                if let message {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }

                PrimaryButton(LocalizedStrings.save, systemImage: "checkmark") {
                    saveSummary()
                }
            }
            .padding()
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .tabBarContentPadding()
        .scrollDismissesKeyboard(.interactively)
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LocalizedStrings.done) {
                    focusedField = nil
                }
            }
        }
        .task {
            loadTodayData()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.eveningSummary)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.eveningSummarySubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
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
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func saveSummary() {
        focusedField = nil
        appState.beginSaving(.eveningSummary)
        mainTask?.isCompleted = didCompleteMainTask

        if didCompleteMainTask {
            dailyState?.mainTaskId = nil
        }

        do {
            let descriptor = FetchDescriptor<DailySummary>(
                sortBy: [SortDescriptor(\DailySummary.date, order: .reverse)]
            )
            let summaries = try modelContext.fetch(descriptor)
            let existingSummary = summaries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
            let completedCount = tasks.filter { $0.isCompleted }.count

            if let existingSummary {
                existingSummary.completedTasksCount = completedCount
                existingSummary.totalTasksCount = tasks.count
                existingSummary.reflectionText = reflectionText
            } else {
                let summary = DailySummary(
                    date: Date(),
                    completedTasksCount: completedCount,
                    totalTasksCount: tasks.count,
                    reflectionText: reflectionText
                )
                modelContext.insert(summary)
            }

            try modelContext.save()
            message = nil
            onSaved()
            dismiss()
            appState.completeSaving(.eveningSummary)
        } catch {
            appState.cancelFeedback()
            message = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EveningSummaryView()
    }
    .modelContainer(PreviewData.previewContainer())
    .environmentObject(AppState())
}
#endif
