import AppIntents
import SwiftUI
import WidgetKit

private enum WidgetSelectionStore {
    private static let selectedDateKey = "selected-menu-date"
    private static let availableDatesKey = "available-menu-dates"
    private static let lastTodayKey = "last-menu-today"

    static func selectedIndex(in menus: [DailyMenu], today: Date = Date()) -> Int {
        guard !menus.isEmpty else { return 0 }

        let dates = menus.map { dateKey($0.date) }
        UserDefaults.standard.set(dates, forKey: availableDatesKey)

        let todayKey = dateKey(today)
        if UserDefaults.standard.string(forKey: lastTodayKey) != todayKey {
            let index = dates.firstIndex(of: todayKey) ?? max(0, dates.count - 1)
            UserDefaults.standard.set(todayKey, forKey: lastTodayKey)
            UserDefaults.standard.set(dates[index], forKey: selectedDateKey)
            return index
        }

        if let selectedDate = UserDefaults.standard.string(forKey: selectedDateKey),
           let index = dates.firstIndex(of: selectedDate) {
            return index
        }

        let index = dates.firstIndex(of: todayKey) ?? max(0, dates.count - 1)
        UserDefaults.standard.set(dates[index], forKey: selectedDateKey)
        return index
    }

    static func move(by offset: Int) {
        let dates = UserDefaults.standard.stringArray(forKey: availableDatesKey) ?? []
        guard !dates.isEmpty else { return }

        let selected = UserDefaults.standard.string(forKey: selectedDateKey)
        let currentIndex = selected.flatMap { dates.firstIndex(of: $0) } ?? dates.count - 1
        let nextIndex = min(max(0, currentIndex + offset), dates.count - 1)
        UserDefaults.standard.set(dates[nextIndex], forKey: selectedDateKey)
        WidgetCenter.shared.reloadTimelines(ofKind: PangyoMenuWidget.kind)
    }

    private static func dateKey(_ date: Date) -> String {
        MenuCalendar.dateKey(for: date)
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

struct MenuWidgetEntry: TimelineEntry {
    let date: Date
    let menus: [DailyMenu]
    let selectedIndex: Int
    let errorMessage: String?

    var selectedMenu: DailyMenu? {
        guard menus.indices.contains(selectedIndex) else { return nil }
        return menus[selectedIndex]
    }
}

struct MenuWidgetProvider: TimelineProvider {
    private let client = SKALAMenuClient()

    func placeholder(in context: Context) -> MenuWidgetEntry {
        sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (MenuWidgetEntry) -> Void) {
        if context.isPreview {
            completion(sampleEntry)
            return
        }
        loadEntry(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MenuWidgetEntry>) -> Void) {
        loadEntry { entry in
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
                ?? Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    private func loadEntry(completion: @escaping (MenuWidgetEntry) -> Void) {
        Task {
            do {
                let menus = try await client.fetchWeek()
                let selectedIndex = WidgetSelectionStore.selectedIndex(in: menus)
                completion(
                    MenuWidgetEntry(
                        date: Date(),
                        menus: menus,
                        selectedIndex: selectedIndex,
                        errorMessage: nil
                    )
                )
            } catch {
                completion(
                    MenuWidgetEntry(
                        date: Date(),
                        menus: [],
                        selectedIndex: 0,
                        errorMessage: error.localizedDescription
                    )
                )
            }
        }
    }

    private var sampleEntry: MenuWidgetEntry {
        let calendar = MenuCalendar.seoul
        let dates = (-4...0).compactMap {
            calendar.date(byAdding: .day, value: $0, to: Date())
        }
        let menus = dates.map {
            DailyMenu(
                date: $0,
                lunch: "매콤돈육장조림  ·  근대된장국  ·  쌀밥  ·  치커리겉절이  ·  포기김치",
                dinner: "돈코츠라멘 · 시치미  ·  타코야끼 · 소스  ·  쌀밥  ·  참깨연근무침\n후식: 쟈스민차",
                fetchedAt: Date()
            )
        }
        return MenuWidgetEntry(
            date: Date(),
            menus: menus,
            selectedIndex: max(0, menus.count - 1),
            errorMessage: nil
        )
    }
}

struct PangyoMenuWidgetView: View {
    let entry: MenuWidgetEntry

    var body: some View {
        if let menu = entry.selectedMenu {
            VStack(alignment: .leading, spacing: 10) {
                header(for: menu)
                mealSection(title: "중식", symbol: "sun.max", menu: menu.lunch)
                mealSection(title: "석식", symbol: "moon.stars", menu: menu.dinner)
            }
        } else {
            ContentUnavailableView(
                "메뉴를 불러오지 못했습니다",
                systemImage: "fork.knife",
                description: Text(entry.errorMessage ?? "잠시 후 다시 확인해주세요.")
            )
        }
    }

    private func header(for menu: DailyMenu) -> some View {
        HStack(spacing: 10) {
            Text(Self.dateFormatter.string(from: menu.date))
                .font(.title3.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Button(intent: PreviousMenuDayIntent()) {
                    Image(systemName: "chevron.left")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(entry.selectedIndex <= 0)
                .accessibilityLabel("이전 날짜")

                Button(intent: NextMenuDayIntent()) {
                    Image(systemName: "chevron.right")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(entry.selectedIndex + 1 >= entry.menus.count)
                .accessibilityLabel("다음 날짜")
            }
            .foregroundStyle(.secondary)
        }
    }

    private func mealSection(title: String, symbol: String, menu: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.headline)

            Divider()

            Text(menu ?? "등록된 메뉴가 없습니다.")
                .font(.callout)
                .foregroundStyle(menu == nil ? .secondary : .primary)
                .lineLimit(5)
                .minimumScaleFactor(0.82)
                .allowsTightening(true)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter
    }()
}

@main
struct PangyoMenuWidget: Widget {
    static let kind = "com.chaeeun.pangyo-menu-widget.today"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: MenuWidgetProvider()) { entry in
            PangyoMenuWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 메뉴")
        .description("판교캠의 금일 중식과 석식 메뉴를 표시합니다.")
        .supportedFamilies([.systemLarge])
    }
}
