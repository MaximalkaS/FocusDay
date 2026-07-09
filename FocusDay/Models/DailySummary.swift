import Foundation
import SwiftData

enum DayFeeling: String, CaseIterable, Identifiable {
    case excellent
    case calm
    case hard
    case overloaded

    var id: String { rawValue }

    var needsInfluenceReasons: Bool {
        self == .hard || self == .overloaded
    }
}

enum DayInfluenceReason: String, CaseIterable, Identifiable {
    case notEnoughTime
    case lowEnergy
    case distracted
    case tooManyTasks

    var id: String { rawValue }
}

@Model
final class DailySummary: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var completedTasksCount: Int
    var totalTasksCount: Int
    var reflectionText: String
    var dayFeelingRawValue: String?
    var influenceReasonRawValues: String?
    var finishedAt: Date?

    var isDayFinished: Bool {
        finishedAt != nil
    }

    var dayFeeling: DayFeeling {
        get { dayFeelingRawValue.flatMap(DayFeeling.init(rawValue:)) ?? .calm }
        set { dayFeelingRawValue = newValue.rawValue }
    }

    var influenceReasons: [DayInfluenceReason] {
        get {
            guard let influenceReasonRawValues, influenceReasonRawValues.isEmpty == false else {
                return []
            }

            return influenceReasonRawValues
                .split(separator: "|")
                .compactMap { DayInfluenceReason(rawValue: String($0)) }
        }
        set {
            influenceReasonRawValues = newValue.map(\.rawValue).joined(separator: "|")
        }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0,
        reflectionText: String = "",
        dayFeeling: DayFeeling = .calm,
        influenceReasons: [DayInfluenceReason] = [],
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
        self.reflectionText = reflectionText
        self.dayFeelingRawValue = dayFeeling.rawValue
        self.influenceReasonRawValues = influenceReasons.map(\.rawValue).joined(separator: "|")
        self.finishedAt = finishedAt
    }
}
