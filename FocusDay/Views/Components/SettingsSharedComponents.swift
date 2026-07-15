import SwiftUI

struct SettingsSurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "94A3B8").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

struct SettingsNameField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField(
                "",
                text: $text,
                prompt: Text(LocalizedStrings.namePlaceholder)
                    .foregroundStyle(Color(hex: "8A96B3"))
            )
            .focused($isFocused)
            .textContentType(.name)
            .textInputAutocapitalization(.words)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppTheme.text)
            .tint(AppTheme.primaryBlue)

            if text.isEmpty == false {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.snackbarSuccessIcon)
                        .foregroundStyle(Color(hex: "98A2BD"))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStrings.delete)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: 58)
        .background(isFocused ? Color(hex: "F7FBFF") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isFocused ? AppTheme.primaryBlue.opacity(0.5) : Color(hex: "D8E3F2"),
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }
}

struct AppToggleSize {
    let width: CGFloat
    let height: CGFloat
    let thumbDiameter: CGFloat
    let inset: CGFloat

    static let standard = AppToggleSize(
        width: 54,
        height: 32,
        thumbDiameter: 28,
        inset: 2
    )
}

struct AppToggle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var isOn: Bool
    let accessibilityLabel: String
    let size: AppToggleSize

    init(
        isOn: Binding<Bool>,
        accessibilityLabel: String,
        size: AppToggleSize = .standard
    ) {
        _isOn = isOn
        self.accessibilityLabel = accessibilityLabel
        self.size = size
    }

    var body: some View {
        Button {
            toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AppTheme.primaryBlue : Color(hex: "E2E8F0"))
                    .frame(width: size.width, height: size.height)

                Circle()
                    .fill(Color.white)
                    .frame(width: size.thumbDiameter, height: size.thumbDiameter)
                    .shadow(color: Color(hex: "0F172A").opacity(0.16), radius: 3, x: 0, y: 1)
                    .padding(size.inset)
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? LocalizedStrings.toggleOn : LocalizedStrings.toggleOff)
        .accessibilityAddTraits(.isButton)
    }

    private func toggle() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.12)
            : Animation.spring(response: 0.25, dampingFraction: 0.85)

        withAnimation(animation) {
            isOn.toggle()
        }
    }
}


struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(AppTypography.tinyBold)

            Text(LocalizedStrings.premiumBadgeTitle)
                .font(AppTypography.compactSemibold)
        }
        .foregroundStyle(AppTheme.primaryBlue)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(AppTheme.background)
        .clipShape(Capsule())
    }
}

struct PremiumLockedFeatureMessage: View {
    let message: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(AppTypography.buttonText)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 22, height: 22)

            Text(message)
                .font(AppTypography.compactMedium)
                .foregroundStyle(Color(hex: "64748B"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F6F9FE"))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

struct SettingsGoalOptionCard: View {
    let goal: FocusGoal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: goal.settingsSystemImage)
                    .font(AppTypography.goalIcon)
                    .foregroundStyle(goal.settingsTint)
                    .frame(width: 52, height: 52)
                    .background(goal.settingsTint.opacity(0.12))
                    .clipShape(Circle())

                Text(goal.title)
                    .font(AppTypography.choiceButtonText)
                    .foregroundStyle(Color(hex: "0F172A"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 112)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.primaryBlue : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            }
            .overlay(alignment: .topTrailing) {
                selectedBadge
            }
            .shadow(color: Color(hex: "94A3B8").opacity(0.12), radius: 16, x: 0, y: 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var selectedBadge: some View {
        if isSelected {
            ZStack {
                Circle()
                    .fill(Color(hex: "007BFF"))

                Image(systemName: "checkmark")
                    .font(AppTypography.sectionTitleBold)
                    .foregroundStyle(Color.white)
            }
            .frame(width: 34, height: 34)
            .offset(x: 8, y: -8)
            .zIndex(10)
        }
    }
}

struct SettingsReminderTimeRow: View {
    let systemImage: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: Date
    let onSelectTime: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(AppTypography.notificationIcon)
                .foregroundStyle(iconColor)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.sectionTitleSemibold)
                    .foregroundStyle(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(AppTypography.compactMedium)
                    .foregroundStyle(Color(hex: "64748B"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 8)

            Button(action: onSelectTime) {
                Text(time.settingsFormattedReminderTime)
                    .font(AppTypography.buttonText)
                    .foregroundStyle(AppTheme.text)
                    .monospacedDigit()
                    .frame(width: 92, height: 46)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(time.settingsFormattedReminderTime)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

enum SettingsReminderPicker: String, Identifiable {
    case morning
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning:
            LocalizedStrings.morningReminderTitle
        case .evening:
            LocalizedStrings.eveningReminderTitle
        }
    }
}

struct SettingsReminderTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(title)
                    .font(AppTypography.progressCardValue)
                    .foregroundStyle(Color(hex: "0F172A"))

                Spacer()

                Button(LocalizedStrings.done) {
                    dismiss()
                }
                .font(AppTypography.buttonText)
                .foregroundStyle(AppTheme.primaryBlue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(AppTheme.primaryBlue)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

extension Date {
    var settingsFormattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizedStrings.dateLocale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

extension FocusGoal {
    var settingsSystemImage: String {
        switch self {
        case .study:
            "graduationcap"
        case .sport:
            "dumbbell"
        case .work:
            "briefcase"
        case .habits:
            "target"
        case .personal:
            "person"
        }
    }

    var settingsTint: Color {
        switch self {
        case .study:
            AppTheme.primaryBlue
        case .sport:
            Color(hex: "22C55E")
        case .work:
            Color(hex: "7C3AED")
        case .habits:
            Color(hex: "FF9F0A")
        case .personal:
            Color(hex: "14B8C4")
        }
    }
}

#if DEBUG
#Preview("Settings components: goal") {
    VStack(spacing: 16) {
        SettingsGoalOptionCard(goal: .study, isSelected: true) {}
        SettingsGoalOptionCard(goal: .sport, isSelected: false) {}
    }
    .padding(24)
    .frame(width: 320)
    .background(AppTheme.screenBackground)
}

#Preview("Settings components: reminder row") {
    SettingsSurfaceCard {
        SettingsReminderTimeRow(
            systemImage: "sun.max.fill",
            iconColor: AppTheme.primaryBlue,
            title: LocalizedStrings.morningReminderTitle,
            subtitle: LocalizedStrings.morningReminderSubtitle,
            time: Date()
        ) {}
    }
    .padding(16)
    .background(AppTheme.screenBackground)
}
#endif
