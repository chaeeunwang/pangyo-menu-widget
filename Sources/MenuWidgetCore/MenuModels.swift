import Foundation

public struct DailyMenu: Codable, Equatable, Sendable {
    public let date: Date
    public let lunch: String?
    public let dinner: String?
    public let fetchedAt: Date

    public init(
        date: Date,
        lunch: String?,
        dinner: String?,
        fetchedAt: Date
    ) {
        self.date = date
        self.lunch = lunch
        self.dinner = dinner
        self.fetchedAt = fetchedAt
    }
}
