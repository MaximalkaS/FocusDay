import AppIntents
import SwiftUI
import WidgetKit

struct FocusDayWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: FocusDayWidgetSnapshot
}

struct FocusDayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusDayWidgetEntry {
        FocusDayWidgetEntry(date: Date(), snapshot: .previewSelected)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusDayWidgetEntry) -> Void) {
        Task { @MainActor in
            completion(
                FocusDayWidgetEntry(
                    date: Date(),
                    snapshot: WidgetSnapshotService.makeTimelineSnapshot()
                )
            )
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusDayWidgetEntry>) -> Void) {
        Task { @MainActor in
            let now = Date()
            let snapshot = WidgetSnapshotService.makeTimelineSnapshot(referenceDate: now)
            var entries = [FocusDayWidgetEntry(date: now, snapshot: snapshot)]
            var nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)

            if let displayUntil = snapshot.completedMainTaskDisplayUntil, displayUntil > now {
                entries.append(
                    FocusDayWidgetEntry(
                        date: displayUntil,
                        snapshot: snapshot.hidingCompletedMainTask()
                    )
                )
                nextUpdate = displayUntil.addingTimeInterval(1)
            }

            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }
}

struct FocusDayWidgets: Widget {
    let kind = "FocusDayWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusDayWidgetProvider()) { entry in
            FocusDayWidgetView(entry: entry)
        }
        .configurationDisplayName("FocusDay")
        .description(WidgetText.choose("Главное дело, прогресс дня и серия.", "Main task, daily progress, and streak."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct FocusDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusDayWidgets()
    }
}

private struct FocusDayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FocusDayWidgetEntry

    var body: some View {
        Group {
            if shouldShowPremiumLockedState {
                PremiumLockedWidgetView()
            } else {
                switch family {
                case .systemSmall:
                    SmallFocusDayWidget(snapshot: entry.snapshot)
                case .systemMedium:
                    MediumFocusDayWidget(snapshot: entry.snapshot)
                case .systemLarge:
                    LargeFocusDayWidget(snapshot: entry.snapshot)
                default:
                    MediumFocusDayWidget(snapshot: entry.snapshot)
                }
            }
        }
        .containerBackground(for: .widget) {
            WidgetPalette.white
        }
        .widgetURL(URL(string: "focusday://today"))
    }

    private var shouldShowPremiumLockedState: Bool {
        family != .systemSmall && entry.snapshot.isPremium == false
    }
}

private struct SmallFocusDayWidget: View {
    let snapshot: FocusDayWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            WidgetHeader(compact: true)
                .layoutPriority(3)

            if let mainTask = snapshot.mainTask {
                Text(mainTask.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(mainTask.isCompleted ? WidgetPalette.mutedText : WidgetPalette.text)
                    .strikethrough(mainTask.isCompleted, color: WidgetPalette.mutedText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                Spacer(minLength: 1)

                HStack(spacing: 6) {
                    InteractiveWidgetCheckbox(task: mainTask, size: 23)

                    Text(mainTask.isCompleted ? WidgetText.done : WidgetText.notDone)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(mainTask.isCompleted ? WidgetPalette.primaryBlue : WidgetPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .layoutPriority(3)
            } else {
                MainTaskSelectionControl(
                    axis: .vertical,
                    availableTaskCount: snapshot.availableTaskCount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .layoutPriority(1)
            }
        }
        .padding(10)
    }
}

private struct MediumFocusDayWidget: View {
    let snapshot: FocusDayWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let mainTask = snapshot.mainTask {
                HStack(alignment: .top, spacing: 8) {
                    InteractiveWidgetCheckbox(task: mainTask, size: 30)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(WidgetText.mainTask)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetPalette.mutedText)

                        Text(mainTask.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(mainTask.isCompleted ? WidgetPalette.mutedText : WidgetPalette.text)
                            .strikethrough(mainTask.isCompleted, color: WidgetPalette.mutedText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: 9) {
                    WidgetHeader(compact: false)
                    Spacer(minLength: 6)
                    MainTaskSelectionControl(
                        axis: .horizontal,
                        availableTaskCount: snapshot.availableTaskCount
                    )
                    .frame(maxWidth: 190, alignment: .trailing)
                }
            }

            Rectangle()
                .fill(WidgetPalette.softLine)
                .frame(height: 1)

            HStack(spacing: 8) {
                ProgressSummaryBlock(snapshot: snapshot)
                StreakSummaryBlock(streak: snapshot.currentStreak)
            }
        }
        .padding(13)
    }
}

private struct LargeFocusDayWidget: View {
    let snapshot: FocusDayWidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                WidgetHeader(compact: false)

                if let mainTask = snapshot.mainTask {
                    WidgetTaskRow(task: mainTask, isMain: true)
                } else {
                    MainTaskSelectionControl(
                        axis: .horizontal,
                        availableTaskCount: snapshot.availableTaskCount
                    )
                }

                WidgetAdditionalTasksList(tasks: snapshot.additionalTasks)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 8) {
                LargeProgressBlock(snapshot: snapshot)
                LargeStreakBlock(streak: snapshot.currentStreak)
            }
            .frame(width: 112)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
    }
}

private struct WidgetHeader: View {
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 3) {
            Text("FocusDay")
                .font(.system(size: compact ? 15 : 18, weight: .bold))
                .foregroundStyle(WidgetPalette.primaryBlue)
                .lineLimit(1)

            Text(WidgetText.mainTask)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
                .foregroundStyle(WidgetPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}

private enum CalloutAxis {
    case horizontal
    case vertical
}

private struct MainTaskSelectionControl: View {
    let axis: CalloutAxis
    let availableTaskCount: Int

    var body: some View {
        if availableTaskCount > 0 {
            Button(intent: SelectRecommendedMainTaskIntent()) {
                AddMainTaskCallout(axis: axis, title: WidgetText.chooseMainTask)
            }
            .buttonStyle(.plain)
        } else if let url = URL(string: "focusday://add-task") {
            Link(destination: url) {
                AddMainTaskCallout(axis: axis, title: WidgetText.noAvailableTasks)
            }
        } else {
            AddMainTaskCallout(axis: axis, title: WidgetText.noAvailableTasks)
        }
    }
}

private struct AddMainTaskCallout: View {
    let axis: CalloutAxis
    let title: String

    var body: some View {
        switch axis {
        case .horizontal:
            HStack(spacing: 8) {
                plusButton
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        case .vertical:
            VStack(spacing: 4) {
                plusButton
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var plusButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WidgetPalette.softBlueBackground)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                .foregroundStyle(WidgetPalette.primaryBlue.opacity(0.45))

            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryBlue)
        }
        .frame(width: plusButtonSize, height: plusButtonSize)
    }

    private var plusButtonSize: CGFloat {
        axis == .vertical ? 42 : 46
    }
}

private struct ProgressSummaryBlock: View {
    let snapshot: FocusDayWidgetSnapshot

    var body: some View {
        HStack(spacing: 7) {
            WidgetProgressRing(progress: progress, size: 38, lineWidth: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(snapshot.completedTodayCount) из \(snapshot.totalTodayCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(WidgetText.tasksDone)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetPalette.mutedText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(WidgetPalette.softBlueBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var progress: Double {
        guard snapshot.totalTodayCount > 0 else { return 0 }
        return Double(snapshot.completedTodayCount) / Double(snapshot.totalTodayCount)
    }
}

private struct StreakSummaryBlock: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryBlue)
                .frame(width: 38, height: 38)
                .background(WidgetPalette.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(WidgetText.days(streak))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(WidgetText.streak)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetPalette.mutedText)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(WidgetPalette.softBlueBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LargeProgressBlock: View {
    let snapshot: FocusDayWidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            Text(WidgetText.dayProgress)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetPalette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            WidgetProgressRing(progress: progress, size: 58, lineWidth: 6)

            Text("\(snapshot.completedTodayCount) из \(snapshot.totalTodayCount)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WidgetPalette.primaryBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(WidgetText.tasksDone)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetPalette.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(WidgetPalette.softBlueBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var progress: Double {
        guard snapshot.totalTodayCount > 0 else { return 0 }
        return Double(snapshot.completedTodayCount) / Double(snapshot.totalTodayCount)
    }
}

private struct LargeStreakBlock: View {
    let streak: Int

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryBlue)

            Text(WidgetText.days(streak))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WidgetPalette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(WidgetText.currentStreak)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetPalette.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetPalette.softBlueBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WidgetAdditionalTasksList: View {
    let tasks: [FocusDayWidgetTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(tasks.prefix(3)) { task in
                WidgetTaskRow(task: task, isMain: false)
            }

            if tasks.isEmpty {
                NoOtherTasksHint()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct WidgetTaskRow: View {
    let task: FocusDayWidgetTask
    let isMain: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            InteractiveWidgetCheckbox(task: task, size: isMain ? 28 : 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: isMain ? 16 : 13, weight: isMain ? .semibold : .medium))
                    .foregroundStyle(task.isCompleted ? WidgetPalette.mutedText : WidgetPalette.text)
                    .strikethrough(task.isCompleted, color: WidgetPalette.mutedText)
                    .lineLimit(isMain ? 2 : 1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 4) {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 6, height: 6)

                    Text(task.priorityTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, isMain ? 9 : 8)
        .padding(.vertical, isMain ? 8 : 7)
        .background(isMain ? WidgetPalette.softBlueBackground : WidgetPalette.white)
        .clipShape(RoundedRectangle(cornerRadius: isMain ? 16 : 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: isMain ? 16 : 14, style: .continuous)
                .stroke(isMain ? WidgetPalette.primaryBlue.opacity(0.12) : WidgetPalette.softLine, lineWidth: 1)
        }
    }

    private var priorityColor: Color {
        switch task.priorityRawValue {
        case "low":
            return WidgetPalette.lowPriority
        case "high":
            return WidgetPalette.highPriority
        default:
            return WidgetPalette.mediumPriority
        }
    }
}


private struct InteractiveWidgetCheckbox: View {
    let task: FocusDayWidgetTask
    let size: CGFloat

    var body: some View {
        if task.isCompleted {
            WidgetCheckbox(isCompleted: true, size: size)
        } else {
            Button(intent: CompleteTaskIntent(taskId: task.id.uuidString)) {
                WidgetCheckbox(isCompleted: false, size: size)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct WidgetCheckbox: View {
    let isCompleted: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? WidgetPalette.primaryBlue : WidgetPalette.white)

            Circle()
                .stroke(WidgetPalette.primaryBlue, lineWidth: 1.8)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(WidgetPalette.white)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct WidgetProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetPalette.primaryBlue.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    WidgetPalette.primaryBlue,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

private struct PlaceholderHint: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryBlue)
                .frame(width: 28, height: 28)
                .background(WidgetPalette.primaryBlue.opacity(0.1))
                .clipShape(Circle())

            Text(WidgetText.addTasksHint)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetPalette.mutedText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WidgetPalette.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct NoOtherTasksHint: View {
    var body: some View {
        Text(WidgetText.noOtherTasks)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(WidgetPalette.mutedText)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WidgetPalette.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PlaceholderLine: View {
    let widthScale: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(WidgetPalette.softLine)
            .frame(height: 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .scaleEffect(x: widthScale, y: 1, anchor: .leading)
    }
}

private struct PremiumLockedWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryBlue)
                .frame(width: 44, height: 44)
                .background(WidgetPalette.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            Text(WidgetText.premiumTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(WidgetPalette.text)
                .multilineTextAlignment(.center)

            Text(WidgetText.premiumWidgetsMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetPalette.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum WidgetPalette {
    static let white = Color(hex: "FFFFFF")
    static let primaryBlue = Color(hex: "007BFF")
    static let text = Color(hex: "0F172A")
    static let mutedText = Color(hex: "64748B")
    static let softBlueBackground = Color(hex: "F2F7FF")
    static let softLine = Color(hex: "D8E8FF")
    static let lowPriority = Color(hex: "22C55E")
    static let mediumPriority = Color(hex: "FF9F0A")
    static let highPriority = Color(hex: "FF5A5F")
}

private enum WidgetText {
    static var isRussian: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("ru") == true
    }

    static func choose(_ russian: String, _ english: String) -> String {
        isRussian ? russian : english
    }

    static let mainTask = choose("Главное дело дня", "Main task of the day")
    static let chooseMainTask = choose("Выбрать главное дело", "Choose main task")
    static let notDone = choose("Не выполнено", "Not done")
    static let done = choose("Выполнено", "Done")
    static let tasksDone = choose("задач выполнено", "tasks done")
    static let streak = choose("серия", "streak")
    static let currentStreak = choose("текущая серия", "current streak")
    static let dayProgress = choose("Прогресс дня", "Day progress")
    static let addTasksHint = choose("Добавьте задачи, чтобы видеть прогресс", "Add tasks to see progress")
    static let premiumTitle = choose("Доступно в Premium", "Available in Premium")
    static let premiumWidgetsMessage = choose("Расширенные виджеты доступны в Premium", "Extended widgets are available in Premium")
    static let noAvailableTasks = choose("Нет доступных задач", "No available tasks")
    static let noOtherTasks = choose("Других задач пока нет", "No other tasks yet")

    static func days(_ count: Int) -> String {
        guard isRussian else {
            return count == 1 ? "1 day" : "\(count) days"
        }

        let remainder10 = count % 10
        let remainder100 = count % 100
        let suffix: String
        if remainder10 == 1 && remainder100 != 11 {
            suffix = "день"
        } else if (2...4).contains(remainder10) && !(12...14).contains(remainder100) {
            suffix = "дня"
        } else {
            suffix = "дней"
        }

        return "\(count) \(suffix)"
    }
}

private extension Color {
    init(hex: String) {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: normalizedHex).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch normalizedHex.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 24
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = 51
            green = 51
            blue = 51
            alpha = 255
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

private extension FocusDayWidgetSnapshot {
    static let previewNoMain = FocusDayWidgetSnapshot(
        updatedAt: Date(),
        mainTask: nil,
        additionalTasks: [
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("Подготовить конспект", "Prepare notes"),
                categoryTitle: WidgetText.choose("Учёба", "Study"),
                priorityTitle: WidgetText.choose("Высокий", "High"),
                priorityRawValue: "high",
                isCompleted: false
            ),
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("Разобрать входящие", "Sort inbox"),
                categoryTitle: WidgetText.choose("Работа", "Work"),
                priorityTitle: WidgetText.choose("Средний", "Medium"),
                priorityRawValue: "medium",
                isCompleted: false
            ),
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("Прогулка", "Walk"),
                categoryTitle: WidgetText.choose("Спорт", "Sport"),
                priorityTitle: WidgetText.choose("Низкий", "Low"),
                priorityRawValue: "low",
                isCompleted: false
            )
        ],
        completedTodayCount: 0,
        totalTodayCount: 3,
        availableTaskCount: 3,
        currentStreak: 0,
        isPremium: true,
        completedMainTaskDisplayUntil: nil
    )

    static let previewSelected = FocusDayWidgetSnapshot(
        updatedAt: Date(),
        mainTask: FocusDayWidgetTask(
            id: UUID(),
            title: WidgetText.choose("Подготовить важную презентацию", "Prepare the important presentation"),
            categoryTitle: WidgetText.choose("Работа", "Work"),
            priorityTitle: WidgetText.choose("Высокий", "High"),
            priorityRawValue: "high",
            isCompleted: false
        ),
        additionalTasks: [
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("Ответить на письма", "Reply to emails"),
                categoryTitle: WidgetText.choose("Работа", "Work"),
                priorityTitle: WidgetText.choose("Средний", "Medium"),
                priorityRawValue: "medium",
                isCompleted: true
            ),
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("Тренировка", "Workout"),
                categoryTitle: WidgetText.choose("Спорт", "Sport"),
                priorityTitle: WidgetText.choose("Низкий", "Low"),
                priorityRawValue: "low",
                isCompleted: false
            )
        ],
        completedTodayCount: 2,
        totalTodayCount: 5,
        availableTaskCount: 3,
        currentStreak: 3,
        isPremium: true,
        completedMainTaskDisplayUntil: nil
    )

    static let previewCompleted = FocusDayWidgetSnapshot(
        updatedAt: Date(),
        mainTask: FocusDayWidgetTask(
            id: UUID(),
            title: WidgetText.choose("Закрыть главное дело", "Finish the main task"),
            categoryTitle: WidgetText.choose("Личные дела", "Personal"),
            priorityTitle: WidgetText.choose("Высокий", "High"),
            priorityRawValue: "high",
            isCompleted: true
        ),
        additionalTasks: [
            FocusDayWidgetTask(
                id: UUID(),
                title: WidgetText.choose("План на завтра", "Plan tomorrow"),
                categoryTitle: WidgetText.choose("Привычки", "Habits"),
                priorityTitle: WidgetText.choose("Средний", "Medium"),
                priorityRawValue: "medium",
                isCompleted: true
            )
        ],
        completedTodayCount: 5,
        totalTodayCount: 5,
        availableTaskCount: 0,
        currentStreak: 5,
        isPremium: true,
        completedMainTaskDisplayUntil: Date().addingTimeInterval(FocusDayWidgetConstants.completedMainTaskDisplayDuration)
    )

    static let previewFreeLocked = FocusDayWidgetSnapshot(
        updatedAt: Date(),
        mainTask: previewSelected.mainTask,
        additionalTasks: previewSelected.additionalTasks,
        completedTodayCount: 2,
        totalTodayCount: 5,
        availableTaskCount: 3,
        currentStreak: 3,
        isPremium: false,
        completedMainTaskDisplayUntil: nil
    )
}

#Preview("Small · No Main", as: .systemSmall) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewNoMain)
}

#Preview("Small · Selected", as: .systemSmall) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewSelected)
}

#Preview("Small · Completed", as: .systemSmall) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewCompleted)
}

#Preview("Medium · No Main", as: .systemMedium) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewNoMain)
}

#Preview("Medium · Selected", as: .systemMedium) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewSelected)
}

#Preview("Medium · Completed", as: .systemMedium) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewCompleted)
}

#Preview("Large · No Main", as: .systemLarge) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewNoMain)
}

#Preview("Large · Selected", as: .systemLarge) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewSelected)
}

#Preview("Large · Completed", as: .systemLarge) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewCompleted)
}

#Preview("Premium Locked", as: .systemMedium) {
    FocusDayWidgets()
} timeline: {
    FocusDayWidgetEntry(date: Date(), snapshot: .previewFreeLocked)
}
