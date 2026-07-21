import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(UserDefaultsKeys.hasCompletedIntroOnboarding) private var hasCompletedIntroOnboarding = false
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else if hasCompletedIntroOnboarding {
                OnboardingView {
                    hasCompletedIntroOnboarding = true
                    hasCompletedOnboarding = true
                }
            } else {
                OnboardingIntroView {
                    hasCompletedIntroOnboarding = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: hasCompletedIntroOnboarding)
        .animation(.easeInOut(duration: 0.28), value: hasCompletedOnboarding)
        .tint(AppTheme.primaryBlue)
        .preferredColorScheme(.light)
        .task {
            prepareCurrentDay()
        }
        .task(id: scenePhase) {
            await monitorCalendarDayChanges()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            prepareCurrentDay()
        }
    }

    private func prepareCurrentDay() {
        do {
            try DayTransitionService.prepareForCurrentDay(
                modelContext: modelContext,
                calendar: .current,
                referenceDate: Date()
            )
            WidgetSnapshotService.refresh(modelContext: modelContext)
        } catch {
            // Individual screens surface storage errors through their existing state.
        }
    }

    @MainActor
    private func monitorCalendarDayChanges() async {
        guard scenePhase == .active else { return }

        while Task.isCancelled == false {
            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: today) else {
                return
            }

            let interval = max(nextDay.timeIntervalSince(now) + 0.25, 0.25)
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                return
            }

            guard Task.isCancelled == false, scenePhase == .active else { return }
            prepareCurrentDay()
            NotificationCenter.default.post(name: .focusDayCalendarDayDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let focusDayCalendarDayDidChange = Notification.Name(
        "FocusDayCalendarDayDidChange"
    )
}

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(PreviewData.previewContainer())
}
#endif
