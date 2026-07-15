import SwiftUI
import UIKit

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

struct SelectionTile: View {
    let title: String
    let systemImage: String?
    let color: Color
    var unselectedColor: Color?
    let isSelected: Bool
    var selectedColor: Color = AppTheme.primaryBlue
    var unselectedBorderColor: Color = Color(hex: "D8E3F2")
    var selectedBorderColor: Color?
    var selectedBackgroundColor: Color?
    var selectedBackgroundOpacity: Double = 0.08
    let action: () -> Void

    private var currentColor: Color {
        isSelected ? selectedColor : (unselectedColor ?? color)
    }

    private var selectedFillColor: Color {
        selectedBackgroundColor ?? selectedColor.opacity(selectedBackgroundOpacity)
    }

    private var selectedStrokeColor: Color {
        selectedBorderColor ?? selectedColor
    }

    init(
        title: String,
        systemImage: String? = nil,
        color: Color,
        unselectedColor: Color? = nil,
        isSelected: Bool,
        selectedColor: Color = AppTheme.primaryBlue,
        unselectedBorderColor: Color = Color(hex: "D8E3F2"),
        selectedBorderColor: Color? = nil,
        selectedBackgroundColor: Color? = nil,
        selectedBackgroundOpacity: Double = 0.08,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.unselectedColor = unselectedColor
        self.isSelected = isSelected
        self.selectedColor = selectedColor
        self.unselectedBorderColor = unselectedBorderColor
        self.selectedBorderColor = selectedBorderColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.selectedBackgroundOpacity = selectedBackgroundOpacity
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(currentColor)
                        .frame(width: 24, height: 24)
                }

                Text(title)
                    .font(AppTypography.choiceButtonText)
                    .foregroundStyle(currentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 8)
            .background(isSelected ? selectedFillColor : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? selectedStrokeColor : unselectedBorderColor, lineWidth: isSelected ? 1.6 : 1.2)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}


struct KeyboardAwareTextEditor<Field: Hashable>: View {
    @Binding var text: String
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let placeholder: String
    var font: Font = AppTypography.bodyMedium
    var placeholderColor: Color = AppTheme.placeholderText
    var textColor: Color = AppTheme.text
    var tintColor: Color = AppTheme.primaryBlue
    var horizontalTextPadding: CGFloat = 12
    var verticalTextPadding: CGFloat = 12
    var placeholderHorizontalPadding: CGFloat = 18
    var placeholderVerticalPadding: CGFloat = 17
    var minHeight: CGFloat = 120
    var backgroundColor: Color = Color.white
    var cornerRadius: CGFloat = 12
    var borderColor: Color = Color(hex: "BBD6FF")
    var borderWidth: CGFloat = 1.2

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused(focusedField, equals: field)
                .font(font)
                .foregroundStyle(textColor)
                .tint(tintColor)
                .padding(.horizontal, horizontalTextPadding)
                .padding(.vertical, verticalTextPadding)
                .scrollContentBackground(.hidden)

            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(placeholderColor)
                    .padding(.horizontal, placeholderHorizontalPadding)
                    .padding(.vertical, placeholderVerticalPadding)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

private struct KeyboardAwareTextEditorScrollModifier<Field: Equatable, TargetID: Hashable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let focusedField: Field?
    let targetField: Field
    let text: String
    let targetId: TargetID
    let proxy: ScrollViewProxy
    let bottomSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: bottomSpacing)
                    .allowsHitTesting(false)
            }
            .onChange(of: focusedField) { _, newValue in
                guard newValue == targetField else { return }
                scrollToEditor(animated: true)
            }
            .onChange(of: text) { _, _ in
                guard focusedField == targetField else { return }
                scrollToEditor(animated: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                guard focusedField == targetField else { return }
                scrollToEditor(animated: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in
                guard focusedField == targetField else { return }
                scrollToEditor(animated: true)
            }
    }

    private func scrollToEditor(animated: Bool) {
        Task { @MainActor in
            await Task.yield()

            if animated, let animation = AppMotion.smooth(reduceMotion) {
                withAnimation(animation) {
                    proxy.scrollTo(targetId, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(targetId, anchor: .bottom)
            }
        }
    }
}

extension View {
    func keyboardAwareTextEditorScroll<Field: Equatable, TargetID: Hashable>(
        focusedField: Field?,
        targetField: Field,
        text: String,
        targetId: TargetID,
        proxy: ScrollViewProxy,
        bottomSpacing: CGFloat = 16
    ) -> some View {
        modifier(
            KeyboardAwareTextEditorScrollModifier(
                focusedField: focusedField,
                targetField: targetField,
                text: text,
                targetId: targetId,
                proxy: proxy,
                bottomSpacing: bottomSpacing
            )
        )
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
