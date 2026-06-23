import SwiftUI

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .tint(AppTheme.primaryBlue)
        .preferredColorScheme(.light)
    }
}

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(PreviewData.previewContainer())
}
#endif
