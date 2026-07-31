import Foundation

public enum SKALAMenuClientError: LocalizedError {
    case invalidResponse
    case noMenuForToday
    case server(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "식단표 응답을 읽지 못했습니다."
        case .noMenuForToday:
            return "오늘 등록된 메뉴가 없습니다."
        case .server(let statusCode):
            return "식단표 서버가 응답하지 않습니다. (HTTP \(statusCode))"
        }
    }
}

public struct SKALAMenuClient: Sendable {
    public static let endpointURL = URL(string: "https://skala-lunch.ewkimhyunsu11.workers.dev/api/menus/current")!

    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 15
        session = URLSession(configuration: configuration)
    }

    public init(session: URLSession) {
        self.session = session
    }

    public func fetchToday(now: Date = Date()) async throws -> DailyMenu {
        let menus = try await fetchWeek(now: now)
        let dateKey = MenuCalendar.dateKey(for: now)
        guard let today = menus.first(where: { MenuCalendar.dateKey(for: $0.date) == dateKey }) else {
            throw SKALAMenuClientError.noMenuForToday
        }
        return today
    }

    public func fetchWeek(now: Date = Date()) async throws -> [DailyMenu] {
        var request = URLRequest(url: Self.endpointURL)
        request.cachePolicy = .reloadRevalidatingCacheData
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SKALAMenuClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SKALAMenuClientError.server(statusCode: httpResponse.statusCode)
        }

        return try decodeWeek(data, now: now)
    }

    func decodeWeek(_ data: Data, now: Date = Date()) throws -> [DailyMenu] {
        let weeklyMenu: WeeklyMenuResponse
        do {
            weeklyMenu = try JSONDecoder().decode(WeeklyMenuResponse.self, from: data)
        } catch {
            throw SKALAMenuClientError.invalidResponse
        }

        return weeklyMenu.days.compactMap { day in
            guard let date = MenuCalendar.date(from: day.date) else { return nil }

            let lunch = format(dishes: day.lunch?.dishes ?? [])
            var dinner = format(dishes: day.dinner?.dishes ?? [])
            if let dessert = day.dessert?.trimmingCharacters(in: .whitespacesAndNewlines),
               !dessert.isEmpty {
                dinner = [dinner, "후식: \(dessert)"]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
            }

            return DailyMenu(
                date: date,
                lunch: lunch.isEmpty ? nil : lunch,
                dinner: dinner.isEmpty ? nil : dinner,
                fetchedAt: now
            )
        }
    }

    private func format(dishes: [Dish]) -> String {
        dishes
            .map { dish in
                dish.name
                    .replacingOccurrences(of: "*", with: " · ")
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .joined(separator: "  ·  ")
    }

}

private struct WeeklyMenuResponse: Decodable {
    let days: [MenuDay]
}

private struct MenuDay: Decodable {
    let date: String
    let lunch: Meal?
    let dinner: Meal?
    let dessert: String?
}

private struct Meal: Decodable {
    let dishes: [Dish]
}

private struct Dish: Decodable {
    let name: String
}
