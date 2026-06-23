import SwiftUI

enum SaveFeedbackContext: Equatable {
    case eveningSummary
    case settings
    case progress
    case taskDeletion
}

enum SaveStatus: Equatable {
    case hidden
    case loading
    case success
}

struct SaveFeedback: Equatable {
    let context: SaveFeedbackContext?
    let status: SaveStatus

    static let hidden = SaveFeedback(context: nil, status: .hidden)
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var saveFeedback = SaveFeedback.hidden
    @Published private(set) var taskListRevision = 0

    private var feedbackTask: Task<Void, Never>?

    func beginSaving(_ context: SaveFeedbackContext) {
        feedbackTask?.cancel()
        saveFeedback = SaveFeedback(context: context, status: .loading)
    }

    func completeSaving(_ context: SaveFeedbackContext) {
        feedbackTask?.cancel()
        feedbackTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 1_700_000_000)
            } catch {
                return
            }

            guard let self,
                  Task.isCancelled == false,
                  self.saveFeedback.context == context else { return }

            self.saveFeedback = SaveFeedback(context: context, status: .success)

            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }

            guard Task.isCancelled == false else { return }

            self.saveFeedback = .hidden
        }
    }

    func cancelFeedback() {
        feedbackTask?.cancel()
        saveFeedback = .hidden
    }

    func status(for context: SaveFeedbackContext) -> SaveStatus {
        saveFeedback.context == context ? saveFeedback.status : .hidden
    }

    func status(for contexts: [SaveFeedbackContext]) -> SaveStatus {
        guard let context = saveFeedback.context,
              contexts.contains(context) else { return .hidden }
        return saveFeedback.status
    }

    func taskDataDidChange() {
        taskListRevision += 1
    }
}

struct SaveStatusSnackbar: View {
    let status: SaveStatus

    private let cornerRadius: CGFloat = 12
    private let snackbarWidth: CGFloat = 300
    private let snackbarHeight: CGFloat = 68

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.screenBackground)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppTheme.softBlue.opacity(0.85), lineWidth: 1)

            HStack(spacing: 12) {
                statusIcon
                statusText
            }
            .padding(.horizontal, 18)
        }
        .frame(width: snackbarWidth, height: snackbarHeight)
        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
        .opacity(status == .hidden ? 0 : 1)
        .animation(.easeInOut(duration: 0.24), value: status == .hidden)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: some View {
        ZStack {
            SwiftUI.ProgressView()
                .controlSize(.small)
                .tint(AppTheme.primaryBlue)
                .opacity(status == .loading ? 1 : 0)
                .scaleEffect(status == .loading ? 1 : 0.82)

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.success)
                .opacity(status == .success ? 1 : 0)
                .scaleEffect(status == .success ? 1 : 0.82)
        }
        .frame(width: 28, height: 28)
        .animation(.easeInOut(duration: 0.22), value: status)
    }

    private var statusText: some View {
        ZStack(alignment: .leading) {
            Text(LocalizedStrings.savingProgress)
                .opacity(status == .loading ? 1 : 0)
                .scaleEffect(status == .loading ? 1 : 0.98, anchor: .leading)

            Text(LocalizedStrings.changesSaved)
                .opacity(status == .success ? 1 : 0)
                .scaleEffect(status == .success ? 1 : 0.98, anchor: .leading)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppTheme.text)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: status)
    }
}

struct SaveFeedbackOverlay: View {
    let status: SaveStatus

    var body: some View {
        SaveStatusSnackbar(status: status)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .top)
            .allowsHitTesting(false)
    }
}

enum MainTabLayout {
    static let barBodyHeight: CGFloat = 72
    static let contentClearance: CGFloat = 16
    static let scrollContentBottomInset = barBodyHeight + contentClearance
}

private struct TabBarContentPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        // safeAreaInset reserves the tab bar and device safe area; this margin keeps the last control clear of its edge.
        content.contentMargins(
            .bottom,
            MainTabLayout.scrollContentBottomInset,
            for: .scrollContent
        )
    }
}

extension View {
    func tabBarContentPadding() -> some View {
        modifier(TabBarContentPaddingModifier())
    }
}

enum MainTab: CaseIterable, Identifiable {
    case today
    case progress
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .today:
            LocalizedStrings.todayTab
        case .progress:
            LocalizedStrings.progressTab
        case .settings:
            LocalizedStrings.settingsTab
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "sun.max.fill"
        case .progress:
            "chart.bar.fill"
        case .settings:
            "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: MainTabLayout.barBodyHeight)
        .padding(.horizontal, 14)
        .background(Color.white)
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.black.opacity(0.04))
        }
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
    }

    private func tabButton(for tab: MainTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 24, weight: .semibold))

                Text(tab.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.primaryBlue : AppTheme.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: MainTabLayout.barBodyHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

struct MainTabView: View {
    @StateObject private var appState: AppState
    @State private var selectedTab: MainTab = .today
    @State private var isShowingCreateTask = false

    @MainActor
    init(initialTab: MainTab = .today) {
        _appState = StateObject(wrappedValue: AppState())
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            tabScreen(.today) {
                TodayView {
                    isShowingCreateTask = true
                }
            }

            tabScreen(.progress) {
                ProgressView()
            }

            tabScreen(.settings) {
                SettingsView()
            }
        }
        .environmentObject(appState)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $isShowingCreateTask) {
            CreateTaskView {
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedTab = .today
                }
                appState.taskDataDidChange()
            }
        }
    }

    private func tabScreen<Content: View>(
        _ tab: MainTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .zIndex(selectedTab == tab ? 1 : 0)
    }
}

#if DEBUG
#Preview {
    MainTabView()
        .modelContainer(PreviewData.previewContainer())
}

#Preview(
    "Главный экран: компактный",
    traits: .fixedLayout(width: 320, height: 568)
) {
    MainTabView()
        .modelContainer(PreviewData.previewContainer())
}

#Preview("Кастомный tab bar") {
    CustomTabBarPreview()
        .background(AppTheme.background)
}

#Preview("Snackbar: loading") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        SaveStatusSnackbar(
            status: .loading
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Snackbar: success") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        SaveStatusSnackbar(
            status: .success
        )
        .padding(.horizontal, 16)
    }
}

private struct CustomTabBarPreview: View {
    @State private var selectedTab: MainTab = .today

    var body: some View {
        CustomTabBar(selectedTab: $selectedTab)
    }
}
#endif
