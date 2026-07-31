import Foundation
import XCTest
@testable import MenuWidgetCore

final class SKALAMenuClientTests: XCTestCase {
    func testDecodesAndFormatsWeeklyMenu() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_785_456_000)
        let menus = try SKALAMenuClient().decodeWeek(Self.fixture, now: fetchedAt)

        XCTAssertEqual(menus.count, 2)
        XCTAssertEqual(MenuCalendar.dateKey(for: menus[0].date), "2026-07-30")
        XCTAssertEqual(menus[0].lunch, "삼색수제비국  ·  너비아니 · 파채  ·  쌀밥")
        XCTAssertEqual(menus[0].dinner, "버섯만두전골  ·  고기완자조림\n후식: 옥수수차")
        XCTAssertEqual(menus[0].fetchedAt, fetchedAt)
        XCTAssertNil(menus[1].lunch)
        XCTAssertEqual(menus[1].dinner, "돈코츠라멘 · 시치미")
    }

    func testRejectsInvalidJSON() {
        XCTAssertThrowsError(try SKALAMenuClient().decodeWeek(Data("{}".utf8))) { error in
            guard case SKALAMenuClientError.invalidResponse = error else {
                return XCTFail("예상하지 못한 오류: \(error)")
            }
        }
    }

    func testDateKeyUsesSeoulTimezone() {
        let utcDate = Date(timeIntervalSince1970: 1_785_456_000)
        XCTAssertEqual(MenuCalendar.dateKey(for: utcDate), "2026-07-31")
    }

    func testDailyMenusRoundTripThroughCacheEncoding() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_785_456_000)
        let menus = try SKALAMenuClient().decodeWeek(Self.fixture, now: fetchedAt)

        let data = try JSONEncoder().encode(menus)
        let decodedMenus = try JSONDecoder().decode([DailyMenu].self, from: data)

        XCTAssertEqual(decodedMenus, menus)
    }

    private static let fixture = Data(
        """
        {
          "weekStart": "2026-07-27",
          "weekEnd": "2026-07-31",
          "days": [
            {
              "date": "2026-07-30",
              "weekday": "목",
              "lunch": { "dishes": [
                { "name": "삼색수제비국", "isMain": true },
                { "name": "너비아니*파채", "isMain": true },
                { "name": "쌀밥", "isMain": false }
              ] },
              "dinner": { "dishes": [
                { "name": "버섯만두전골", "isMain": true },
                { "name": "고기완자조림", "isMain": true }
              ] },
              "dessert": "옥수수차"
            },
            {
              "date": "2026-07-31",
              "weekday": "금",
              "lunch": null,
              "dinner": { "dishes": [
                { "name": "돈코츠라멘*시치미", "isMain": true }
              ] },
              "dessert": ""
            }
          ],
          "notes": []
        }
        """.utf8
    )
}
