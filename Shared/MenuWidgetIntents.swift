import AppIntents
import Foundation
import WidgetKit

enum WidgetSelectionStore {
    static let widgetKind = "com.chaeeun.pangyo-menu-widget.today"
    static let selectedDateKey = "selected-menu-date"
    static let availableDatesKey = "available-menu-dates"
    static let lastTodayKey = "last-menu-today"

    static func move(by offset: Int) {
        let dates = UserDefaults.standard.stringArray(forKey: availableDatesKey) ?? []
        guard !dates.isEmpty else { return }

        let selected = UserDefaults.standard.string(forKey: selectedDateKey)
        let currentIndex = selected.flatMap { dates.firstIndex(of: $0) } ?? dates.count - 1
        let nextIndex = min(max(0, currentIndex + offset), dates.count - 1)
        UserDefaults.standard.set(dates[nextIndex], forKey: selectedDateKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

struct PreviousMenuDayIntent: AppIntent {
    static let title: LocalizedStringResource = "이전 날짜"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        WidgetSelectionStore.move(by: -1)
        return .result()
    }
}

struct NextMenuDayIntent: AppIntent {
    static let title: LocalizedStringResource = "다음 날짜"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        WidgetSelectionStore.move(by: 1)
        return .result()
    }
}
