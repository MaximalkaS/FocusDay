import SwiftUI

struct FocusDayCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundStyle(AppTheme.text)
            .tint(AppTheme.primaryBlue)
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.softBlue.opacity(0.8), lineWidth: 1)
            }
    }
}

private struct AppTextEditorStyle: ViewModifier {
    let text: String
    let placeholder: String
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.fieldBackground)

            if text.isEmpty {
                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.placeholderText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 15)
                    .allowsHitTesting(false)
            }

            content
                .foregroundStyle(AppTheme.text)
                .tint(AppTheme.primaryBlue)
                .padding(8)
                .scrollContentBackground(.hidden)
        }
        .frame(minHeight: minHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.softBlue.opacity(0.8), lineWidth: 1)
        }
    }
}

extension View {
    func appTextEditorStyle(
        text: String,
        placeholder: String,
        minHeight: CGFloat
    ) -> some View {
        modifier(
            AppTextEditorStyle(
                text: text,
                placeholder: placeholder,
                minHeight: minHeight
            )
        )
    }

    func dismissKeyboardOnBackgroundTap(_ action: @escaping () -> Void) -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
        )
    }
}

#if DEBUG
#Preview {
    FocusDayCard {
        Text(LocalizedStrings.appName)
            .font(AppTypography.sectionTitle)
    }
    .padding()
    .background(AppTheme.background)
}

#Preview("Поля ввода") {
    VStack(spacing: 16) {
        TextField(
            "",
            text: .constant("Текст задачи"),
            prompt: Text(LocalizedStrings.taskTitlePlaceholder)
                .foregroundStyle(AppTheme.placeholderText)
        )
        .textFieldStyle(AppTextFieldStyle())

        TextField(
            "",
            text: .constant(""),
            prompt: Text(LocalizedStrings.taskTitlePlaceholder)
                .foregroundStyle(AppTheme.placeholderText)
        )
        .textFieldStyle(AppTextFieldStyle())

        TextEditor(text: .constant("Что получилось сегодня"))
            .appTextEditorStyle(
                text: "Что получилось сегодня",
                placeholder: LocalizedStrings.reflectionPlaceholder,
                minHeight: 110
            )

        TextEditor(text: .constant(""))
            .appTextEditorStyle(
                text: "",
                placeholder: LocalizedStrings.reflectionPlaceholder,
                minHeight: 110
            )
    }
    .padding()
    .background(AppTheme.background)
}
#endif
