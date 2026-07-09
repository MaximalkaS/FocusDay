import SwiftUI

struct ChoiceChip: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(AppTypography.choiceButtonText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : AppTheme.text)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(isSelected ? AppTheme.primaryBlue : Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AppTheme.primaryBlue : AppTheme.softBlue, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TwoColumnSelectionGrid<Item: Hashable, Content: View>: View {
    let items: [Item]
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    @ViewBuilder let content: (Item) -> Content

    init(
        items: [Item],
        horizontalSpacing: CGFloat = 10,
        verticalSpacing: CGFloat = 12,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    private var rows: [[Item]] {
        stride(from: 0, to: items.count, by: 2).map { index in
            Array(items[index..<min(index + 2, items.count)])
        }
    }

    var body: some View {
        VStack(spacing: verticalSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: horizontalSpacing) {
                    if row.count == 1 {
                        content(row[0])
                            .frame(maxWidth: .infinity)
                    } else {
                        content(row[0])
                            .frame(maxWidth: .infinity)

                        content(row[1])
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        HStack {
            ChoiceChip(title: LocalizedStrings.lowEnergy, isSelected: true) {}
            ChoiceChip(title: LocalizedStrings.highEnergy, isSelected: false) {}
        }

        TwoColumnSelectionGrid(items: [1, 2, 3]) { value in
            ChoiceChip(title: "\(value)", isSelected: value == 3) {}
        }
    }
    .padding()
    .background(AppTheme.background)
}
#endif
