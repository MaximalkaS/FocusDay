import SwiftUI

struct MoodSelectionCard: View {
    let selectedMood: Mood
    let onSelect: (Mood) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.moodTitle)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        onSelect(mood)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: mood.symbolName)
                                .font(.title3.weight(.semibold))
                                .frame(width: 26)

                            Text(mood.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(mood.tint)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.horizontal, 10)
                        .background(mood.tint.opacity(selectedMood == mood ? 0.16 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    selectedMood == mood ? mood.tint.opacity(0.55) : mood.tint.opacity(0.12),
                                    lineWidth: selectedMood == mood ? 1.5 : 1
                                )
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct EnergySelectionCard: View {
    let selectedEnergyLevel: EnergyLevel
    let onSelect: (EnergyLevel) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var body: some View {
        FocusDayCard {
            SectionHeader(title: LocalizedStrings.energyTitle)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(EnergyLevel.allCases) { energyLevel in
                    Button {
                        onSelect(energyLevel)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: energyLevel.symbolName)
                                .font(.headline)

                            Text(energyLevel.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.68)
                        }
                        .foregroundStyle(
                            selectedEnergyLevel == energyLevel
                                ? AppTheme.primaryBlue
                                : AppTheme.mutedText
                        )
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.horizontal, 5)
                        .background(
                            selectedEnergyLevel == energyLevel
                                ? AppTheme.primaryBlue.opacity(0.09)
                                : AppTheme.screenBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    selectedEnergyLevel == energyLevel
                                        ? AppTheme.primaryBlue.opacity(0.55)
                                        : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
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

#if DEBUG
#Preview {
    VStack {
        MoodSelectionCard(selectedMood: .calm) { _ in }
        EnergySelectionCard(selectedEnergyLevel: .medium) { _ in }
    }
    .padding()
    .background(AppTheme.screenBackground)
}
#endif
