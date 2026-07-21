import Charts
import SwiftData
import SwiftUI
import UIKit

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @Query(sort: \TaskItem.date, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \DailySummary.date, order: .reverse) private var summaries: [DailySummary]
    @StateObject private var viewModel: ProgressViewModel
    @State private var hasPlayedIntro = false
    private let isActive: Bool

    @MainActor
    init(isActive: Bool = true) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel())
        self.isActive = isActive
    }

    @MainActor
    init(
        isActive: Bool = true,
        viewModel: ProgressViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.isActive = isActive
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    metricCards

                    ThirtyDayCalendarCard(
                        days: viewModel.lastThirtyDays,
                        referenceDate: viewModel.referenceDate
                    )
                    .modifier(ProgressIntroAnimationModifier(
                        isVisible: hasPlayedIntro,
                        reduceMotion: reduceMotion,
                        delay: 0.18
                    ))

                    SevenDayActivityCard(points: viewModel.lastSevenDays)
                        .modifier(ProgressIntroAnimationModifier(
                            isVisible: hasPlayedIntro,
                            reduceMotion: reduceMotion,
                            delay: 0.24
                        ))

                    WeeklyCompletedTasksCard(summary: viewModel.weeklySummary)
                        .modifier(ProgressIntroAnimationModifier(
                            isVisible: hasPlayedIntro,
                            reduceMotion: reduceMotion,
                            delay: 0.3
                        ))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .tabBarContentPadding()
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                refreshMetrics()
                playIntroIfNeeded()
            }
            .onChange(of: taskRevision) { _, _ in
                refreshMetrics()
            }
            .onChange(of: summaryRevision) { _, _ in
                refreshMetrics()
            }
            .onChange(of: appState.taskListRevision) { _, _ in
                refreshMetrics()
            }
            .onChange(of: isActive) { _, newValue in
                guard newValue else { return }
                refreshMetrics()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                refreshMetrics()
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusDayCalendarDayDidChange)) { _ in
                refreshMetrics()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStrings.progress)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(LocalizedStrings.progressSubtitle)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricCards: some View {
        let cardHeight: CGFloat = 142

        return HStack(alignment: .top, spacing: 10) {
            ProgressMetricCard(
                title: LocalizedStrings.currentStreak,
                value: LocalizedStrings.daysCount(viewModel.currentStreak),
                systemImage: "flame.fill",
                color: AppTheme.primaryBlue,
                backgroundImageName: "currentStreakBackground",
                height: cardHeight
            )
            .modifier(ProgressIntroAnimationModifier(
                isVisible: hasPlayedIntro,
                reduceMotion: reduceMotion,
                delay: 0
            ))

            ProgressMetricCard(
                title: LocalizedStrings.bestResult,
                value: LocalizedStrings.tasksCount(viewModel.bestResult),
                systemImage: "trophy.fill",
                color: Color(hex: "7C3AED"),
                backgroundImageName: "bestResultBackground",
                height: cardHeight
            )
            .modifier(ProgressIntroAnimationModifier(
                isVisible: hasPlayedIntro,
                reduceMotion: reduceMotion,
                delay: 0.07
            ))

            ProgressMetricCard(
                title: LocalizedStrings.completedToday,
                value: LocalizedStrings.tasksCount(viewModel.completedTasksCount),
                systemImage: "checkmark.circle.fill",
                color: Color(hex: "22C55E"),
                backgroundImageName: "completedTodayBackground",
                height: cardHeight
            )
            .modifier(ProgressIntroAnimationModifier(
                isVisible: hasPlayedIntro,
                reduceMotion: reduceMotion,
                delay: 0.14
            ))
        }
    }

    private var taskRevision: [ProgressTaskRevision] {
        tasks.map {
            ProgressTaskRevision(
                id: $0.id,
                date: $0.date,
                isCompleted: $0.isCompleted,
                completedAt: $0.completedAt
            )
        }
    }

    private var summaryRevision: [ProgressSummaryRevision] {
        summaries.map {
            ProgressSummaryRevision(
                id: $0.id,
                date: $0.date,
                completedTasksCount: $0.completedTasksCount,
                totalTasksCount: $0.totalTasksCount
            )
        }
    }

    private func refreshMetrics() {
        viewModel.load(modelContext: modelContext, referenceDate: Date())
    }

    private func playIntroIfNeeded() {
        guard hasPlayedIntro == false else { return }
        withAnimation(AppMotion.smooth(reduceMotion)) {
            hasPlayedIntro = true
        }
    }
}

private struct ProgressIntroAnimationModifier: ViewModifier {
    let isVisible: Bool
    let reduceMotion: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.97)
            .animation(animation, value: isVisible)
    }

    private var animation: Animation? {
        guard let baseAnimation = AppMotion.smooth(reduceMotion) else {
            return nil
        }

        return reduceMotion ? baseAnimation : baseAnimation.delay(delay)
    }
}

private struct ProgressTaskRevision: Equatable {
    let id: UUID
    let date: Date
    let isCompleted: Bool
    let completedAt: Date?
}

private struct ProgressSummaryRevision: Equatable {
    let id: UUID
    let date: Date
    let completedTasksCount: Int
    let totalTasksCount: Int
}

private struct ProgressMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    let backgroundImageName: String?
    let height: CGFloat

    init(
        title: String,
        value: String,
        systemImage: String,
        color: Color,
        backgroundImageName: String? = nil,
        height: CGFloat
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.color = color
        self.backgroundImageName = backgroundImageName
        self.height = height
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
            bottomIllustration
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.18), radius: 16, x: 0, y: 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: systemImage)
                .font(AppTypography.sectionTitleSemibold)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Spacer(minLength: 8)

            Text(title)
                .font(AppTypography.progressMetricTitle)
                .foregroundStyle(Color(hex: "0F172A"))
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)

            valueView
                .frame(height: 30, alignment: .leading)

            Spacer(minLength: 12)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var valueView: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(valueNumber)
                .font(AppTypography.progressMetricValue)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if valueSuffix.isEmpty == false {
                Text(valueSuffix)
                    .font(AppTypography.progressMetricUnit)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var valueNumber: String {
        value.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? value
    }

    private var valueSuffix: String {
        let parts = value.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count > 1 else { return "" }
        return String(parts[1])
    }

    @ViewBuilder
    private var bottomIllustration: some View {
        GeometryReader { proxy in
            let illustrationHeight = proxy.size.width * 9 / 16
            // Raises the decorative image above the bottom edge so it stays visible inside the card.
            let verticalLift = min(0, proxy.size.height * 0.14)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if let backgroundImageName,
                   UIImage(named: backgroundImageName) != nil {
                    Image(backgroundImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: illustrationHeight)
                        .clipped()
                } else {
                    fallbackIllustration
                        .frame(width: proxy.size.width, height: illustrationHeight)
                        .clipped()
                }
            }
            .padding(.bottom, verticalLift)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .allowsHitTesting(false)
    }

    private var fallbackIllustration: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.08), color.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 44)
                .rotationEffect(.degrees(-7))
                .offset(x: 24, y: 14)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.14), color.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 86, height: 54)
                .rotationEffect(.degrees(-10))
                .offset(x: 44, y: 13)
        }
    }
}

private struct ProgressSectionCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

private struct CardHeader<Legend: View>: View {
    let title: String
    let legend: Legend

    init(
        title: String,
        @ViewBuilder legend: () -> Legend
    ) {
        self.title = title
        self.legend = legend()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                titleText
                Spacer(minLength: 8)
                legend
            }

            VStack(alignment: .leading, spacing: 10) {
                titleText
                legend
            }
        }
    }

    private var titleText: some View {
        Text(title)
            .font(AppTypography.sectionTitleBold)
            .foregroundStyle(AppTheme.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LegendItem: View {
    let title: String
    let color: Color
    let isOutlined: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isOutlined ? Color.white : color)
                .frame(width: 9, height: 9)
                .overlay {
                    Circle()
                        .stroke(isOutlined ? AppTheme.primaryBlue : Color.clear, lineWidth: 1.5)
                }

            Text(title)
                .font(AppTypography.tinySemibold)
                .foregroundStyle(Color(hex: "64748B"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct ThirtyDayCalendarCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    let days: [ProgressCalendarDay]
    let referenceDate: Date

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 10
    )
    private let gridVerticalSpacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            calendarHeader
            calendarGrid
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
        .onAppear {
            withAnimation(AppMotion.quick(reduceMotion)) {
                hasAppeared = true
            }
        }
    }

    private var calendarHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                calendarTitle
                Spacer(minLength: 8)
                calendarLegend
            }

            VStack(alignment: .leading, spacing: 10) {
                calendarTitle
                calendarLegend
            }
        }
    }

    private var calendarTitle: some View {
        Text(LocalizedStrings.calendarThirtyDays)
            .font(AppTypography.calendarTitle)
            .foregroundStyle(Color(hex: "0F172A"))
            .lineLimit(2)
            .minimumScaleFactor(0.86)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var calendarLegend: some View {
        HStack(spacing: 10) {
            LegendItem(
                title: LocalizedStrings.progressDoneLegend,
                color: AppTheme.primaryBlue,
                isOutlined: false
            )
            LegendItem(
                title: LocalizedStrings.progressMissedLegend,
                color: Color(hex: "FFE3E3"),
                isOutlined: false
            )
            LegendItem(
                title: LocalizedStrings.progressTodayLegend,
                color: AppTheme.primaryBlue,
                isOutlined: true
            )
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: gridVerticalSpacing) {
            ForEach(days) { day in
                calendarDayCell(day)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func calendarDayCell(_ day: ProgressCalendarDay) -> some View {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let isToday = day.date.map { Calendar.current.isDateInToday($0) } ?? false
        let isCompleted = day.completedCount > 0
        let isMissed = day.date.map { calendar.startOfDay(for: $0) < todayStart } ?? false
            && isCompleted == false

        return GeometryReader { proxy in
            let size = min(48, proxy.size.width)

            ZStack {
                Circle()
                    .fill(backgroundColor(isToday: isToday, isCompleted: isCompleted, isMissed: isMissed))

                Text("\(day.dayNumber)")
                    .font(AppTypography.calendarDay(cellSize: size))
                    .foregroundStyle(textColor(isToday: isToday, isCompleted: isCompleted, isMissed: isMissed))

                if isToday {
                    todayDoubleStroke(size: size, isCompleted: isCompleted)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .scaleEffect(isCompleted && hasAppeared == false && reduceMotion == false ? 0.92 : 1)
            .animation(AppMotion.quick(reduceMotion), value: hasAppeared)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityTitle(for: day))
    }

    private func todayDoubleStroke(size: CGFloat, isCompleted: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isCompleted ? Color.white.opacity(0.92) : AppTheme.primaryBlue, lineWidth: 1.5)
                .frame(width: size - 6, height: size - 6)

            Circle()
                .stroke(AppTheme.primaryBlue, lineWidth: 2)
                .frame(width: size, height: size)
        }
    }

    private func backgroundColor(
        isToday: Bool,
        isCompleted: Bool,
        isMissed: Bool
    ) -> Color {
        if isToday && isCompleted {
            return AppTheme.primaryBlue
        }

        if isToday {
            return Color.white
        }

        if isCompleted {
            return AppTheme.primaryBlue
        }

        if isMissed {
            return Color(hex: "FFE3E3")
        }

        return Color(hex: "F1F5F9")
    }

    private func textColor(
        isToday: Bool,
        isCompleted: Bool,
        isMissed: Bool
    ) -> Color {
        if isToday && isCompleted {
            return Color.white
        }

        if isToday {
            return AppTheme.primaryBlue
        }

        if isCompleted {
            return Color.white
        }

        if isMissed {
            return Color(hex: "FF5A5F")
        }

        return AppTheme.text
    }

    private func accessibilityTitle(for day: ProgressCalendarDay) -> String {
        guard let date = day.date else {
            return "\(day.dayNumber)"
        }

        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.dateStyle = .medium
        return "\(formatter.string(from: date)), \(day.completedCount)"
    }
}

private struct SevenDayActivityCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    let points: [DailyProgressPoint]

    private var chartMaxValue: Int {
        let maxValue = points.map(\.completedCount).max() ?? 0
        guard maxValue > 0 else { return 1 }

        let paddedValue = Int(ceil(Double(maxValue) * 1.25))
        return max(paddedValue, maxValue + 1)
    }

    var body: some View {
        ProgressSectionCard {
            CardHeader(title: LocalizedStrings.activitySevenDays) {
                LegendItem(
                    title: LocalizedStrings.completedTasksLegend,
                    color: AppTheme.primaryBlue,
                    isOutlined: false
                )
            }

            Chart(displayedPoints) { point in
                BarMark(
                    x: .value(LocalizedStrings.dayAxisTitle, weekdayTitle(for: point.date)),
                    y: .value(LocalizedStrings.tasksAxisTitle, point.completedCount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(hex: "5FB2FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .annotation(position: .top, alignment: .center) {
                    if point.completedCount > 0 {
                        Text("\(point.completedCount)")
                            .font(AppTypography.tinyBold)
                            .foregroundStyle(AppTheme.text)
                    }
                }
            }
            .chartYScale(domain: 0...chartMaxValue)
            .chartXAxis {
                AxisMarks(values: points.map { weekdayTitle(for: $0.date) }) { value in
                    AxisValueLabel {
                        if let title = value.as(String.self) {
                            Text(title)
                                .font(AppTypography.tinySemibold)
                                .foregroundStyle(Color(hex: "64748B"))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color(hex: "D7E8FA"))
                    AxisValueLabel()
                        .font(AppTypography.tiny)
                        .foregroundStyle(Color(hex: "64748B"))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color(hex: "F8FBFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(height: 210)
            .padding(.top, 12)
            .onAppear {
                withAnimation(AppMotion.smooth(reduceMotion)) {
                    hasAppeared = true
                }
            }
        }
    }

    private var displayedPoints: [DailyProgressPoint] {
        guard hasAppeared || reduceMotion else {
            return points.map { DailyProgressPoint(date: $0.date, completedCount: 0) }
        }

        return points
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

private struct WeeklyCompletedTasksCard: View {
    let summary: WeeklyCompletionSummary

    private var ringProgress: CGFloat {
        let denominator = max(summary.currentWeekCount, summary.previousWeekCount, 1)
        return min(1, CGFloat(summary.currentWeekCount) / CGFloat(denominator))
    }

    var body: some View {
        ProgressSectionCard {
            HStack(spacing: 12) {
                Text(LocalizedStrings.weeklyCompletedTasks)
                    .font(AppTypography.sectionTitleBold)
                    .foregroundStyle(AppTheme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink {
                    TaskHistoryView()
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizedStrings.history)
                            .font(AppTypography.buttonText)

                        Image(systemName: "chevron.right")
                            .font(AppTypography.tinyBold)
                    }
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    ring
                    details
                }

                VStack(alignment: .leading, spacing: 16) {
                    ring
                    details
                }
            }
            .padding(.bottom, 4)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "D7E8FA"), lineWidth: 12)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AppTheme.primaryBlue,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(summary.currentWeekCount)")
                    .font(AppTypography.progressRingValue)
                    .foregroundStyle(AppTheme.text)

                Text(LocalizedStrings.tasksWord)
                    .font(AppTypography.tinySemibold)
                    .foregroundStyle(Color(hex: "64748B"))
            }
        }
        .frame(width: 104, height: 104)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(LocalizedStrings.weeklyTasksCount(summary.currentWeekCount))
                .font(AppTypography.progressCardValue)
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            comparisonPill
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var comparisonPill: some View {
        switch summary.trend {
        case .increase:
            pillContainer {
                Text(LocalizedStrings.weeklyMoreThanPreviousPill(summary.difference))
                    .font(AppTypography.compactSemibold)
                    .foregroundStyle(Color(hex: "16A34A"))
            }
            .background(Color(hex: "22C55E").opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

        case .unchanged:
            pillContainer {
                Text(LocalizedStrings.weeklySameAsPreviousPill)
                    .font(AppTypography.compactSemibold)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(AppTheme.primaryBlue)
            .background(AppTheme.primaryBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(AppTheme.primaryBlue.opacity(0.18), lineWidth: 1)
            }

        case .decrease:
            pillContainer {
                Text(LocalizedStrings.weeklyCalmPaceMessage)
                    .font(AppTypography.compactSemibold)
                    .foregroundStyle(Color(hex: "64748B"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .background(AppTheme.screenBackground)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color(hex: "64748B").opacity(0.2), lineWidth: 1)
            }
        }
    }

    private func pillContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 6) {
            content()
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 8)
        .frame(minHeight: 50, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}


private enum TaskHistoryPeriod: CaseIterable, Identifiable {
    case today
    case sevenDays
    case thirtyDays
    case allTime

    var id: Self { self }

    var title: String {
        switch self {
        case .today:
            LocalizedStrings.historyTodayPeriod
        case .sevenDays:
            LocalizedStrings.historySevenDaysPeriod
        case .thirtyDays:
            LocalizedStrings.historyThirtyDaysPeriod
        case .allTime:
            LocalizedStrings.historyAllTimePeriod
        }
    }

    var dayCount: Int? {
        switch self {
        case .today:
            1
        case .sevenDays:
            7
        case .thirtyDays:
            30
        case .allTime:
            nil
        }
    }

    var periodDescription: String {
        switch self {
        case .today:
            return LocalizedStrings.historyForToday
        case .sevenDays, .thirtyDays:
            guard let dayCount else { return LocalizedStrings.historyForAllTime }
            return "\(LocalizedStrings.historyForLast)\n\(LocalizedStrings.historyLastDays(dayCount))"
        case .allTime:
            return LocalizedStrings.historyForAllTime
        }
    }
}

private enum TaskHistoryPremiumAlert: Identifiable {
    case thirtyDays
    case allTime
    case filters

    var id: String {
        switch self {
        case .thirtyDays:
            "thirtyDays"
        case .allTime:
            "allTime"
        case .filters:
            "filters"
        }
    }

    var message: String {
        switch self {
        case .thirtyDays:
            LocalizedStrings.thirtyDayHistoryPremiumMessage
        case .allTime:
            LocalizedStrings.allTimeHistoryPremiumMessage
        case .filters:
            LocalizedStrings.historyFiltersPremiumMessage
        }
    }
}

private struct TaskHistoryGroup: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }
}

private struct TaskHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @ObservedObject private var premiumAccess = PremiumAccessManager.shared
    @Query(sort: \TaskItem.date, order: .reverse) private var tasks: [TaskItem]
    @State private var selectedPeriod: TaskHistoryPeriod = .sevenDays
    @State private var searchText = ""
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority: TaskPriority?
    @State private var draftCategory: TaskCategory?
    @State private var draftPriority: TaskPriority?
    @State private var isShowingFiltersSheet = false
    @State private var premiumAlertMessage = ""
    @State private var isShowingPremiumAlert = false
    @Namespace private var periodSelectionNamespace

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                backButton
                header
                periodPicker
                searchAndFilterControls
                statisticCard

                if periodTasks.isEmpty {
                    emptyState(
                        title: LocalizedStrings.noCompletedTasksTitle,
                        subtitle: LocalizedStrings.noCompletedTasksSubtitle,
                        systemImage: "calendar.badge.checkmark"
                    )
                } else if groupedTasks.isEmpty {
                    emptyState(
                        title: LocalizedStrings.noHistoryResultsTitle,
                        subtitle: LocalizedStrings.noHistoryResultsSubtitle,
                        systemImage: "magnifyingglass"
                    )
                } else {
                    taskGroups
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .dismissKeyboardOnBackgroundTap {
                isSearchFocused = false
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .tabBarContentPadding()
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert(LocalizedStrings.premiumHistoryTitle, isPresented: $isShowingPremiumAlert) {
            Button(LocalizedStrings.gotIt, role: .cancel) {}
        } message: {
            Text(premiumAlertMessage)
        }
        .sheet(isPresented: $isShowingFiltersSheet) {
            TaskHistoryFiltersSheet(
                selectedCategory: $draftCategory,
                selectedPriority: $draftPriority,
                onReset: resetDraftFilters,
                onApply: applyDraftFilters
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.clear)
        }
        .onAppear(perform: enforceAvailableAccess)
        .onChange(of: premiumAccess.isPremium) { _, _ in
            enforceAvailableAccess()
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(AppTypography.sectionTitleSemibold)

                Text(LocalizedStrings.back)
                    .font(AppTypography.sectionTitleSemibold)
            }
            .foregroundStyle(AppTheme.primaryBlue)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStrings.taskHistoryTitle)
                .font(AppTypography.screenTitle)
                .foregroundStyle(Color(hex: "0F172A"))
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStrings.taskHistorySubtitle)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodPicker: some View {
        GeometryReader { geometry in
            let segmentWidth = max((geometry.size.width - 8) / CGFloat(TaskHistoryPeriod.allCases.count), 82)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(TaskHistoryPeriod.allCases) { period in
                        Button {
                            selectPeriod(period)
                        } label: {
                            let isLocked = isPeriodLocked(period)
                            let isSelected = selectedPeriod == period

                            HStack(spacing: 5) {
                                Text(period.title)
                                    .font(AppTypography.buttonText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)

                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(AppTypography.tinyBold)
                                        .accessibilityHidden(true)
                                }
                            }
                            .foregroundStyle(periodTextColor(isSelected: isSelected, isLocked: isLocked))
                            .frame(width: segmentWidth)
                            .frame(minHeight: 42)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(AppTheme.primaryBlue)
                                        .matchedGeometryEffect(
                                            id: "taskHistoryPeriodSelection",
                                            in: periodSelectionNamespace
                                        )
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(isPeriodLocked(period) ? lockedMessage(for: period) : "")
                    }
                }
                .padding(4)
                .frame(minWidth: geometry.size.width, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color(hex: "D8E8FF"), lineWidth: 1)
            }
            .shadow(color: Color(hex: "94A3B8").opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .frame(height: 50)
    }

    private var searchAndFilterControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                searchField
                    .layoutPriority(1)

                filtersButton
            }

            if hasActiveFilters {
                activeFilterChips
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(AppTypography.buttonText)
                .foregroundStyle(Color(hex: "64748B"))

            TextField(
                "",
                text: $searchText,
                prompt: Text(LocalizedStrings.historySearchPlaceholder)
                    .foregroundStyle(Color(hex: "64748B"))
            )
            .focused($isSearchFocused)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppTheme.text)
            .tint(AppTheme.primaryBlue)
            .submitLabel(.search)

            if searchText.isEmpty == false {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.buttonText)
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStrings.deleteTaskAction)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 50)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "D8E8FF"), lineWidth: 1)
        }
        .shadow(color: Color(hex: "94A3B8").opacity(0.12), radius: 12, x: 0, y: 6)
    }

    private var filtersButton: some View {
        Button {
            openFilters()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "slider.horizontal.3")
                    .font(AppTypography.buttonText)

                Text(LocalizedStrings.filters)
                    .font(AppTypography.buttonText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                if premiumAccess.canUseHistoryFilters == false {
                    Image(systemName: "lock.fill")
                        .font(AppTypography.tinyBold)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(AppTheme.primaryBlue.opacity(premiumAccess.canUseHistoryFilters ? 1 : 0.62))
            .padding(.horizontal, 14)
            .frame(width: premiumAccess.canUseHistoryFilters ? 132 : 148)
            .frame(minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "D8E8FF"), lineWidth: 1)
            }
            .shadow(color: Color(hex: "94A3B8").opacity(0.12), radius: 12, x: 0, y: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var activeFilterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if let selectedCategory {
                    TaskHistoryActiveFilterChip(title: selectedCategory.title) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            self.selectedCategory = nil
                        }
                    }
                }

                if let selectedPriority {
                    TaskHistoryActiveFilterChip(title: selectedPriority.title) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            self.selectedPriority = nil
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var statisticCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(filteredTasks.count)")
                    .font(AppTypography.streakCount)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .monospacedDigit()

                Text(LocalizedStrings.tasksCompletedLower)
                    .font(AppTypography.sectionTitleSemibold)
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStrings.excellentWork)
                    .font(AppTypography.compactMedium)
                    .foregroundStyle(Color(hex: "64748B"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(AppTypography.titleIcon)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.background)
                    .clipShape(Circle())

                Text(statisticDescription)
                    .font(AppTypography.compactSemibold)
                    .foregroundStyle(Color(hex: "64748B"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private var taskGroups: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(groupedTasks) { group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(title(for: group.date))
                        .font(AppTypography.sectionTitleBold)
                        .foregroundStyle(Color(hex: "0F172A"))
                        .padding(.horizontal, 2)

                    VStack(spacing: 10) {
                        ForEach(group.tasks) { task in
                            HistoryTaskCard(
                                task: task,
                                completionDate: completionDate(for: task)
                            )
                        }
                    }
                }
            }
        }
    }

    private func emptyState(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.18))
                    .frame(width: 7, height: 7)
                    .offset(x: -28, y: -24)

                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.15))
                    .frame(width: 6, height: 6)
                    .offset(x: 30, y: 22)

                Image(systemName: systemImage)
                    .font(AppTypography.notificationIcon)
                    .foregroundStyle(AppTheme.primaryBlue)
            }
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTypography.sectionTitleSemibold)
                    .foregroundStyle(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(AppTypography.screenSubtitle)
                    .foregroundStyle(Color(hex: "64748B"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private var completedTasks: [TaskItem] {
        let now = Date()

        return tasks
            .filter { task in
                guard task.isCompleted else { return false }
                return completionDate(for: task) <= now
            }
            .sorted { completionDate(for: $0) > completionDate(for: $1) }
    }

    private var periodTasks: [TaskItem] {
        let now = Date()

        guard let dayCount = selectedPeriod.dayCount else {
            return completedTasks
        }

        let todayStart = calendar.startOfDay(for: now)
        let startDate = calendar.date(
            byAdding: .day,
            value: -(dayCount - 1),
            to: todayStart
        ) ?? todayStart

        return completedTasks.filter { task in
            let completion = completionDate(for: task)
            return completion >= startDate && completion <= now
        }
    }

    private var filteredTasks: [TaskItem] {
        let query = normalizedSearchText
        let canFilter = premiumAccess.canUseHistoryFilters

        return periodTasks.filter { task in
            let matchesSearch = query.isEmpty || taskMatchesSearch(task, query: query)
            let matchesCategory = canFilter == false || selectedCategory == nil || task.category == selectedCategory
            let matchesPriority = canFilter == false || selectedPriority == nil || task.priority == selectedPriority
            return matchesSearch && matchesCategory && matchesPriority
        }
    }

    private var groupedTasks: [TaskHistoryGroup] {
        let grouped = Dictionary(grouping: filteredTasks) { task in
            calendar.startOfDay(for: completionDate(for: task))
        }

        return grouped
            .map { TaskHistoryGroup(date: $0.key, tasks: $0.value.sorted { completionDate(for: $0) > completionDate(for: $1) }) }
            .sorted { $0.date > $1.date }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var hasActiveFilters: Bool {
        premiumAccess.canUseHistoryFilters && (selectedCategory != nil || selectedPriority != nil)
    }

    private var hasActiveSearchOrFilters: Bool {
        normalizedSearchText.isEmpty == false || hasActiveFilters
    }

    private var statisticDescription: String {
        hasActiveSearchOrFilters ? LocalizedStrings.historyFilteredResults : selectedPeriod.periodDescription
    }

    private func taskMatchesSearch(_ task: TaskItem, query: String) -> Bool {
        task.title.lowercased().contains(query)
        || task.taskDescription.lowercased().contains(query)
        || task.category.title.lowercased().contains(query)
    }

    private func completionDate(for task: TaskItem) -> Date {
        task.completedAt ?? task.date
    }

    private func selectPeriod(_ period: TaskHistoryPeriod) {
        if isPeriodLocked(period) {
            showPremiumAlert(for: period)
            return
        }

        guard selectedPeriod != period else { return }
        withAnimation(.easeInOut(duration: 0.24)) {
            selectedPeriod = period
        }
    }

    private func openFilters() {
        guard premiumAccess.canUseHistoryFilters else {
            showPremiumAlert(.filters)
            return
        }

        draftCategory = selectedCategory
        draftPriority = selectedPriority
        isShowingFiltersSheet = true
    }

    private func showPremiumAlert(for period: TaskHistoryPeriod) {
        guard let alert = premiumAlertKind(for: period) else { return }
        showPremiumAlert(alert)
    }

    private func showPremiumAlert(_ alert: TaskHistoryPremiumAlert) {
        premiumAlertMessage = alert.message
        isShowingPremiumAlert = true
    }

    private func resetDraftFilters() {
        draftCategory = nil
        draftPriority = nil
    }

    private func applyDraftFilters() {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedCategory = draftCategory
            selectedPriority = draftPriority
        }
        isShowingFiltersSheet = false
    }

    private func enforceAvailableAccess() {
        if selectedPeriod == .thirtyDays, premiumAccess.canViewThirtyDayHistory == false {
            withAnimation(.easeInOut(duration: 0.24)) {
                selectedPeriod = .sevenDays
            }
        }

        if selectedPeriod == .allTime, premiumAccess.canViewAllTimeHistory == false {
            withAnimation(.easeInOut(duration: 0.24)) {
                selectedPeriod = .sevenDays
            }
        }

        if premiumAccess.canUseHistoryFilters == false {
            selectedCategory = nil
            selectedPriority = nil
            draftCategory = nil
            draftPriority = nil
            isShowingFiltersSheet = false
        }
    }

    private func isPeriodLocked(_ period: TaskHistoryPeriod) -> Bool {
        switch period {
        case .today, .sevenDays:
            false
        case .thirtyDays:
            premiumAccess.canViewThirtyDayHistory == false
        case .allTime:
            premiumAccess.canViewAllTimeHistory == false
        }
    }

    private func premiumAlertKind(for period: TaskHistoryPeriod) -> TaskHistoryPremiumAlert? {
        switch period {
        case .today, .sevenDays:
            nil
        case .thirtyDays:
            .thirtyDays
        case .allTime:
            .allTime
        }
    }

    private func lockedMessage(for period: TaskHistoryPeriod) -> String {
        premiumAlertKind(for: period)?.message ?? ""
    }

    private func periodTextColor(isSelected: Bool, isLocked: Bool) -> Color {
        if isSelected {
            return Color.white
        }

        return isLocked ? AppTheme.primaryBlue.opacity(0.58) : AppTheme.primaryBlue
    }

    private func title(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return LocalizedStrings.today
        }

        if calendar.isDateInYesterday(date) {
            return LocalizedStrings.yesterday
        }

        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}

private struct TaskHistoryActiveFilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 5) {
                Text(title)
                    .font(AppTypography.compactSemibold)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(AppTypography.tinyBold)
            }
            .foregroundStyle(AppTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.background)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AppTheme.primaryBlue.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TaskHistoryFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: TaskCategory?
    @Binding var selectedPriority: TaskPriority?
    let onReset: () -> Void
    let onApply: () -> Void

    private let categories: [TaskCategory?] = [nil, .study, .work, .sport, .habits, .personal]
    private let priorities: [TaskPriority?] = [nil, .low, .medium, .high]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "CBD5E1"))
                .frame(width: 42, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    categorySection
                    prioritySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            actions
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStrings.filters)
                .font(AppTypography.screenTitle)
                .foregroundStyle(Color(hex: "0F172A"))

            Text(LocalizedStrings.filtersSubtitle)
                .font(AppTypography.screenSubtitle)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.category)
                .font(AppTypography.sectionTitleBold)
                .foregroundStyle(AppTheme.text)

            TwoColumnSelectionGrid(items: categories) { category in
                SelectionTile(
                    title: category?.title ?? LocalizedStrings.all,
                    systemImage: category?.historySymbolName ?? "square.grid.2x2",
                    color: category?.filterColor ?? AppTheme.primaryBlue,
                    unselectedColor: category?.filterColor ?? AppTheme.primaryBlue,
                    isSelected: selectedCategory == category,
                    selectedColor: category?.filterColor ?? AppTheme.primaryBlue,
                    selectedBorderColor: category?.filterColor ?? AppTheme.primaryBlue,
                    selectedBackgroundColor: (category?.filterColor ?? AppTheme.primaryBlue).opacity(0.1)
                ) {
                    selectedCategory = category
                }
            }
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.priority)
                .font(AppTypography.sectionTitleBold)
                .foregroundStyle(AppTheme.text)

            TwoColumnSelectionGrid(items: priorities) { priority in
                SelectionTile(
                    title: priority?.title ?? LocalizedStrings.all,
                    systemImage: priority?.historyFilterIcon ?? "line.3.horizontal.decrease.circle",
                    color: priority?.displayColor ?? AppTheme.primaryBlue,
                    unselectedColor: priority?.displayColor ?? AppTheme.primaryBlue,
                    isSelected: selectedPriority == priority,
                    selectedColor: priority?.displayColor ?? AppTheme.primaryBlue,
                    selectedBorderColor: priority?.displayColor ?? AppTheme.primaryBlue,
                    selectedBackgroundColor: (priority?.displayColor ?? AppTheme.primaryBlue).opacity(0.1)
                ) {
                    selectedPriority = priority
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                onReset()
            } label: {
                Text(LocalizedStrings.resetFilters)
                    .font(AppTypography.primaryButton)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onApply()
            } label: {
                Text(LocalizedStrings.applyFilters)
                    .font(AppTypography.primaryButton)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct HistoryTaskCard: View {
    let task: TaskItem
    let completionDate: Date

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(AppTypography.sectionTitleBold)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 44, height: 44)
                .background(AppTheme.background)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(task.title)
                    .font(AppTypography.sectionTitleSemibold)
                    .foregroundStyle(Color(hex: "0F172A"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if task.taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    Text(task.taskDescription)
                        .font(AppTypography.compactMedium)
                        .foregroundStyle(Color(hex: "64748B"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                metadata
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.1), radius: 12, x: 0, y: 6)
    }

    private var metadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) {
                categoryMetadata
                separator
                priorityMetadata
                separator
                timeMetadata
            }

            VStack(alignment: .leading, spacing: 5) {
                categoryMetadata

                HStack(spacing: 7) {
                    priorityMetadata
                    separator
                    timeMetadata
                }
            }
        }
        .font(AppTypography.taskMetadata)
        .foregroundStyle(Color(hex: "64748B"))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var categoryMetadata: some View {
        Label(task.category.title, systemImage: task.category.historySymbolName)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var priorityMetadata: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(task.priority.displayColor)
                .frame(width: 6, height: 6)

            Text(task.priority.title)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timeMetadata: some View {
        Label(completionTimeText, systemImage: "clock")
            .fixedSize(horizontal: false, vertical: true)
    }

    private var separator: some View {
        Text("·")
            .foregroundStyle(Color(hex: "94A3B8"))
    }

    private var completionTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: completionDate)
    }
}

private extension TaskCategory {
    var historySymbolName: String {
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

    var filterColor: Color {
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
    var historyFilterIcon: String {
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
#Preview("Карточки Progress: изображения") {
    ProgressMetricCardsPreview(usesImages: true)
        .padding()
        .background(AppTheme.screenBackground)
}

#Preview("Карточки Progress: реальные значения") {
    ProgressMetricCardsPreview(
        usesImages: true,
        values: (
            LocalizedStrings.daysCount(7),
            LocalizedStrings.tasksCount(8),
            LocalizedStrings.tasksCount(5)
        )
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Карточки Progress: длинные значения") {
    ProgressMetricCardsPreview(
        usesImages: true,
        values: (
            LocalizedStrings.daysCount(128),
            LocalizedStrings.tasksCount(999),
            LocalizedStrings.tasksCount(230)
        )
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Карточки Progress: fallback") {
    ProgressMetricCardsPreview(usesImages: false)
        .padding()
        .background(AppTheme.screenBackground)
}

#Preview(
    "Карточки Progress: iPhone SE",
    traits: .fixedLayout(width: 320, height: 205)
) {
    ProgressMetricCardsPreview(usesImages: true)
        .padding(.horizontal, 16)
        .background(AppTheme.screenBackground)
}

#Preview("Календарь: все состояния") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.mixedDays(completedToday: false),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Календарь: пропущенные дни") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.missedDays(),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Календарь: выполненные дни") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.completedDays(),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Календарь: числа 1-30") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.numberedDays(),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Календарь: текущий день") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.emptyTodayDays(),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview("Календарь: выполненный сегодня") {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.mixedDays(completedToday: true),
        referenceDate: Date()
    )
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview(
    "Календарь: iPhone SE",
    traits: .fixedLayout(width: 320, height: 260)
) {
    ThirtyDayCalendarCard(
        days: CalendarPreviewData.mixedDays(completedToday: true),
        referenceDate: Date()
    )
    .padding(.horizontal, 16)
    .background(AppTheme.screenBackground)
}

#Preview("Progress: без выполненных задач") {
    ProgressView()
        .modelContainer(PreviewData.progressZeroStreakContainer())
        .environmentObject(AppState())
}

#Preview("Progress: активная серия") {
    ProgressView()
        .modelContainer(PreviewData.progressStreakContainer())
        .environmentObject(AppState())
}

#Preview("Progress: предупреждение серии") {
    ProgressView()
        .modelContainer(PreviewData.progressStreakWarningContainer())
        .environmentObject(AppState())
}

#Preview("Progress: сегодня только обводка") {
    ProgressView()
        .modelContainer(PreviewData.progressTodayOutlineOnlyContainer())
        .environmentObject(AppState())
}

#Preview("Progress: заполненный недельный график") {
    ProgressView()
        .modelContainer(PreviewData.progressFilledWeekContainer())
        .environmentObject(AppState())
}

#Preview("Progress: новый лучший результат") {
    ProgressView()
        .modelContainer(PreviewData.progressNewBestResultContainer())
        .environmentObject(AppState())
}

#Preview("График: высокие значения") {
    SevenDayActivityCard(points: ActivityChartPreviewData.highValues())
        .padding()
        .background(AppTheme.screenBackground)
}

#Preview("Неделя: спокойный ритм") {
    WeeklyCompletedTasksCard(
        summary: WeeklyCompletionSummary(
            currentWeekCount: 4,
            previousWeekCount: 17
        )
    )
    .padding()
    .background(AppTheme.screenBackground)
}

private struct ProgressMetricCardsPreview: View {
    let usesImages: Bool
    var values: (streak: String, best: String, completed: String) = (
        LocalizedStrings.daysCount(7),
        LocalizedStrings.tasksCount(8),
        LocalizedStrings.tasksCount(5)
    )
    var height: CGFloat = 142

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ProgressMetricCard(
                title: LocalizedStrings.currentStreak,
                value: values.streak,
                systemImage: "flame.fill",
                color: AppTheme.primaryBlue,
                backgroundImageName: usesImages ? "currentStreakBackground" : nil,
                height: height
            )

            ProgressMetricCard(
                title: LocalizedStrings.bestResult,
                value: values.best,
                systemImage: "trophy.fill",
                color: Color(hex: "7C3AED"),
                backgroundImageName: usesImages ? "bestResultBackground" : nil,
                height: height
            )

            ProgressMetricCard(
                title: LocalizedStrings.completedToday,
                value: values.completed,
                systemImage: "checkmark.circle.fill",
                color: Color(hex: "22C55E"),
                backgroundImageName: usesImages ? "completedTodayBackground" : nil,
                height: height
            )
        }
    }
}

private enum ActivityChartPreviewData {
    static func highValues() -> [DailyProgressPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today

        return [0, 1, 7, 17, 25, 4, 9].enumerated().map { index, value in
            let date = calendar.date(byAdding: .day, value: index, to: weekStart) ?? today
            return DailyProgressPoint(date: date, completedCount: value)
        }
    }
}

private enum CalendarPreviewData {
    static func numberedDays() -> [ProgressCalendarDay] {
        makeDays { _ in 0 }
    }

    static func missedDays() -> [ProgressCalendarDay] {
        makeDays { _ in 0 }
    }

    static func completedDays() -> [ProgressCalendarDay] {
        makeDays { dayNumber in
            let todayNumber = Calendar.current.component(.day, from: Date())
            guard dayNumber < todayNumber else { return 0 }
            return dayNumber % 2 == 0 ? 2 : 1
        }
    }

    static func mixedDays(completedToday: Bool) -> [ProgressCalendarDay] {
        makeDays { dayNumber in
            let todayNumber = Calendar.current.component(.day, from: Date())

            if dayNumber == todayNumber {
                return completedToday ? 2 : 0
            }

            if dayNumber % 5 == 0 || dayNumber % 7 == 0 {
                return max(1, dayNumber % 4)
            }

            return 0
        }
    }

    static func emptyTodayDays() -> [ProgressCalendarDay] {
        makeDays { dayNumber in
            let todayNumber = Calendar.current.component(.day, from: Date())
            return [todayNumber - 1, todayNumber - 3, todayNumber - 8].contains(dayNumber) ? 1 : 0
        }
    }

    private static func makeDays(
        completedCount: (Int) -> Int
    ) -> [ProgressCalendarDay] {
        let calendar = Calendar.current
        let referenceDate = Date()
        let monthComponents = calendar.dateComponents([.year, .month], from: referenceDate)
        let monthStart = calendar.date(from: monthComponents) ?? calendar.startOfDay(for: referenceDate)
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart)
        let maximumDay = monthRange?.count ?? 30

        return (1...maximumDay).map { dayNumber in
            let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)

            return ProgressCalendarDay(
                dayNumber: dayNumber,
                date: date,
                completedCount: completedCount(dayNumber)
            )
        }
    }
}
#endif
