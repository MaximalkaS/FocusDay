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
    @Published private(set) var streakCelebration: StreakCelebration?

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

    func presentStreakCelebration(_ streakCelebration: StreakCelebration) {
        self.streakCelebration = streakCelebration
    }

    func dismissStreakCelebration() {
        streakCelebration = nil
    }
}

struct SaveStatusSnackbar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let status: SaveStatus
    var successText: String = LocalizedStrings.changesSaved

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
        .animation(AppMotion.quick(reduceMotion), value: status == .hidden)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: some View {
        ZStack {
            SwiftUI.ProgressView()
                .controlSize(.small)
                .tint(AppTheme.primaryBlue)
                .opacity(status == .loading ? 1 : 0)
                .scaleEffect(status == .loading || reduceMotion ? 1 : 0.82)

            Image(systemName: "checkmark.circle.fill")
                .font(AppTypography.snackbarSuccessIcon)
                .foregroundStyle(AppTheme.success)
                .opacity(status == .success ? 1 : 0)
                .scaleEffect(status == .success || reduceMotion ? 1 : 0.82)
        }
        .frame(width: 28, height: 28)
        .animation(AppMotion.quick(reduceMotion), value: status)
    }

    private var statusText: some View {
        ZStack(alignment: .leading) {
            Text(LocalizedStrings.savingProgress)
                .opacity(status == .loading ? 1 : 0)
                .scaleEffect(status == .loading || reduceMotion ? 1 : 0.98, anchor: .leading)

            Text(successText)
                .opacity(status == .success ? 1 : 0)
                .scaleEffect(status == .success || reduceMotion ? 1 : 0.98, anchor: .leading)
        }
        .font(AppTypography.sectionTitleSemibold)
        .foregroundStyle(AppTheme.text)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(AppMotion.quick(reduceMotion), value: status)
    }
}

struct SaveFeedbackOverlay: View {
    let status: SaveStatus
    var successText: String = LocalizedStrings.changesSaved

    var body: some View {
        SaveStatusSnackbar(status: status, successText: successText)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .top)
            .allowsHitTesting(false)
    }
}

struct StreakCelebrationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBackgroundVisible = false
    @State private var isCardVisible = false
    @State private var isDismissing = false
    @State private var isIconVisible = false
    @State private var isTitleVisible = false
    @State private var isCountVisible = false
    @State private var isSubtitleVisible = false
    @State private var isButtonVisible = false

    let dayCount: Int
    let previewReduceMotion: Bool?
    let onContinue: () -> Void

    init(
        dayCount: Int,
        previewReduceMotion: Bool? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.dayCount = dayCount
        self.previewReduceMotion = previewReduceMotion
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(isBackgroundVisible ? 0.25 : 0)
                .ignoresSafeArea()

            card
                .padding(.horizontal, 28)
                .opacity(isCardVisible ? 1 : 0)
                .scaleEffect(cardScale)
                .offset(y: cardOffset)
        }
        .zIndex(100)
        .allowsHitTesting(true)
        .onAppear {
            runAppearAnimation()
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            stagedElement(isIconVisible) {
                Image(systemName: "flame.fill")
                    .font(AppTypography.streakIcon)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.primaryBlue.opacity(0.12))
                    .clipShape(Circle())
            }

            VStack(spacing: 6) {
                stagedElement(isTitleVisible) {
                    Text(celebrationTitle)
                        .font(AppTypography.progressCardValue)
                        .foregroundStyle(AppTheme.text)
                        .multilineTextAlignment(.center)
                }

                stagedElement(isCountVisible) {
                    Text(LocalizedStrings.streakDaysInRow(dayCount))
                        .font(AppTypography.streakCount)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.center)
                }

                stagedElement(isSubtitleVisible) {
                    Text(LocalizedStrings.streakCelebrationSubtitle)
                        .font(AppTypography.screenSubtitle)
                        .foregroundStyle(Color(hex: "64748B"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            stagedElement(isButtonVisible) {
                Button {
                    dismiss()
                } label: {
                    Text(LocalizedStrings.continueTitle)
                        .font(AppTypography.primaryButton)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .frame(maxWidth: 320)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
    }

    private var cardScale: CGFloat {
        guard usesReducedMotion == false else { return 1 }
        if isCardVisible { return 1 }
        return isDismissing ? 0.98 : 0.96
    }

    private var cardOffset: CGFloat {
        guard usesReducedMotion == false else { return 0 }
        if isCardVisible { return 0 }
        return isDismissing ? 8 : 14
    }

    private var usesReducedMotion: Bool {
        previewReduceMotion ?? reduceMotion
    }

    private var celebrationTitle: String {
        dayCount == 1 ? LocalizedStrings.streakCelebrationStartTitle : LocalizedStrings.streakCelebrationTitle
    }

    private func stagedElement<Content: View>(
        _ isElementVisible: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(isElementVisible ? 1 : 0)
            .offset(y: usesReducedMotion || isElementVisible ? 0 : 6)
    }

    private func runAppearAnimation() {
        isDismissing = false

        withAnimation(.easeOut(duration: 0.18)) {
            isBackgroundVisible = true
        }

        withAnimation(.easeOut(duration: usesReducedMotion ? 0.18 : 0.34)) {
            isCardVisible = true
        }

        reveal(after: 0.05) { isIconVisible = true }
        reveal(after: 0.10) { isTitleVisible = true }
        reveal(after: 0.14) { isCountVisible = true }
        reveal(after: 0.17) { isSubtitleVisible = true }
        reveal(after: 0.20) { isButtonVisible = true }
    }

    private func reveal(after delay: Double, action: @escaping @MainActor () -> Void) {
        let animationDelay = usesReducedMotion ? 0 : delay
        withAnimation(.easeOut(duration: 0.22).delay(animationDelay)) {
            action()
        }
    }

    private func dismiss() {
        let dismissalDelay: UInt64 = usesReducedMotion ? 180_000_000 : 260_000_000

        withAnimation(.easeInOut(duration: usesReducedMotion ? 0.18 : 0.26)) {
            isDismissing = true
            isBackgroundVisible = false
            isCardVisible = false
            isIconVisible = false
            isTitleVisible = false
            isCountVisible = false
            isSubtitleVisible = false
            isButtonVisible = false
        }

        Task {
            do {
                try await Task.sleep(nanoseconds: dismissalDelay)
            } catch {
                return
            }

            await MainActor.run {
                onContinue()
            }
        }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            withAnimation(AppMotion.quick(reduceMotion)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(AppTypography.plusIcon)
                    .offset(y: selectedTab == tab && reduceMotion == false ? -2 : 0)

                Text(tab.title)
                    .font(AppTypography.tabLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.primaryBlue : AppTheme.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: MainTabLayout.barBodyHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AppMotion.quick(reduceMotion), value: selectedTab)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            selectedTabContent
                .transition(.opacity)
        }
        .animation(AppMotion.quick(reduceMotion), value: selectedTab)
        .environmentObject(appState)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .overlay {
            if let streakCelebration = appState.streakCelebration {
                StreakCelebrationOverlay(dayCount: streakCelebration.dayCount) {
                    withAnimation(AppMotion.quick(reduceMotion)) {
                        appState.dismissStreakCelebration()
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isShowingCreateTask) {
            CreateTaskView {
                withAnimation(AppMotion.quick(reduceMotion)) {
                    selectedTab = .today
                }
                appState.taskDataDidChange()
            }
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .today:
            TodayView {
                isShowingCreateTask = true
            }
        case .progress:
            ProgressView(isActive: true)
        case .settings:
            SettingsView()
        }
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

#Preview("Серия продлена: 4 дня") {
    StreakCelebrationOverlay(dayCount: 4) {}
}

#Preview("Серия началась: 1 день") {
    StreakCelebrationOverlay(dayCount: 1) {}
}

#Preview("Серия: первый день без overlay") {
    ZStack {
        AppTheme.screenBackground.ignoresSafeArea()

        Text(LocalizedStrings.streakDaysInRow(1))
            .font(AppTypography.progressCardValue)
            .foregroundStyle(AppTheme.text)
    }
}

#Preview("Серия продлена: Reduce Motion") {
    StreakCelebrationOverlay(dayCount: 4, previewReduceMotion: true) {}
}

private struct CustomTabBarPreview: View {
    @State private var selectedTab: MainTab = .today

    var body: some View {
        CustomTabBar(selectedTab: $selectedTab)
    }
}
#endif
