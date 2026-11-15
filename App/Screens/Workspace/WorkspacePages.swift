import SwiftUI

struct OverviewPage: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeading(eyebrow: Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(localization.locale)), title: L10n.text("Overview"), subtitle: L10n.text("Tasks, focus sessions and active widgets."))
                HStack(spacing: 16) {
                    statistic(L10n.text("Active widgets"), value: "\(store.document.activeTiles.filter(\.enabled).count)", symbol: "macwindow")
                    statistic(L10n.text("Tasks remaining"), value: "\(store.document.tasks.filter { !$0.completed }.count)", symbol: "checklist")
                    statistic(L10n.text("Focus sessions"), value: "\(store.document.focus.completedSessions)", symbol: "timer")
                }
                HStack { Text(L10n.text("TASKS AND FOCUS")).font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(.secondary); Spacer(); Button(L10n.text("Daily tools")) { store.page = .tools }.font(.system(size: 11)) }
                HStack(spacing: 18) {
                    WorkspaceWidgetView(kind: .focus, document: store.document, paletteID: "paper", onFocus: { store.toggleFocus() }).frame(height: 210)
                    WorkspaceWidgetView(kind: .tasks, document: store.document, paletteID: "lilac", onTask: { store.setTask($0, completed: $1) }).frame(height: 210)
                }
                Surface {
                    HStack(spacing: 18) {
                        Image(systemName: store.document.activeSpace?.symbol ?? "rectangle.3.group").font(.system(size: 26, weight: .light)).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.format("Current space: %@", store.document.activeSpace?.name ?? "—")).font(.system(size: 16, weight: .medium))
                            Text(L10n.text("Saved widget layout.")).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(L10n.text("Manage spaces")) { store.page = .spaces }
                    }
                }
                Label(L10n.text("Local storage · No account required"), systemImage: "internaldrive").font(.system(size: 11)).foregroundStyle(.tertiary)
            }.padding(32)
        }
    }
    private func statistic(_ title: String, value: String, symbol: String) -> some View {
        Surface {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Image(systemName: symbol).foregroundStyle(.secondary); Spacer(); Text(value).font(.system(size: 29, weight: .medium, design: .rounded)).monospacedDigit() }
                Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DesktopPage: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    PageHeading(eyebrow: store.document.activeSpace?.name ?? L10n.text("Your space"), title: L10n.text("Your desktop"), subtitle: L10n.text("Manage the widgets in your current space."))
                    Spacer()
                    Button(store.document.desktopVisible ? L10n.text("Hide desktop widgets") : L10n.text("Show desktop widgets")) { store.change { $0.desktopVisible.toggle() } }.controlSize(.large)
                }
                Toggle(L10n.text("Lock widget positions"), isOn: Binding(get: { store.document.preferences.lockLayout }, set: { locked in store.preferences { $0.lockLayout = locked } })).font(.system(size: 12))
                if store.document.activeTiles.isEmpty {
                    EmptyWorkspaceView(symbol: "macwindow.badge.plus", title: L10n.text("No widgets in this space"), detail: L10n.text("Add widgets from the library."))
                    Button(L10n.text("Browse widgets")) { store.page = .gallery }.buttonStyle(.borderedProminent)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 205), spacing: 22)], spacing: 24) {
                    ForEach(store.document.activeTiles) { tile in
                        VStack(alignment: .leading, spacing: 12) {
                            Button { store.editInStudio(tile.id) } label: {
                                ZStack {
                                    LiveTile(tile: tile, interactive: false)
                                        .frame(height: 190)
                                        .allowsHitTesting(false)
                                        .opacity(tile.enabled ? 1 : 0.5)
                                    Color.clear
                                        .contentShape(RoundedRectangle(cornerRadius: 18))
                                }
                            }
                            .buttonStyle(.plain)
                            .help(L10n.text("Customize"))
                            HStack {
                                Text(tile.kind.title).font(.system(size: 12, weight: .medium))
                                Spacer()
                                Button { store.editTile(tile.id) { $0.enabled.toggle() } } label: { Image(systemName: tile.enabled ? "eye" : "eye.slash") }.buttonStyle(.plain).help(tile.enabled ? L10n.text("Hide widget") : L10n.text("Show widget"))
                                Menu {
                                    Button(L10n.text("Open tool")) { store.selectedTool = tile.kind }
                                    Button(L10n.text("Customize")) { store.editInStudio(tile.id) }
                                    Divider()
                                    Button(L10n.text("Remove widget"), role: .destructive) { store.removeTile(tile.id) }
                                } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).fixedSize()
                            }
                            Text("\(L10n.text(tile.size.rawValue.capitalized)) · \(L10n.text(tile.palette.capitalized))").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                }
            }.padding(32)
        }
    }
}

struct ImportReviewView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeading(eyebrow: L10n.text("SPACE IMPORT"), title: store.pendingPack?.name ?? L10n.text("Import space"), subtitle: L10n.text("Review this space before adding it."))
            if let pack = store.pendingPack {
                HStack(spacing: 10) {
                    ForEach(pack.tiles.prefix(6)) { tile in Image(systemName: tile.kind.symbol).font(.title3).padding(10).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8)) }
                }
                Text(L10n.format("%d widgets · Schema %d", pack.tiles.count, pack.schemaVersion)).font(.system(size: 12)).foregroundStyle(.secondary)
                if pack.tiles.contains(where: { $0.kind == .weather || $0.kind == .music }) { Text(L10n.text("Connected widgets use their built-in service providers when active. Music still requires you to connect the player.")).font(.system(size: 11)).foregroundStyle(.secondary) }
                if pack.tiles.contains(where: { $0.settings.photo != nil || $0.settings.bodyText != nil }) { Text(L10n.text("This pack includes widget photos or custom text.")).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("Built-in widgets and editable settings"), systemImage: "checkmark")
                Label(L10n.text("No executable scripts"), systemImage: "checkmark")
                Label(L10n.text("Your shared tasks and notes stay as they are"), systemImage: "checkmark")
            }.font(.system(size: 12))
            HStack { Spacer(); Button(L10n.text("Cancel")) { store.pendingPack = nil }; Button(L10n.text("Import space")) { store.importPack() }.buttonStyle(.borderedProminent) }
        }.padding(32).frame(width: 500)
    }
}
