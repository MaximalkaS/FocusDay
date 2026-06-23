import SwiftData
import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \TaskItem.date, order: .reverse) private var tasks: [TaskItem]
    @StateObject private var viewModel: ProgressViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: ProgressViewModel())
    }

    @MainActor
    init(viewModel: ProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    metricsGrid
                    MonthCalendarView(productiveDays: viewModel.productiveDays)
                    SevenDayChartView(points: viewModel.lastSevenDays)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .tabBarContentPadding()
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                refreshMetrics()
            }
            .onChange(of: taskRevision) { _, _ in
                refreshMetrics()
            }
            .onChange(of: appState.taskListRevision) { _, _ in
                refreshMetrics()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.progress)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.progressSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricsGrid: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MetricCard(
                    title: LocalizedStrings.completedTasks,
                    value: LocalizedStrings.completedTasksCount(viewModel.completedTasksCount),
                    systemImage: "checkmark.circle"
                )

                MetricCard(
                    title: LocalizedStrings.currentStreak,
                    value: "\(viewModel.currentStreak) \(LocalizedStrings.daysSuffix)",
                    systemImage: "flame"
                )
            }

            MetricCard(
                title: LocalizedStrings.bestResult,
                value: LocalizedStrings.completedTasksCount(viewModel.bestResult),
                systemImage: "star"
            )
        }
    }

    private var taskRevision: [ProgressTaskRevision] {
        tasks.map {
            ProgressTaskRevision(id: $0.id, date: $0.date, isCompleted: $0.isCompleted)
        }
    }

    private func refreshMetrics() {
        viewModel.recalculate(tasks: tasks)
    }
}

private struct ProgressTaskRevision: Equatable {
    let id: UUID
    let date: Date
    let isCompleted: Bool
}

private struct MonthCalendarView: View {
    let productiveDays: Set<Date>

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private var firstDayOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    private var leadingEmptyDays: Int {
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var monthDays: [Date] {
        let dayRange = calendar.range(of: .day, in: .month, for: firstDayOfMonth) ?? 1..<31

        return dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
        }
    }

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.productiveDays)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(LocalizedStrings.weekdayShortTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.mutedText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear
                        .frame(height: 34)
                }

                ForEach(monthDays, id: \.self) { date in
                    dayCell(for: date)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isProductive = productiveDays.contains(calendar.startOfDay(for: date))
        let isToday = Calendar.current.isDateInToday(date)

        return Text("\(day)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isProductive ? .white : AppTheme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                isProductive
                    ? AppTheme.primaryBlue.opacity(isToday ? 0.78 : 1)
                    : Color.white.opacity(0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isToday ? AppTheme.primaryBlue : Color.clear, lineWidth: 2)
            }
    }
}

private struct SevenDayChartView: View {
    let points: [DailyProgressPoint]

    private let plotHeight: CGFloat = 112

    private var maxValue: Int {
        max(points.map(\.completedCount).max() ?? 1, 1)
    }

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.lastSevenDays)

            VStack(spacing: 8) {
                GeometryReader { proxy in
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(points) { point in
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)

                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(AppTheme.primaryBlue)
                                    .frame(
                                        height: barHeight(
                                            for: point.completedCount,
                                            availableHeight: proxy.size.height
                                        )
                                    )
                                    .opacity(point.completedCount == 0 ? 0.22 : 1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: plotHeight)

                HStack(spacing: 6) {
                    ForEach(points) { point in
                        Text(weekdayTitle(for: point.date))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 18)
            }
            .padding(.bottom, 4)
        }
    }

    private func barHeight(for count: Int, availableHeight: CGFloat) -> CGFloat {
        guard count > 0 else { return 4 }

        let normalizedHeight = CGFloat(count) / CGFloat(maxValue) * availableHeight
        return min(availableHeight, max(8, normalizedHeight))
    }

    private func weekdayTitle(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let mondayBasedIndex = (weekday + 5) % 7
        guard LocalizedStrings.weekdayShortTitles.indices.contains(mondayBasedIndex) else {
            return ""
        }
        return LocalizedStrings.weekdayShortTitles[mondayBasedIndex]
    }
}

#if DEBUG
#Preview("Progress: текущий день") {
    ProgressView()
        .modelContainer(PreviewData.previewContainer())
        .environmentObject(AppState())
}

#Preview("Progress: одна задача") {
    ProgressView()
        .modelContainer(PreviewData.progressSingleTaskContainer())
        .environmentObject(AppState())
}

#Preview("Progress: несколько задач") {
    ProgressView()
        .modelContainer(PreviewData.progressMultipleTasksContainer())
        .environmentObject(AppState())
}

#Preview("Progress: заполненная серия") {
    ProgressView()
        .modelContainer(PreviewData.progressStreakContainer())
        .environmentObject(AppState())
}

#Preview("График: нулевые значения") {
    SevenDayChartView(points: ChartPreviewData.points(counts: [0, 0, 0, 0, 0, 0, 0]))
        .padding()
        .background(AppTheme.background)
}

#Preview("График: одна задача") {
    SevenDayChartView(points: ChartPreviewData.points(counts: [0, 0, 0, 1, 0, 0, 0]))
        .padding()
        .background(AppTheme.background)
}

#Preview("График: заполненная неделя") {
    SevenDayChartView(points: ChartPreviewData.points(counts: [1, 3, 2, 5, 4, 6, 7]))
        .padding()
        .background(AppTheme.background)
}

private enum ChartPreviewData {
    static func points(counts: [Int]) -> [DailyProgressPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return counts.enumerated().compactMap { index, count in
            let offset = index - counts.count + 1
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }

            return DailyProgressPoint(date: date, completedCount: count)
        }
    }
}
#endif
