import Foundation
import WidgetKit

enum WidgetSelectionStore {
    static let widgetKind = "com.chaeeun.pangyo-menu-widget.today"
    static let sharedPreferencesIdentifier = "com.chaeeun.pangyo-menu-widget.selection"
    static let selectedDateKey = "selected-menu-date"
    static let availableDatesKey = "available-menu-dates"
    static let lastTodayKey = "last-menu-today"

    static let preferences: UserDefaults = {
        guard let shared = UserDefaults(suiteName: sharedPreferencesIdentifier) else {
            return .standard
        }

        for key in [selectedDateKey, availableDatesKey, lastTodayKey]
        where shared.object(forKey: key) == nil {
            if let value = UserDefaults.standard.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }
        shared.synchronize()
        return shared
    }()

    static func move(by offset: Int) {
        let dates = preferences.stringArray(forKey: availableDatesKey) ?? []
        guard !dates.isEmpty else { return }

        let selected = preferences.string(forKey: selectedDateKey)
        let currentIndex = selected.flatMap { dates.firstIndex(of: $0) } ?? dates.count - 1
        let nextIndex = min(max(0, currentIndex + offset), dates.count - 1)
        preferences.set(dates[nextIndex], forKey: selectedDateKey)
        preferences.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
