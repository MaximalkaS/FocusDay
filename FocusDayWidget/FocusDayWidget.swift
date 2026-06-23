import SwiftUI
import WidgetKit

struct FocusDayWidgetEntry: TimelineEntry {
    let date: Date
    let mainTaskTitle: String?
}

struct FocusDayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusDayWidgetEntry {
        FocusDayWidgetEntry(date: Date(), mainTaskTitle: LocalizedStrings.widgetEmptyTitle)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusDayWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusDayWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> FocusDayWidgetEntry {
        FocusDayWidgetEntry(
            date: Date(),
            mainTaskTitle: FocusDayWidgetStore.readMainTaskTitle()
        )
    }
}

struct FocusDayWidgetView: View {
    let entry: FocusDayWidgetEntry

    var body: some View {
        ZStack {
            AppTheme.background

            VStack(alignment: .leading, spacing: 10) {
                Label(LocalizedStrings.widgetTitle, systemImage: "target")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primaryBlue)

                Text(entry.mainTaskTitle ?? LocalizedStrings.widgetEmptyTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text(LocalizedStrings.widgetPrompt)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .containerBackground(AppTheme.background, for: .widget)
    }
}

struct FocusDayWidget: Widget {
    let kind = "FocusDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusDayWidgetProvider()) { entry in
            FocusDayWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStrings.appName)
        .description(LocalizedStrings.widgetTitle)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct FocusDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusDayWidget()
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    FocusDayWidget()
} timeline: {
    FocusDayWidgetEntry(date: Date(), mainTaskTitle: "Подготовить конспект")
}
#endif
