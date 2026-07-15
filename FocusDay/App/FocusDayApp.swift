import SwiftData
import SwiftUI

@main
struct FocusDayApp: App {
    private let modelContainer: ModelContainer?

    init() {
        modelContainer = Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
            } else {
                StorageUnavailableView()
            }
        }
    }

    private static func makeModelContainer() -> ModelContainer? {
        do {
            return try FocusDayModelContainerFactory.makeModelContainer()
        } catch {
            return try? FocusDayModelContainerFactory.makeInMemoryModelContainer()
        }
    }
}

private struct StorageUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(AppTypography.storageWarningIcon)
                .foregroundStyle(AppTheme.primaryBlue)

            Text(LocalizedStrings.storageUnavailableTitle)
                .font(AppTypography.progressCardValue)
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStrings.storageUnavailableMessage)
                .font(AppTypography.screenSubtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
