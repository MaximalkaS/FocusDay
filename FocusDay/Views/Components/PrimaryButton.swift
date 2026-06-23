import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } icon: {
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(isDisabled ? AppTheme.mutedText : AppTheme.primaryBlue)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .disabled(isDisabled)
    }
}

#if DEBUG
#Preview {
    PrimaryButton(LocalizedStrings.save, systemImage: "checkmark") {}
        .padding()
}
#endif
