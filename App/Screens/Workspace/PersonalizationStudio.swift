import SwiftUI
import AppKit

struct StudioPage: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.colorScheme) private var scheme
    @State private var tab = "Style"
    @State private var selectedLayer: UUID?
    @State private var demandToken = UUID()
    init(tab: String = "Style") { _tab = State(initialValue: tab) }
    private var tile: DesktopTile? { store.document.activeTiles.first { $0.id == store.editingTileID } ?? store.document.activeTiles.first }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                PageHeading(eyebrow: L10n.text("WIDGET EDITOR"), title: L10n.text("Widget Studio"), subtitle: L10n.text("Edit appearance, content and desktop placement."))
                Spacer()
                if let tile {
                    Menu {
                        Button(L10n.text("Duplicate widget")) { store.duplicateTile(tile.id) }
                        Button(L10n.text("Export this space…")) { store.exportSpace() }
                        Divider()
                        Button(L10n.text("Remove widget"), role: .destructive) { store.removeTile(tile.id) }
                    } label: { Image(systemName: "ellipsis.circle").font(.title3) }.menuStyle(.borderlessButton).fixedSize()
                }
            }
            if let tile {
                Picker(L10n.text("Editing"), selection: Binding(get: { self.tile?.id ?? tile.id }, set: { store.editingTileID = $0; selectedLayer = nil })) {
                    ForEach(Array(store.document.activeTiles.enumerated()), id: \.element.id) { index, value in Text("\(value.displayTitle) · \(index + 1)").tag(value.id) }
                }.frame(maxWidth: 390)
                HStack(alignment: .top, spacing: 22) {
                    VStack(spacing: 0) {
                        HStack { Label(L10n.text("LIVE PREVIEW"), systemImage: "viewfinder").font(.system(size: 9, weight: .semibold)).tracking(1); Spacer(); Text("\(Int(tile.displayWidth)) × \(Int(tile.displayHeight)) pt").font(.system(size: 10)).monospacedDigit() }.foregroundStyle(.secondary).padding(18)
                        GeometryReader { geometry in
                            let scale = min(1, max(0.2, min((geometry.size.width - 30) / tile.displayWidth, (geometry.size.height - 30) / tile.displayHeight)))
                            Group {
                                if tile.kind == .canvas && tab == "Layers" {
                                    TileSurface(tile: tile) {
                                        LayerCanvasView(layers: tile.settings.layers ?? CanvasLayer.localizedStarter, options: tile.settings, document: store.document, selectedID: selectedLayer, onSelect: { selectedLayer = $0 }, onMove: { id, x, y in store.customize(tile.id) { options in
                                            if options.layers == nil { options.layers = CanvasLayer.localizedStarter }
                                            guard let index = options.layers?.firstIndex(where: { $0.id == id }) else { return }
                                            options.layers?[index].x = x; options.layers?[index].y = y
                                        } })
                                    }
                                } else { LiveTile(tile: tile) }
                            }.frame(width: tile.displayWidth, height: tile.displayHeight).scaleEffect(scale)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        }
                        HStack { Image(systemName: "hand.draw"); Text(tile.kind == .canvas && tab == "Layers" ? L10n.text("Drag a layer to position it.") : L10n.text("Try the controls in your preview.")) }.font(.system(size: 10)).foregroundStyle(.secondary).padding(16)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(BrandTheme.accent.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(BrandTheme.accent.opacity(0.1)))
                    VStack(spacing: 15) {
                        Picker(L10n.text("Inspector"), selection: $tab) {
                            Text(L10n.text("Style")).tag("Style")
                            Text(L10n.text("Content")).tag("Content")
                            if tile.kind == .canvas { Text(L10n.text("Layers")).tag("Layers") }
                        }.pickerStyle(.segmented)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if tab == "Style" { WidgetStyleInspector(tile: tile) }
                                else if tab == "Layers" && tile.kind == .canvas { CanvasInspector(tile: tile, selectedID: $selectedLayer) }
                                else { WidgetContentInspector(tile: tile) }
                            }.padding(2)
                        }.scrollIndicators(.hidden)
                    }.frame(width: 300)
                }
            } else {
                EmptyWorkspaceView(symbol: "square.on.square.dashed", title: L10n.text("Start with a widget"), detail: L10n.text("Choose a tool, a game or a blank canvas from the library."))
                Button(L10n.text("Build a canvas")) { store.createAndCustomize(.canvas) }.buttonStyle(.borderedProminent)
                Spacer()
            }
        }.padding(28).background(BrandTheme.background(scheme == .dark)).tint(BrandTheme.accent).accentColor(BrandTheme.accent).environment(\.locale, localization.locale)
            .onAppear(perform: updateDemand)
            .onDisappear { store.setInterfaceDemand(demandToken, kind: nil) }
            .onChange(of: tile?.id) { _, _ in updateDemand() }
            .onChange(of: tile?.settings.city) { _, _ in updateDemand() }
            .onChange(of: tile?.kind) { _, kind in if kind != .canvas && tab == "Layers" { tab = "Style" } }
    }
    private func updateDemand() { store.setInterfaceDemand(demandToken, kind: tile?.kind, city: tile?.settings.city) }
}

private struct WidgetStyleInspector: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let tile: DesktopTile
    @EnvironmentObject private var store: WorkspaceStore
    private func field<T>(_ key: WritableKeyPath<WidgetOptions, T>) -> Binding<T> { Binding(get: { tile.settings[keyPath: key] }, set: { value in store.customize(tile.id) { $0[keyPath: key] = value } }) }
    var body: some View {
        Group {
            inspectorHeading(L10n.text("IDENTITY"))
            TextField(L10n.text("Widget title"), text: field(\.title)).textFieldStyle(.roundedBorder)
            Toggle(L10n.text("Show heading"), isOn: field(\.showHeader))
            inspectorHeading(L10n.text("COLOR & SURFACE"))
            PalettePicker(selection: Binding(get: { tile.palette }, set: { palette in store.editTile(tile.id) { $0.palette = palette } }))
            Toggle(L10n.text("Custom colors"), isOn: field(\.customColors))
            if tile.settings.customColors {
                ColorPicker(L10n.text("Background"), selection: color(\.backgroundHex), supportsOpacity: false)
                ColorPicker(L10n.text("Text"), selection: color(\.foregroundHex), supportsOpacity: false)
                ColorPicker(L10n.text("Accent"), selection: color(\.accentHex), supportsOpacity: false)
            }
            Picker(L10n.text("Surface"), selection: field(\.backdrop)) { ForEach(WidgetBackdrop.allCases, id: \.self) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }
            SliderSetting(title: L10n.text("Opacity"), value: tile.settings.opacity, range: 0.2...1, step: 0.05) { value in store.customize(tile.id) { $0.opacity = value } }
            SliderSetting(title: L10n.text("Corners"), value: tile.cornerRadius, range: 0...48, step: 2) { value in store.editTile(tile.id) { $0.cornerRadius = value } }
            SliderSetting(title: L10n.text("Border"), value: tile.settings.borderWidth, range: 0...6, step: 0.5) { value in store.customize(tile.id) { $0.borderWidth = value } }
            Toggle(L10n.text("Window shadow"), isOn: field(\.shadow))
            inspectorHeading(L10n.text("SIZE & TYPE"))
            Picker(L10n.text("Preset"), selection: Binding(get: { tile.size }, set: { size in store.editTile(tile.id) { $0.size = size; var options = $0.settings; options.width = nil; options.height = nil; $0.settings = options } })) { ForEach(TileSize.allCases) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }
            SliderSetting(title: L10n.text("Width"), value: tile.displayWidth, range: 144...720, step: 8) { value in store.customize(tile.id) { $0.width = value } }
            SliderSetting(title: L10n.text("Height"), value: tile.displayHeight, range: 144...720, step: 8) { value in store.customize(tile.id) { $0.height = value } }
            Picker(L10n.text("Typeface"), selection: field(\.typeface)) { ForEach(WidgetTypeface.allCases, id: \.self) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }
            SliderSetting(title: L10n.text("Text scale"), value: tile.settings.fontScale, range: 0.65...1.6, step: 0.05) { value in store.customize(tile.id) { $0.fontScale = value } }
            inspectorHeading(L10n.text("ON YOUR DESKTOP"))
            Picker(L10n.text("Window layer"), selection: field(\.placement)) { ForEach(WidgetPlacement.allCases, id: \.self) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }
            Toggle(L10n.text("Lock position"), isOn: field(\.locked))
            Toggle(L10n.text("Snap to an 8 pt grid"), isOn: field(\.snapToGrid))
            Toggle(L10n.text("Pass clicks through"), isOn: field(\.clickThrough))
            if tile.settings.clickThrough { Text(L10n.text("Change this here to interact with the desktop widget again.")).font(.system(size: 10)).foregroundStyle(.secondary) }
        }.font(.system(size: 12))
    }
    private func color(_ key: WritableKeyPath<WidgetOptions, String>) -> Binding<Color> {
        Binding(get: { Color(hex: tile.settings[keyPath: key]) }, set: { value in
            guard let rgb = NSColor(value).usingColorSpace(.deviceRGB) else { return }
            let hex = String(format: "#%02X%02X%02X", Int((rgb.redComponent * 255).rounded()), Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
            store.customize(tile.id) { $0[keyPath: key] = hex }
        })
    }
}

struct WidgetContentInspector: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let tile: DesktopTile
    @EnvironmentObject private var store: WorkspaceStore
    @State private var shortcutName = ""
    @State private var shortcutURL = ""
    private func field<T>(_ key: WritableKeyPath<WidgetOptions, T>) -> Binding<T> { Binding(get: { tile.settings[keyPath: key] }, set: { value in store.customize(tile.id) { $0[keyPath: key] = value } }) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            inspectorHeading(tile.kind.title.uppercased(with: localization.locale))
            switch tile.kind {
            case .photo:
                Text(L10n.text("A copy is optimized and stored inside this widget.")).foregroundStyle(.secondary)
                Button(L10n.text("Choose photo…")) { store.choosePhoto(for: tile.id) }
                Toggle(L10n.text("Fill the frame"), isOn: field(\.photoFill))
                if tile.settings.photo != nil { Button(L10n.text("Remove photo")) { store.customize(tile.id) { $0.photo = nil } } }
            case .sticker, .pet:
                TextField(L10n.text("Emoji or short text"), text: field(\.symbol)).textFieldStyle(.roundedBorder)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(tile.kind == .pet ? ["🐈", "🐕", "🐸", "🦊", "🐼", "🐧", "🐰", "🐢"] : ["🌸", "✨", "🌈", "🍒", "🪩", "🦋", "☁️", "🌻"], id: \.self) { value in Button { store.customize(tile.id) { $0.symbol = value } } label: { Text(value).font(.system(size: 25)).frame(maxWidth: .infinity).padding(6) }.buttonStyle(.plain) }
                }
                SliderSetting(title: L10n.text("Sticker rotation"), value: tile.settings.rotation, range: -180...180, step: 5) { value in store.customize(tile.id) { $0.rotation = value } }
                if tile.kind == .pet { Text(L10n.text("Feed, play and nap using the controls in the preview or on your desktop.")).foregroundStyle(.secondary) }
            case .quote:
                Text(L10n.text("One quote per line. The next button switches quotes.")).foregroundStyle(.secondary)
                WidgetTextEditor(value: tile.settings.bodyText ?? WidgetOptions.quotes.joined(separator: "\n")) { value in store.customize(tile.id) { $0.bodyText = value; $0.quoteIndex = 0 } }
            case .notes:
                Toggle(L10n.text("Use the shared quick note"), isOn: Binding(get: { tile.settings.bodyText == nil }, set: { shared in store.customize(tile.id) { $0.bodyText = shared ? nil : store.document.note } }))
                if let text = tile.settings.bodyText { WidgetTextEditor(value: text) { value in store.customize(tile.id) { $0.bodyText = value } } }
                else { Button(L10n.text("Open shared note")) { store.selectedTool = .notes } }
            case .clock:
                Picker(L10n.text("Clock style"), selection: Binding(get: {
                    MascotClockType.from(symbol: tile.settings.symbol)?.rawValue ?? "digital"
                }, set: { choice in
                    store.customize(tile.id) { $0.symbol = choice }
                })) {
                    Text(L10n.text("Minnie (Apple Watch Illustrated)")).tag("minnie")
                    Text(L10n.text("Minnie (Character Arms)")).tag("minnie-arms")
                    Text(L10n.text("Minnie (Classic Hands)")).tag("minnie-classic")
                    Text(L10n.text("Digital")).tag("digital")
                    Text(L10n.text("Cat mascot (Mimi)")).tag("cat")
                    Text(L10n.text("Bunny mascot (Bibi)")).tag("bunny")
                    Text(L10n.text("Bear mascot (Kuma)")).tag("bear")
                }
                Picker(L10n.text("Time zone"), selection: Binding(get: { tile.settings.timeZone ?? store.document.preferences.clockTimeZone }, set: { zone in store.customize(tile.id) { $0.timeZone = zone } })) { ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ")).tag($0) } }
                Button(L10n.text("Follow shared clock settings")) { store.customize(tile.id) { $0.timeZone = nil } }
            case .countdown:
                TextField(L10n.text("Event"), text: Binding(get: { tile.settings.countdownTitle ?? store.document.countdown.title }, set: { title in store.customize(tile.id) { $0.countdownTitle = title } })).textFieldStyle(.roundedBorder)
                DatePicker(L10n.text("Date"), selection: Binding(get: { tile.settings.countdownDate ?? store.document.countdown.date }, set: { date in store.customize(tile.id) { $0.countdownDate = date } }), displayedComponents: .date)
            case .water:
                Stepper(L10n.count(tile.settings.goal, one: "Daily goal: %d glass", other: "Daily goal: %d glasses"), value: field(\.goal), in: 1...30)
                Button(L10n.text("Reset today")) { store.customize(tile.id) { $0.counter = 0; $0.dailyKey = LocalHabit.dayKey() } }
            case .dice: Button(L10n.text("Roll both dice")) { store.rollDice(tile.id) }
            case .game: Text(L10n.text("Two players take turns as X and O.")).foregroundStyle(.secondary); Button(L10n.text("Start a new game")) { store.resetGame(tile.id) }
            case .breathing: Text(L10n.text("A one-minute, three-phase timer. Animation respects Reduce Motion and Power saver.")).foregroundStyle(.secondary)
            case .weather: WeatherCityEditor(tile: tile)
            case .music: MusicConnectionSettings(provider: store.music)
            case .launcher:
                ForEach(tile.settings.shortcuts) { item in
                    HStack { Label(item.title, systemImage: item.symbol).lineLimit(1); Spacer(); Button { store.customize(tile.id) { $0.shortcuts.removeAll { $0.id == item.id } } } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain).accessibilityLabel(L10n.format("Remove %@", item.title)) }
                }
                TextField(L10n.text("Shortcut name"), text: $shortcutName).textFieldStyle(.roundedBorder)
                TextField("https://…", text: $shortcutURL).textFieldStyle(.roundedBorder)
                Button(L10n.text("Add website")) {
                    let item = LaunchShortcut(title: shortcutName.trimmingCharacters(in: .whitespacesAndNewlines), website: shortcutURL.trimmingCharacters(in: .whitespacesAndNewlines))
                    do { try item.validate(); store.customize(tile.id) { $0.shortcuts.append(item) }; shortcutName = ""; shortcutURL = "" }
                    catch { store.errorMessage = L10n.text("Enter a name and a valid http or https website address.") }
                }.disabled(shortcutName.isEmpty || shortcutURL.isEmpty)
                Button(L10n.text("Add application…")) { store.chooseApplication(for: tile.id) }
            case .canvas: Text(L10n.text("Open the Layers tab to add text, a clock, dates, symbols and progress bars. Drag layers directly in the preview.")).foregroundStyle(.secondary)
            default: Button(L10n.format("Open %@", tile.kind.title)) { store.selectedTool = tile.kind }
            }
        }.font(.system(size: 12))
    }
}

private struct CanvasInspector: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let tile: DesktopTile
    @Binding var selectedID: UUID?
    @EnvironmentObject private var store: WorkspaceStore
    private var layers: [CanvasLayer] { tile.settings.layers ?? CanvasLayer.localizedStarter }
    private var selected: CanvasLayer? { layers.first { $0.id == selectedID } ?? layers.last }
    private func update(_ edit: (inout CanvasLayer) -> Void) {
        guard let id = selected?.id else { return }
        store.customize(tile.id) { options in
            if options.layers == nil { options.layers = CanvasLayer.localizedStarter }
            guard let index = options.layers?.firstIndex(where: { $0.id == id }) else { return }
            edit(&options.layers![index])
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            inspectorHeading(L10n.text("ADD A LAYER"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                ForEach(CanvasContent.allCases, id: \.self) { kind in Button(L10n.text(kind.rawValue.capitalized)) { store.addCanvasLayer(tile.id, kind: kind); selectedID = store.document.activeTiles.first(where: { $0.id == tile.id })?.settings.layers?.last?.id }.controlSize(.small) }
            }
            inspectorHeading(L10n.text("LAYERS · BACK TO FRONT"))
            ForEach(layers) { layer in
                Button { selectedID = layer.id } label: {
                    HStack { Image(systemName: layer.kind == .text ? "textformat" : layer.kind == .time ? "clock" : "square.on.square"); Text(layer.text.isEmpty ? L10n.text(layer.kind.rawValue.capitalized) : layer.text).lineLimit(1); Spacer(); if selected?.id == layer.id { Image(systemName: "checkmark") } }.padding(8).background(selected?.id == layer.id ? BrandTheme.accent.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
            if let layer = selected {
                inspectorHeading(L10n.text("EDIT LAYER"))
                if layer.kind == .text || layer.kind == .symbol { TextField(L10n.text("Text or emoji"), text: Binding(get: { layer.text }, set: { value in update { $0.text = value } })).textFieldStyle(.roundedBorder) }
                ColorPicker(L10n.text("Color"), selection: Binding(get: { Color(hex: layer.colorHex) }, set: { color in
                    guard let rgb = NSColor(color).usingColorSpace(.deviceRGB) else { return }
                    update { $0.colorHex = String(format: "#%02X%02X%02X", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255)) }
                }), supportsOpacity: false)
                SliderSetting(title: L10n.text("Text size"), value: layer.fontSize, range: 8...120, step: 1) { value in update { $0.fontSize = value } }
                SliderSetting(title: L10n.text("Horizontal position"), value: layer.x, range: 0...1, step: 0.01) { value in update { $0.x = value } }
                SliderSetting(title: L10n.text("Vertical position"), value: layer.y, range: 0...1, step: 0.01) { value in update { $0.y = value } }
                SliderSetting(title: L10n.text("Width"), value: layer.width, range: 0.05...1, step: 0.05) { value in update { $0.width = value } }
                SliderSetting(title: L10n.text("Rotation"), value: layer.rotation, range: -180...180, step: 5) { value in update { $0.rotation = value } }
                SliderSetting(title: L10n.text("Opacity"), value: layer.opacity, range: 0...1, step: 0.05) { value in update { $0.opacity = value } }
                if layer.kind == .progress {
                    Picker(L10n.text("Data source"), selection: Binding(get: { layer.source ?? .manual }, set: { source in update { $0.source = source } })) { ForEach(CanvasDataSource.allCases, id: \.self) { Text(L10n.text($0.rawValue.capitalized)).tag($0) } }
                    if layer.source == nil || layer.source == .manual { SliderSetting(title: L10n.text("Progress"), value: layer.progress, range: 0...1, step: 0.05) { value in update { $0.progress = value } } }
                }
                HStack {
                    Button(L10n.text("Send back")) { reorder(layer.id, offset: -1) }
                    Button(L10n.text("Bring forward")) { reorder(layer.id, offset: 1) }
                }.controlSize(.small)
                Button(L10n.text("Remove layer"), role: .destructive) { store.customize(tile.id) { options in if options.layers == nil { options.layers = CanvasLayer.localizedStarter }; options.layers?.removeAll { $0.id == layer.id } }; selectedID = nil }
            }
        }.font(.system(size: 12))
    }
    private func reorder(_ id: UUID, offset: Int) {
        store.customize(tile.id) { options in
            if options.layers == nil { options.layers = CanvasLayer.localizedStarter }
            guard let index = options.layers?.firstIndex(where: { $0.id == id }), let count = options.layers?.count, (0..<count).contains(index + offset) else { return }
            options.layers?.swapAt(index, index + offset)
        }
    }
}

private struct WeatherCityEditor: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let tile: DesktopTile
    @EnvironmentObject private var store: WorkspaceStore
    @State private var name = ""
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(L10n.text("City"), selection: Binding(get: { tile.settings.city.name }, set: { name in if let city = WeatherCity.presets.first(where: { $0.name == name }) { store.customize(tile.id) { $0.city = city } } })) {
                ForEach(WeatherCity.presets) { Text($0.name).tag($0.name) }
                if !WeatherCity.presets.contains(where: { $0.name == tile.settings.city.name }) { Text(tile.settings.city.name).tag(tile.settings.city.name) }
            }
            Text(L10n.text("Or choose a location manually. Your device location is never requested.")).foregroundStyle(.secondary)
            TextField(L10n.text("City name"), text: $name).textFieldStyle(.roundedBorder)
            TextField(L10n.text("Latitude"), value: $latitude, format: .number).textFieldStyle(.roundedBorder)
            TextField(L10n.text("Longitude"), value: $longitude, format: .number).textFieldStyle(.roundedBorder)
            Button(L10n.text("Use this location")) {
                let city = WeatherCity(name: name, latitude: latitude, longitude: longitude)
                do { try city.validate(); store.customize(tile.id) { $0.city = city } } catch { store.errorMessage = error.localizedDescription }
            }
            Text(L10n.text("Forecasts use Open-Meteo and refresh every 15 minutes while needed.")).font(.system(size: 10)).foregroundStyle(.secondary)
        }.onAppear { name = tile.settings.city.name; latitude = tile.settings.city.latitude; longitude = tile.settings.city.longitude }
    }
}

struct MusicConnectionSettings: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject var provider: MusicProvider
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(L10n.text("Player"), selection: $provider.source) { ForEach(MusicSource.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.onChange(of: provider.source) { _, _ in provider.disconnect() }
            Text(L10n.text("Open the player and choose a track. Connecting asks macOS for Automation access to that player.")).font(.system(size: 12)).foregroundStyle(.secondary)
            HStack { Button(L10n.text("Connect")) { provider.connect() }; if provider.connected { Button(L10n.text("Disconnect")) { provider.disconnect() } } }
            if let error = provider.error { Text(error).font(.system(size: 11)).foregroundStyle(.secondary) }
        }
    }
}

private struct WidgetTextEditor: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let value: String
    let save: (String) -> Void
    @State private var text = ""
    @State private var task: Task<Void, Never>?
    var body: some View {
        TextEditor(text: $text).font(.system(size: 13)).frame(minHeight: 140).scrollContentBackground(.hidden).padding(8).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
            .onAppear { text = value }
            .onChange(of: text) { _, newValue in
                task?.cancel()
                guard newValue != value else { return }
                task = Task { @MainActor in try? await Task.sleep(for: .milliseconds(500)); guard !Task.isCancelled else { return }; save(String(newValue.prefix(25000))) }
            }
            .onDisappear { task?.cancel(); if text != value { save(String(text.prefix(25000))) } }
    }
}

private struct SliderSetting: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let save: (Double) -> Void
    @State private var draft = 0.0
    @State private var editing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack { Text(title); Spacer(); Text(draft < 2 ? String(format: "%.2f", draft) : String(format: "%.0f", draft)).monospacedDigit().foregroundStyle(.secondary) }.font(.system(size: 11))
            Slider(value: $draft, in: range, step: step, onEditingChanged: { active in editing = active; if !active && draft != value { save(draft) } }).accessibilityLabel(title)
                .onChange(of: draft) { _, newValue in if !editing && newValue != value { save(newValue) } }
        }.onAppear { draft = value }.onChange(of: value) { _, newValue in if !editing { draft = newValue } }
    }
}

private func inspectorHeading(_ text: String) -> some View { Text(text).font(.system(size: 9, weight: .semibold)).tracking(1.2).foregroundStyle(BrandTheme.accent) }
