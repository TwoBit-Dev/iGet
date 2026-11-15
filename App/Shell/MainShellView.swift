import SwiftUI

enum WorkspacePage: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case gallery = "Widget library"
    case desktop = "My widgets"
    case tools = "Daily tools"
    case studio = "Studio"
    case spaces = "Spaces"
    case settings = "Settings"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .gallery: return "square.stack.3d.up"
        case .desktop: return "macwindow"
        case .tools: return "checklist"
        case .studio: return "slider.horizontal.3"
        case .spaces: return "rectangle.3.group"
        case .settings: return "gearshape"
        }
    }
}

struct MainShellView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openWindow) private var openWindow
    @State private var showGuide = false
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 196)
            Divider()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text(L10n.text(store.page.rawValue)).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    Spacer()
                    if let space = store.document.activeSpace {
                        Menu {
                            ForEach(store.document.spaces) { space in
                                Button(space.name) { store.activateSpace(space.id) }
                            }
                        } label: { Label(space.name, systemImage: space.symbol).font(.system(size: 11, weight: .medium)) }
                        .menuStyle(.borderlessButton).fixedSize()
                    }
                    Divider().frame(height: 14)
                    Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
                        .buttonStyle(.plain).foregroundStyle(.secondary).help(L10n.text("How desktop widgets work"))
                }.padding(.horizontal, 28).frame(height: 48)
                Divider()
                page
            }.background(BrandTheme.background(scheme == .dark))
        }
        .frame(minWidth: 1040, minHeight: 700)
        .tint(BrandTheme.accent)
        .accentColor(BrandTheme.accent)
        .preferredColorScheme(store.appearance)
        .environment(\.locale, localization.locale)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let notice = store.notice {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle").foregroundStyle(.secondary)
                    Text(notice).font(.system(size: 12))
                    Spacer()
                    if store.canUndo { Button(L10n.text("Undo")) { store.undo() }.buttonStyle(.plain).fontWeight(.semibold) }
                    Button { store.notice = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel(L10n.text("Dismiss message"))
                }.padding(14).background(.regularMaterial)
            }
        }
        .alert(L10n.text("Unable to complete action"), isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button(L10n.text("OK")) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .sheet(item: $store.selectedTool) { tool in
            ToolEditorView(kind: tool).environmentObject(store).preferredColorScheme(store.appearance)
        .environment(\.locale, localization.locale)
        }
        .sheet(isPresented: $showGuide) { WidgetGuideView() }
        .sheet(isPresented: Binding(get: { store.pendingPack != nil }, set: { if !$0 { store.pendingPack = nil } })) {
            ImportReviewView().environmentObject(store)
        }
        .onOpenURL { url in
            guard url.scheme == "iget", url.host == "tool", let kind = ToolKind(rawValue: url.lastPathComponent) else { return }
            store.selectedTool = kind
            MainWindowRegistry.show()
        }
        .onAppear { MainWindowRegistry.reopen = { openWindow(id: "main") } }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                BrandMark(size: 37)
                Text("iGet").font(.system(size: 25, weight: .semibold)).tracking(-0.8)
            }.padding(.horizontal, 24).padding(.top, 34).padding(.bottom, 32)
            Text(L10n.text("WORKSPACE")).font(.system(size: 9, weight: .semibold)).tracking(1.5).foregroundStyle(.tertiary).padding(.horizontal, 24).padding(.bottom, 12)
            ForEach(WorkspacePage.allCases.filter { $0 != .settings }) { page in
                Button { store.page = page } label: {
                    HStack(spacing: 11) {
                        Image(systemName: page.symbol).font(.system(size: 14)).frame(width: 18)
                        Text(L10n.text(page.rawValue)).font(.system(size: 12, weight: store.page == page ? .semibold : .regular))
                        Spacer(minLength: 0)
                        if page == .desktop { Text("\(store.document.activeTiles.count)").font(.system(size: 10)).foregroundStyle(.secondary) }
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 37)
                    .foregroundStyle(store.page == page ? Color.primary : Color.secondary)
                    .background(store.page == page ? BrandTheme.accent.opacity(scheme == .dark ? 0.22 : 0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                    .contentShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Label(store.samplingInterval >= 15 ? L10n.text("Power saver") : L10n.text(store.document.preferences.energy.rawValue.capitalized), systemImage: "leaf")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                Text(L10n.count(ToolKind.allCases.count, one: "%d widget", other: "%d widgets")).font(.system(size: 10)).foregroundStyle(.tertiary)
            }.padding(20)
            Divider().padding(.horizontal, 16)
            Button { store.page = .settings } label: {
                Label(L10n.text("Settings"), systemImage: "gearshape")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }.background(BrandTheme.sidebar(scheme == .dark))
    }
    @ViewBuilder private var page: some View {
        switch store.page {
        case .overview: OverviewPage()
        case .gallery: GalleryView()
        case .desktop: DesktopPage()
        case .tools: DailyToolsPage()
        case .studio: StudioPage()
        case .spaces: SpacesView()
        case .settings: SettingsView()
        }
    }
}

struct WidgetGuideView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeading(eyebrow: L10n.text("DESKTOP WIDGETS"), title: L10n.text("Desktop and system widgets"), subtitle: L10n.text("Add widgets through iGet or the macOS widget gallery."))
            Surface {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L10n.text("iGet desktop widgets"), systemImage: "macwindow").font(.headline)
                    Text(L10n.text("Add any tool from the library. Drag the handle at the top of a desktop widget to move it. Spaces remember each layout; keep iGet running to use them."))
                        .font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            Surface {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L10n.text("macOS widgets"), systemImage: "square.grid.2x2").font(.headline)
                    Text(L10n.text("With the signed widget extension installed, Control-click the desktop, choose Edit Widgets, then search for iGet. macOS controls their placement and refresh schedule. Spaces arrange iGet desktop widgets only."))
                        .font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack { Spacer(); Button(L10n.text("Got it")) { dismiss() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction) }
        }.padding(32).frame(width: 570)
    }
}
