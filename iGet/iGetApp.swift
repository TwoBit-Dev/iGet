import SwiftUI

@main
struct iGetApp: App {
    @ObservedObject private var localization = LocalizationManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Window("iGet", id: "main") {
            MainShellView().environmentObject(delegate.store).background(MainWindowReader())
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 810)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {
                Button(L10n.text("Settings…")) { delegate.store.page = .settings; MainWindowRegistry.show() }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu(L10n.text("Workspace")) {
                Button(L10n.text("Show or hide desktop widgets")) { delegate.store.change { $0.desktopVisible.toggle() } }.keyboardShortcut("d", modifiers: [.command, .shift])
                Button(L10n.text("Widget library")) { delegate.store.page = .gallery; MainWindowRegistry.show() }.keyboardShortcut("1", modifiers: .command)
                Button(L10n.text("Daily tools")) { delegate.store.page = .tools; MainWindowRegistry.show() }.keyboardShortcut("2", modifiers: .command)
                Button(L10n.text("Start or pause focus")) { delegate.store.toggleFocus() }.keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
        MenuBarExtra {
            MenuBarView().environmentObject(delegate.store)
        } label: {
            Image(systemName: "square.grid.2x2")
        }.menuBarExtraStyle(.window)
    }
}
