import SwiftUI

struct GalleryView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var category = "All"
    @State private var selected: ToolKind = .canvas
    @State private var size: TileSize = .large
    @State private var palette = "aurora"
    @State private var clockStyle = "minnie"
    private var filtered: [ToolKind] {
        [.canvas, .photo, .pet, .music, .weather, .sticker, .game, .clock, .quote, .water, .dice, .breathing, .launcher, .focus, .tasks, .notes, .calendar, .countdown, .habits, .battery, .system].filter { (item: ToolKind) in (category == "All" || item.category == category) && (query.isEmpty || (item.title + " " + item.summary + " " + item.rawValue).range(of: query, options: [.caseInsensitive, .diacriticInsensitive], locale: localization.locale) != nil) }
    }
    private var previewTile: DesktopTile {
        var tile = DesktopTile(kind: selected, size: size, palette: palette)
        if selected == .clock {
            var opts = tile.settings
            opts.symbol = clockStyle
            tile.settings = opts
        }
        return tile
    }
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.text("WIDGETS")).font(.system(size: 10, weight: .semibold)).tracking(1.7).foregroundStyle(BrandTheme.accent)
                            Text(L10n.text("Widget library")).font(.system(size: 30, weight: .semibold)).tracking(-0.9).fixedSize(horizontal: false, vertical: true)
                            Text(L10n.text("Add widgets to your desktop and edit them in Studio.")).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Label(L10n.count(ToolKind.allCases.count, one: "%d widget", other: "%d widgets"), systemImage: "square.grid.2x2")
                                Text("·")
                                Text(L10n.text("Custom colors and layouts"))
                            }.font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).padding(.top, 3)
                        }
                        Spacer(minLength: 0)
                        BrandMark(size: 67).rotationEffect(.degrees(-5))
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: [BrandTheme.accent.opacity(scheme == .dark ? 0.18 : 0.1), Color(hex: "#BFABFF").opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField(L10n.text("Search widgets"), text: $query).textFieldStyle(.plain).font(.system(size: 12))
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).accessibilityLabel(L10n.text("Clear search")) }
                    }.padding(12).background(BrandTheme.surface(scheme == .dark), in: RoundedRectangle(cornerRadius: 11))
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(["All", "Personal", "Play", "Productivity", "Time", "Connected", "System"], id: \.self) { item in
                                Button { category = item } label: {
                                    Text(L10n.text(item)).font(.system(size: 11, weight: category == item ? .semibold : .regular)).padding(.horizontal, 13).padding(.vertical, 8)
                                        .background(category == item ? BrandTheme.accent : Color.primary.opacity(0.035), in: Capsule())
                                        .foregroundStyle(category == item ? Color.white : Color.secondary)
                                }.buttonStyle(.plain)
                            }
                        }
                    }.scrollIndicators(.hidden)
                    if filtered.isEmpty {
                        EmptyWorkspaceView(symbol: "magnifyingglass", title: L10n.text("No matching widgets"), detail: L10n.text("Try another name or category."))
                        Button(L10n.text("Clear filters")) { query = ""; category = "All" }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 18)], alignment: .leading, spacing: 22) {
                            ForEach(filtered) { kind in
                                Button { selected = kind; palette = kind.defaultPalette; size = kind == .game || kind == .canvas ? .large : .small } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ZStack {
                                            LiveTile(tile: DesktopTile(kind: kind, palette: kind.defaultPalette), interactive: false)
                                                .frame(height: 177)
                                                .allowsHitTesting(false)
                                            Color.clear
                                                .contentShape(RoundedRectangle(cornerRadius: 18))
                                        }
                                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected == kind ? BrandTheme.accent.opacity(0.8) : .clear, lineWidth: 2))
                                        HStack { Text(kind.title).font(.system(size: 12, weight: .medium)); Spacer(); Image(systemName: "plus").font(.system(size: 10)).foregroundStyle(.secondary) }.foregroundStyle(.primary).padding(.horizontal, 3)
                                        Text(L10n.text(kind.category)).font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 3)
                                    }
                                    .contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityLabel(L10n.format("Configure %@", kind.title))
                            }
                        }
                    }
                }.padding(26)
            }
            Divider()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack { Text(L10n.text("WIDGET SETTINGS")).font(.system(size: 9, weight: .semibold)).tracking(1.4).foregroundStyle(BrandTheme.accent); Spacer(); Image(systemName: selected.symbol).foregroundStyle(.secondary) }
                        VStack(alignment: .leading, spacing: 7) { Text(selected.title).font(.system(size: 23, weight: .semibold)); Text(selected.summary).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                        GeometryReader { proxy in
                            let targetW = max(1, previewTile.displayWidth)
                            let targetH = max(1, previewTile.displayHeight)
                            let scale = min(1.0, min(proxy.size.width / targetW, proxy.size.height / targetH))
                            LiveTile(tile: previewTile, interactive: false)
                                .frame(width: targetW, height: targetH)
                                .scaleEffect(scale)
                                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        }
                        .frame(height: 196)
                        .allowsHitTesting(false)
                        if selected == .clock {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.text("Clock style")).font(.system(size: 11, weight: .medium))
                                Picker(L10n.text("Clock style"), selection: $clockStyle) {
                                    Text(L10n.text("Minnie Mouse (Apple Watch)")).tag("minnie")
                                    Text(L10n.text("Digital")).tag("digital")
                                    Text(L10n.text("Cat mascot (Mimi)")).tag("cat")
                                    Text(L10n.text("Bunny mascot (Bibi)")).tag("bunny")
                                    Text(L10n.text("Bear mascot (Kuma)")).tag("bear")
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) { Text(L10n.text("Starting size")).font(.system(size: 11, weight: .medium)); Picker(L10n.text("Size"), selection: $size) { ForEach(TileSize.allCases) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }.labelsHidden().pickerStyle(.segmented) }
                        VStack(alignment: .leading, spacing: 10) { Text(L10n.text("Palette")).font(.system(size: 11, weight: .medium)); PalettePicker(selection: $palette) }
                        Label(L10n.text("Resize freely in Studio"), systemImage: "arrow.up.left.and.arrow.down.right").font(.system(size: 10)).foregroundStyle(.secondary)
                    }.padding(22)
                }
                VStack(spacing: 11) {
                    Button {
                        store.createAndCustomize(selected, size: size, palette: palette)
                        if selected == .clock, let lastID = store.document.activeTiles.last?.id {
                            store.customize(lastID) { $0.symbol = clockStyle }
                        }
                    } label: { Label(L10n.text("Configure widget"), systemImage: "slider.horizontal.3").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large)
                    Button {
                        store.addTile(selected, size: size, palette: palette)
                        if selected == .clock, let lastID = store.document.activeTiles.last?.id {
                            store.customize(lastID) { $0.symbol = clockStyle }
                        }
                    } label: { Label(L10n.text("Add to desktop"), systemImage: "plus").frame(maxWidth: .infinity) }.controlSize(.large)
                    Text(L10n.text("Add via macOS → Edit Widgets.")).font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(L10n.format("Current space: %@", store.document.activeSpace?.name ?? "—")).font(.system(size: 10)).foregroundStyle(.secondary)
                }.padding(22)
            }.frame(width: 300).background(BrandTheme.surface(scheme == .dark).opacity(0.55))
        }
    }
}
