import SwiftUI

extension ThemeTokens {
    static func palette(_ id: String, dark: Bool) -> ThemePalette {
        guard dark else { return palette(for: id) }
        switch id {
        case "aurora": return ThemePalette(id: id, displayName: L10n.text("Aurora"), backgroundHex: "#302744", surfaceHex: "#3C3155", primaryTextHex: "#F4EBFF", secondaryTextHex: "#C4B0DD", accentHex: "#C4A4FF")
        case "sky": return ThemePalette(id: id, displayName: L10n.text("Sky"), backgroundHex: "#203548", surfaceHex: "#2B455D", primaryTextHex: "#E7F5FF", secondaryTextHex: "#A4C6DF", accentHex: "#8BCCF5")
        case "rose": return ThemePalette(id: id, displayName: L10n.text("Rose"), backgroundHex: "#422838", surfaceHex: "#543448", primaryTextHex: "#FFEAF5", secondaryTextHex: "#D9A7C1", accentHex: "#F0AAD1")
        case "peach": return ThemePalette(id: id, displayName: L10n.text("Peach"), backgroundHex: "#413027", surfaceHex: "#523C31", primaryTextHex: "#FFF0E5", secondaryTextHex: "#D8B39A", accentHex: "#F0BB91")
        case "paper": return ThemePalette(id: id, displayName: L10n.text("Paper"), backgroundHex: "#302B25", surfaceHex: "#3C352D", primaryTextHex: "#F3E9DB", secondaryTextHex: "#C9B8A3", accentHex: "#DFC39A")
        case "lilac": return ThemePalette(id: id, displayName: L10n.text("Lilac"), backgroundHex: "#2D2735", surfaceHex: "#393044", primaryTextHex: "#F0E7F7", secondaryTextHex: "#C2B0D1", accentHex: "#C8ACDF")
        case "slate": return ThemePalette(id: id, displayName: L10n.text("Slate"), backgroundHex: "#242E35", surfaceHex: "#303D47", primaryTextHex: "#E5EFF5", secondaryTextHex: "#A7BDCB", accentHex: "#A3C5DE")
        default: return ThemePalette(id: "sage", displayName: L10n.text("Sage"), backgroundHex: "#253029", surfaceHex: "#303E35", primaryTextHex: "#E5EFE5", secondaryTextHex: "#ADC4AE", accentHex: "#B2D1B0")
        }
    }
}

struct WorkspaceWidgetView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let kind: ToolKind
    let document: WorkspaceDocument
    var paletteID: String = "sage"
    var radius: Double = 18
    var isLarge = false
    var referenceDate: Date? = nil
    var onTask: ((UUID, Bool) -> Void)?
    var onFocus: (() -> Void)?
    var onHabit: ((UUID) -> Void)?
    var options: WidgetOptions?
    private var style: WidgetOptions { options ?? WidgetOptions() }
    @Environment(\.colorScheme) private var scheme
    private var palette: ThemePalette { style.theme(palette: paletteID, dark: scheme == .dark) }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if style.showHeader { HStack(spacing: 6) {
                Image(systemName: kind.symbol)
                Text(style.title.isEmpty ? (kind == .clock ? clockCity.uppercased(with: localization.locale) : kind.title.uppercased(with: localization.locale)) : style.title.uppercased(with: localization.locale))
                    .tracking(1.1)
                Spacer(minLength: 0)
            }
            .font(.system(size: (10) * style.fontScale, weight: .semibold))
            .foregroundStyle(palette.secondaryText) }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(18)
        .foregroundStyle(palette.primaryText)
        .background {
            switch style.backdrop { case .solid: palette.background; case .glass: Rectangle().fill(.regularMaterial); case .transparent: Color.clear }
        }.clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(palette.subtleBorder, lineWidth: style.borderWidth))
        .tint(palette.accent).opacity(style.opacity)
    }
    private var clockCity: String {
        (style.timeZone ?? document.preferences.clockTimeZone).split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? L10n.text("Local time")
    }
    @ViewBuilder private var content: some View {
        switch kind {
        case .clock:
            if let mascotType = MascotClockType.from(symbol: style.symbol) {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let clockDate = referenceDate ?? context.date
                    MascotClockView(
                        date: clockDate,
                        mascotType: mascotType,
                        palette: palette,
                        isLarge: isLarge,
                        timeZoneIdentifier: style.timeZone ?? document.preferences.clockTimeZone,
                        showDigitalTime: true,
                        interactive: true
                    )
                }
            } else {
                TimelineView(.everyMinute) { context in
                    let clockDate = referenceDate ?? context.date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(timeString(clockDate))
                            .font(.system(size: (isLarge ? 60 : 43) * style.fontScale, weight: .medium, design: style.typeface.design)).monospacedDigit()
                            .minimumScaleFactor(0.45).lineLimit(1)
                        Spacer(minLength: 0)
                        if document.preferences.showDate {
                            Text(dateString(clockDate, format: "EEEE"))
                                .font(.system(size: (12) * style.fontScale, weight: .medium))
                            Text(dateString(clockDate, format: "d MMMM"))
                                .font(.system(size: (11) * style.fontScale)).foregroundStyle(palette.secondaryText)
                        }
                    }
                }
            }
        case .focus:
            VStack(alignment: .leading, spacing: 10) {
                if let end = document.focus.endDate, end > Date() {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.system(size: (isLarge ? 58 : 40) * style.fontScale, weight: .medium, design: style.typeface.design)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                } else {
                    Text(focusTime).font(.system(size: (isLarge ? 58 : 40) * style.fontScale, weight: .medium, design: style.typeface.design)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                }
                Spacer(minLength: 0)
                HStack {
                    Text(document.focus.completed ? L10n.text("Session complete") : document.focus.phase == .work ? L10n.text("Deep work") : L10n.text("Break"))
                        .font(.system(size: (11) * style.fontScale)).foregroundStyle(palette.secondaryText).lineLimit(1)
                    Spacer(minLength: 0)
                    if let onFocus {
                        Button(action: onFocus) { Image(systemName: document.focus.isRunning ? "pause.fill" : "play.fill") }
                            .buttonStyle(.plain).accessibilityLabel(document.focus.isRunning ? L10n.text("Pause focus") : L10n.text("Start focus"))
                    }
                }
            }
        case .tasks:
            if document.tasks.isEmpty { empty(L10n.text("No tasks"), detail: L10n.text("Add tasks in Daily tools.")) }
            else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(document.tasks.sorted { !$0.completed && $1.completed }.prefix(isLarge ? 7 : 4)) { task in
                        Button { onTask?(task.id, !task.completed) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 7) {
                                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle").foregroundStyle(palette.accent)
                                Text(task.title).strikethrough(task.completed).lineLimit(1)
                            }
                            .font(.system(size: (12) * style.fontScale)).foregroundStyle(task.completed ? palette.secondaryText : palette.primaryText)
                        }
                        .buttonStyle(.plain).allowsHitTesting(onTask != nil)
                    }
                    Spacer(minLength: 0)
                    Text(L10n.format("%d of %d complete", document.tasks.filter(\.completed).count, document.tasks.count))
                        .font(.system(size: (10) * style.fontScale)).foregroundStyle(palette.secondaryText)
                }
            }
        case .countdown:
            TimelineView(.periodic(from: .now, by: 60)) { context in
                if countdown.title.isEmpty { empty(L10n.text("No countdown"), detail: L10n.text("Set an event and date.")) }
                else {
                    VStack(alignment: .leading, spacing: 7) {
                        let days = countdown.days(from: referenceDate ?? context.date)
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(abs(days))").font(.system(size: (isLarge ? 54 : 42) * style.fontScale, weight: .medium, design: style.typeface.design)).monospacedDigit()
                            Text(days < 0 ? L10n.text("days ago") : days == 1 ? L10n.text("day") : L10n.text("days")).font(.system(size: (14) * style.fontScale))
                        }.lineLimit(1).minimumScaleFactor(0.5)
                        Text(countdown.title).font(.system(size: (13) * style.fontScale, weight: .medium)).lineLimit(2)
                        Spacer(minLength: 0)
                        Text(countdown.date, format: .dateTime.day().month(.abbreviated).year())
                            .font(.system(size: (10) * style.fontScale)).foregroundStyle(palette.secondaryText)
                    }
                }
            }
        case .notes:
            if (style.bodyText ?? document.note).isEmpty { empty(L10n.text("Empty note"), detail: L10n.text("Edit this note in iGet.")) }
            else { Text((style.bodyText ?? document.note)).font(.system(size: (isLarge ? 19 : 15) * style.fontScale, weight: .medium)).lineSpacing(4).frame(maxHeight: .infinity, alignment: .topLeading).clipped() }
        case .calendar:
            TimelineView(.periodic(from: .now, by: 60)) { context in MonthGrid(date: referenceDate ?? context.date, accent: palette.accent, emphasized: isLarge) }
        case .habits:
            if document.habits.isEmpty { empty(L10n.text("No habits"), detail: L10n.text("Add habits in Daily tools.")) }
            else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(document.habits.prefix(isLarge ? 7 : 4)) { habit in
                        Button { onHabit?(habit.id) } label: {
                            HStack {
                                Image(systemName: habit.done() ? "checkmark.circle.fill" : "circle").foregroundStyle(palette.accent)
                                Text(habit.title).lineLimit(1)
                                Spacer(minLength: 0)
                                Text(L10n.count(habit.streak(), one: "%d day", other: "%d days")).foregroundStyle(palette.secondaryText)
                            }.font(.system(size: (12) * style.fontScale))
                        }.buttonStyle(.plain).allowsHitTesting(onHabit != nil)
                    }
                    Spacer(minLength: 0)
                    Text(L10n.format("%d / %d today", document.habits.filter { $0.done() }.count, document.habits.count))
                        .font(.system(size: (10) * style.fontScale)).foregroundStyle(palette.secondaryText)
                }
            }
        case .battery: empty(L10n.text("Battery"), detail: L10n.text("Charge level and power source."))
        case .system: empty(L10n.text("System monitor"), detail: L10n.text("CPU and memory usage."))
        default: empty(kind.title, detail: kind.summary)
        }
    }
    private var countdown: LocalCountdown {
        var value = document.countdown
        if let date = style.countdownDate { value.date = date }
        if let title = style.countdownTitle { value.title = title }
        return value
    }
    private var focusTime: String {
        let seconds = Int(document.focus.seconds())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    private func timeString(_ date: Date) -> String {
        let format = DateFormatter()
        format.timeZone = TimeZone(identifier: (style.timeZone ?? document.preferences.clockTimeZone))
        format.locale = localization.locale
        format.dateFormat = document.preferences.use24Hour ? "HH:mm" : "h:mm a"
        return format.string(from: date)
    }
    private func dateString(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: (style.timeZone ?? document.preferences.clockTimeZone))
        formatter.locale = localization.locale
        formatter.setLocalizedDateFormatFromTemplate(format)
        return formatter.string(from: date)
    }
    private func empty(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: (16) * style.fontScale, weight: .medium)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(detail).font(.system(size: (11) * style.fontScale)).foregroundStyle(palette.secondaryText).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MonthGrid: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let date: Date
    let accent: Color
    var expanded = false
    var emphasized = false
    private var calendar: Calendar { var calendar = Calendar.current; calendar.locale = localization.locale; return calendar }
    private var start: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date }
    private var offset: Int { (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7 }
    private var days: Int { calendar.range(of: .day, in: .month, for: date)?.count ?? 30 }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(date, format: .dateTime.month(.wide).year()).font(.system(size: expanded ? 22 : emphasized ? 17 : 12, weight: .semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: expanded ? 12 : emphasized ? 5 : 2) {
                ForEach(0..<7, id: \.self) { index in
                    Text(calendar.veryShortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7])
                        .font(.system(size: expanded ? 12 : emphasized ? 10 : 8, weight: .medium)).foregroundStyle(.secondary)
                }
                ForEach(0..<(offset + days), id: \.self) { index in
                    if index < offset { Text(" ").font(.system(size: 9)) }
                    else {
                        let day = index - offset + 1
                        let isToday = calendar.isDate(date, equalTo: Date(), toGranularity: .month) && day == calendar.component(.day, from: Date())
                        Text("\(day)").font(.system(size: expanded ? 16 : emphasized ? 12 : 9, weight: isToday ? .bold : .regular))
                            .frame(maxWidth: .infinity).padding(.vertical, expanded ? 7 : emphasized ? 3 : 0.5)
                            .background(isToday ? accent.opacity(0.25) : .clear, in: Circle())
                    }
                }
            }
        }
    }
}
