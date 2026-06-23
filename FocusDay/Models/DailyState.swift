import Foundation
import SwiftData

@Model
final class DailyState: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var energyLevelRawValue: String
    var moodRawValue: String
    var mainTaskId: UUID?

    var energyLevel: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevelRawValue) ?? .medium }
        set { energyLevelRawValue = newValue.rawValue }
    }

    var mood: Mood {
        get { Mood(rawValue: moodRawValue) ?? .calm }
        set { moodRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        energyLevel: EnergyLevel = .medium,
        mood: Mood = .calm,
        mainTaskId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.energyLevelRawValue = energyLevel.rawValue
        self.moodRawValue = mood.rawValue
        self.mainTaskId = mainTaskId
    }
}
