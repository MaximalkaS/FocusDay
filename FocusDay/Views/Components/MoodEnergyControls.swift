import SwiftUI
import UIKit

struct MoodSelectionCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let selectedMood: Mood
    let onSelect: (Mood) -> Void

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.moodTitle)

            ExplanationText(LocalizedStrings.moodExplanation)

            TwoColumnSelectionGrid(
                items: Mood.allCases,
                horizontalSpacing: 10,
                verticalSpacing: 10
            ) { mood in
                    Button {
                        selectMood(mood)
                    } label: {
                        let isSelected = selectedMood == mood

                        HStack(spacing: 10) {
                            Image(systemName: mood.symbolName)
                                .font(AppTypography.sectionTitleSemibold)
                                .frame(width: 26)

                            Text(mood.title)
                                .font(AppTypography.choiceButtonText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(mood.tint)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.horizontal, 10)
                        .background(mood.tint.opacity(isSelected ? 0.16 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    isSelected ? mood.tint.opacity(0.55) : mood.tint.opacity(0.12),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        }
                        .scaleEffect(isSelected && reduceMotion == false ? 1.03 : 1)
                        .contentShape(Rectangle())
                        .animation(AppMotion.quick(reduceMotion), value: selectedMood)
                    }
                    .buttonStyle(.plain)
            }
        }
    }

    private func selectMood(_ mood: Mood) {
        guard selectedMood != mood else { return }
        if reduceMotion == false {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        withAnimation(AppMotion.quick(reduceMotion)) {
            onSelect(mood)
        }
    }
}

struct EnergySelectionCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let selectedEnergyLevel: EnergyLevel
    let onSelect: (EnergyLevel) -> Void

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.energyTitle)

            ExplanationText(LocalizedStrings.energyExplanation)

            TwoColumnSelectionGrid(
                items: EnergyLevel.allCases,
                horizontalSpacing: 8,
                verticalSpacing: 8
            ) { energyLevel in
                energyButton(for: energyLevel)
            }
        }
    }

    private func energyButton(for energyLevel: EnergyLevel) -> some View {
        let isSelected = selectedEnergyLevel == energyLevel

        return Button {
            selectEnergy(energyLevel)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: energyLevel.symbolName)
                    .font(AppTypography.sectionTitle)
                    .frame(width: 22)

                Text(energyLevel.title)
                    .font(AppTypography.choiceButtonText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? AppTheme.primaryBlue : Color(hex: "64748B"))
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
            .background(isSelected ? AppTheme.primaryBlue.opacity(0.09) : AppTheme.screenBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.primaryBlue.opacity(0.55) : Color.clear,
                        lineWidth: 1.5
                    )
            }
            .scaleEffect(isSelected && reduceMotion == false ? 1.03 : 1)
            .contentShape(Rectangle())
            .animation(AppMotion.quick(reduceMotion), value: selectedEnergyLevel)
        }
        .buttonStyle(.plain)
    }

    private func selectEnergy(_ energyLevel: EnergyLevel) {
        guard selectedEnergyLevel != energyLevel else { return }
        if reduceMotion == false {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        withAnimation(AppMotion.quick(reduceMotion)) {
            onSelect(energyLevel)
        }
    }
}

private extension Mood {
    var tint: Color {
        switch self {
        case .calm:
            AppTheme.success
        case .tired:
            AppTheme.purple
        case .motivated:
            AppTheme.primaryBlue
        case .anxious:
            AppTheme.orange
        }
    }
}

private extension EnergyLevel {
    var symbolName: String {
        switch self {
        case .low:
            "battery.25"
        case .medium:
            "battery.50"
        case .high:
            "bolt.fill"
        }
    }
}

private struct ExplanationText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppTypography.compact)
            .foregroundStyle(Color(hex: "64748B"))
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}

#if DEBUG
#Preview {
    VStack {
        MoodSelectionCard(selectedMood: .calm) { _ in }
        EnergySelectionCard(selectedEnergyLevel: .medium) { _ in }
    }
    .padding()
    .background(AppTheme.screenBackground)
}

#Preview(
    "Energy: iPhone SE Dynamic Type",
    traits: .fixedLayout(width: 320, height: 320)
) {
    EnergySelectionCard(selectedEnergyLevel: .medium) { _ in }
        .padding()
        .environment(\.dynamicTypeSize, .accessibility2)
        .background(AppTheme.screenBackground)
}
#endif
