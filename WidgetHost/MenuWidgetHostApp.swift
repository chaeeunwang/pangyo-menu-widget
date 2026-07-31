import AppKit

private final class MenuWidgetHostDelegate: NSObject, NSApplicationDelegate {
    private var terminationWorkItem: DispatchWorkItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.prohibited)
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        scheduleTermination(after: 1)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(handle)
        scheduleTermination(after: 0.2)
    }

    @objc
    private func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        if let value = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
           let url = URL(string: value) {
            handle(url)
        }
        scheduleTermination(after: 0.2)
    }

    private func handle(_ url: URL) {
        guard url.scheme == "pangyo-menu",
              url.host == "select-date",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let offsetText = components.queryItems?.first(where: { $0.name == "offset" })?.value,
              let offset = Int(offsetText),
              offset == -1 || offset == 1 else {
            return
        }
        WidgetSelectionStore.move(by: offset)
    }

    private func scheduleTermination(after delay: TimeInterval) {
        terminationWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            NSApplication.shared.terminate(nil)
        }
        terminationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

@main
enum MenuWidgetHostApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = MenuWidgetHostDelegate()
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}
