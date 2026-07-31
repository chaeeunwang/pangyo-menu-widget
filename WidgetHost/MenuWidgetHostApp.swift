import AppKit
import SwiftUI

private enum MenuRoute {
    static let fullMenu = URL(string: "https://skala-lunch.ewkimhyunsu11.workers.dev/")!
    private static let safari = URL(fileURLWithPath: "/Applications/Safari.app")

    static func open(_ route: URL) {
        guard route.scheme == "pangyo-menu", route.host == "full-menu" else { return }
        openFullMenu()
    }

    static func openFullMenu() {
        NSApplication.shared.hide(nil)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(
            [fullMenu],
            withApplicationAt: safari,
            configuration: configuration
        ) { _, error in
            if error != nil {
                NSWorkspace.shared.open(fullMenu)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@main
struct MenuWidgetHostApp: App {
    var body: some Scene {
        WindowGroup("오늘의 메뉴") {
            VStack(spacing: 18) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)

                Text("오늘의 메뉴 위젯")
                    .font(.title2.weight(.semibold))

                Text("바탕화면을 우클릭한 다음\n‘위젯 편집’에서 오늘의 메뉴를 추가하세요.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("전체 식단표 열기") {
                    MenuRoute.openFullMenu()
                }
            }
            .padding(36)
            .frame(width: 420, height: 300)
            .onOpenURL(perform: MenuRoute.open)
        }
        .windowResizability(.contentSize)
    }
}
