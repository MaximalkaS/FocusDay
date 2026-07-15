import SwiftUI

struct ContentView: View {
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
    }
}

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(PreviewData.previewContainer())
}
#endif
