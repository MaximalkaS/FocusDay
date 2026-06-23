import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        FocusDayCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    MetricCard(title: LocalizedStrings.completedTasks, value: "7", systemImage: "checkmark.circle")
        .padding()
        .background(AppTheme.background)
}
#endif
