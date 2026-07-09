import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let footnote: String?
    let minHeight: CGFloat

    init(
        title: String,
        value: String,
        systemImage: String,
        footnote: String? = nil,
        minHeight: CGFloat = 96
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.footnote = footnote
        self.minHeight = minHeight
    }

    var body: some View {
        FocusDayCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(AppTypography.progressRingValue)
                        .foregroundStyle(AppTheme.text)
                    Text(title)
                        .font(AppTypography.compact)
                        .foregroundStyle(AppTheme.mutedText)
                        .lineLimit(2)

                    if let footnote {
                        Text(footnote)
                            .font(AppTypography.tiny)
                            .foregroundStyle(Color(hex: "64748B"))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
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
