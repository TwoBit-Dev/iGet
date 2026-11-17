import SwiftUI

public enum MascotClockType: String, CaseIterable, Identifiable {
    case cat = "cat"
    case bunny = "bunny"
    case bear = "bear"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cat: return L10n.text("Cat mascot")
        case .bunny: return L10n.text("Bunny mascot")
        case .bear: return L10n.text("Bear mascot")
        }
    }

    public var emoji: String {
        switch self {
        case .cat: return "🐱"
        case .bunny: return "🐰"
        case .bear: return "🐻"
        }
    }

    public static func from(symbol: String) -> MascotClockType? {
        switch symbol.lowercased() {
        case "cat", "mascot-cat", "🐈", "🐱": return .cat
        case "bunny", "mascot-bunny", "🐰": return .bunny
        case "bear", "mascot-bear", "🐻": return .bear
        case "mascot": return .cat
        default: return nil
        }
    }
}

public struct MascotClockView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    public let date: Date
    public let mascotType: MascotClockType
    public let palette: ThemePalette
    public var isLarge: Bool = false
    public var timeZoneIdentifier: String? = nil
    public var showDigitalTime: Bool = true
    public var interactive: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCheering = false
    @State private var heartOpacity: Double = 0
    @State private var heartOffset: CGFloat = 0

    private var calendar: Calendar {
        var cal = Calendar.current
        if let timeZoneIdentifier, let tz = TimeZone(identifier: timeZoneIdentifier) {
            cal.timeZone = tz
        }
        return cal
    }

    public init(
        date: Date,
        mascotType: MascotClockType = .cat,
        palette: ThemePalette,
        isLarge: Bool = false,
        timeZoneIdentifier: String? = nil,
        showDigitalTime: Bool = true,
        interactive: Bool = true
    ) {
        self.date = date
        self.mascotType = mascotType
        self.palette = palette
        self.isLarge = isLarge
        self.timeZoneIdentifier = timeZoneIdentifier
        self.showDigitalTime = showDigitalTime
        self.interactive = interactive
    }

    public var body: some View {
        GeometryReader { proxy in
            let dialSize = min(proxy.size.width, proxy.size.height)

            ZStack {
                // 1. Dial Face & Hour Markers
                dialBackground(size: dialSize)

                // 2. City or Header Label
                if let cityName = resolvedCityName {
                    VStack {
                        Text(cityName.uppercased(with: localization.locale))
                            .font(.system(size: max(8, dialSize * 0.05), weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(palette.secondaryText)
                            .padding(.top, dialSize * 0.12)
                        Spacer()
                    }
                }

                // 3. Floating Interactive Cheer Heart/Sparkle
                if heartOpacity > 0 {
                    Text("💖")
                        .font(.system(size: dialSize * 0.16))
                        .offset(y: -dialSize * 0.28 + heartOffset)
                        .opacity(heartOpacity)
                }

                // 4. Center Mascot Body & Head
                mascotFigure(size: dialSize)
                    .scaleEffect(isCheering ? 1.14 : 1.0)
                    .offset(y: isCheering ? -6 : 0)

                // 5. Clock Hands (The Mascot's Arms!)
                mascotArms(size: dialSize)

                // 6. Center Pin / Bowtie
                centerPin(size: dialSize)

                // 7. Digital Time Readout Pill (Bottom)
                if showDigitalTime {
                    VStack {
                        Spacer()
                        Text(digitalTimeString)
                            .font(.system(size: max(9, dialSize * 0.065), weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(palette.primaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(palette.background.opacity(0.85), in: Capsule())
                            .overlay(Capsule().strokeBorder(palette.subtleBorder, lineWidth: 1))
                            .padding(.bottom, dialSize * 0.11)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Circle())
            .onTapGesture {
                guard interactive else { return }
                triggerCheer()
            }
        }
    }

    // MARK: - Tap Reaction

    private func triggerCheer() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.52)) {
            isCheering = true
            heartOpacity = 1.0
            heartOffset = -18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.28)) {
                isCheering = false
                heartOpacity = 0.0
                heartOffset = -30
            }
        }
    }

    // MARK: - Dial Background & Markers

    private func dialBackground(size: CGFloat) -> some View {
        ZStack {
            // Dial perimeter
            Circle()
                .fill(palette.surface.opacity(0.4))
                .overlay(Circle().strokeBorder(palette.subtleBorder, lineWidth: 1.5))

            // 12 Hour Dots & Numerals
            ForEach(1...12, id: \.self) { hour in
                let angle = Double(hour) * 30.0 * .pi / 180.0
                let radius = size * 0.41
                let x = radius * sin(angle)
                let y = -radius * cos(angle)

                Group {
                    if hour == 12 || hour == 3 || hour == 6 || hour == 9 {
                        Text("\(hour)")
                            .font(.system(size: max(9, size * 0.065), weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                    } else {
                        Circle()
                            .fill(palette.accent.opacity(0.75))
                            .frame(width: max(3.5, size * 0.026), height: max(3.5, size * 0.026))
                    }
                }
                .offset(x: x, y: y)
            }
        }
    }

    // MARK: - Center Mascot Figure

    private func mascotFigure(size: CGFloat) -> some View {
        let sec = Double(calendar.component(.second, from: date))
        let isTapping = !reduceMotion && (Int(sec) % 2 == 0)

        return VStack(spacing: 0) {
            // Ears
            mascotEars(size: size)

            // Head
            ZStack {
                Circle()
                    .fill(mascotBaseColor)
                    .frame(width: size * 0.30, height: size * 0.30)
                    .overlay(Circle().strokeBorder(palette.primaryText.opacity(0.12), lineWidth: 1))

                // Cheeks
                HStack(spacing: size * 0.16) {
                    Circle().fill(Color(hex: "#FF9EAA").opacity(0.45)).frame(width: size * 0.05, height: size * 0.05)
                    Circle().fill(Color(hex: "#FF9EAA").opacity(0.45)).frame(width: size * 0.05, height: size * 0.05)
                }
                .offset(y: size * 0.03)

                // Eyes (Blinks or Cheers)
                if isCheering {
                    // Joyful eyes: ^ ^
                    HStack(spacing: size * 0.09) {
                        Text("^").font(.system(size: size * 0.08, weight: .bold)).foregroundStyle(palette.primaryText)
                        Text("^").font(.system(size: size * 0.08, weight: .bold)).foregroundStyle(palette.primaryText)
                    }
                    .offset(y: -size * 0.01)
                } else {
                    // Regular eyes with sparkle
                    HStack(spacing: size * 0.10) {
                        mascotEye(size: size)
                        mascotEye(size: size)
                    }
                    .offset(y: -size * 0.01)
                }

                // Nose / Whiskers / Mouth
                mascotMouth(size: size)
                    .offset(y: size * 0.05)
            }

            // Body
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.06)
                    .fill(palette.accent.opacity(0.85))
                    .frame(width: size * 0.22, height: size * 0.16)

                // Cute belly or collar detail
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: size * 0.10, height: size * 0.10)
            }
            .offset(y: -size * 0.02)

            // Feet (Rhythmic foot tap like Minnie Mouse!)
            HStack(spacing: size * 0.06) {
                // Left Foot
                Capsule()
                    .fill(palette.primaryText.opacity(0.8))
                    .frame(width: size * 0.07, height: size * 0.035)

                // Right Foot (Taps up and down with seconds!)
                Capsule()
                    .fill(palette.primaryText.opacity(0.8))
                    .frame(width: size * 0.07, height: size * 0.035)
                    .offset(y: isTapping ? -3.5 : 0)
                    .rotationEffect(.degrees(isTapping ? -10 : 0), anchor: .bottom)
            }
            .offset(y: -size * 0.02)
        }
    }

    private func mascotEye(size: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(palette.primaryText)
                .frame(width: size * 0.045, height: size * 0.045)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.018, height: size * 0.018)
                .offset(x: -1, y: 1)
        }
    }

    @ViewBuilder
    private func mascotEars(size: CGFloat) -> some View {
        switch mascotType {
        case .cat:
            HStack(spacing: size * 0.14) {
                catEar(isLeft: true, size: size)
                catEar(isLeft: false, size: size)
            }
            .offset(y: size * 0.04)

        case .bunny:
            HStack(spacing: size * 0.08) {
                Capsule()
                    .fill(mascotBaseColor)
                    .frame(width: size * 0.06, height: size * 0.14)
                    .overlay(Capsule().fill(Color(hex: "#FFC2D1")).frame(width: size * 0.03, height: size * 0.10))
                    .rotationEffect(.degrees(-8), anchor: .bottom)

                Capsule()
                    .fill(mascotBaseColor)
                    .frame(width: size * 0.06, height: size * 0.14)
                    .overlay(Capsule().fill(Color(hex: "#FFC2D1")).frame(width: size * 0.03, height: size * 0.10))
                    .rotationEffect(.degrees(8), anchor: .bottom)
            }
            .offset(y: size * 0.05)

        case .bear:
            HStack(spacing: size * 0.17) {
                Circle()
                    .fill(mascotBaseColor)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .overlay(Circle().fill(palette.accent.opacity(0.3)).frame(width: size * 0.05, height: size * 0.05))

                Circle()
                    .fill(mascotBaseColor)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .overlay(Circle().fill(palette.accent.opacity(0.3)).frame(width: size * 0.05, height: size * 0.05))
            }
            .offset(y: size * 0.04)
        }
    }

    private func catEar(isLeft: Bool, size: CGFloat) -> some View {
        Triangle()
            .fill(mascotBaseColor)
            .frame(width: size * 0.08, height: size * 0.08)
            .overlay(
                Triangle()
                    .fill(Color(hex: "#FFC2D1"))
                    .frame(width: size * 0.045, height: size * 0.045)
            )
            .rotationEffect(.degrees(isLeft ? -15 : 15))
    }

    @ViewBuilder
    private func mascotMouth(size: CGFloat) -> some View {
        switch mascotType {
        case .cat:
            VStack(spacing: 1) {
                Triangle()
                    .fill(Color(hex: "#FF8E9E"))
                    .frame(width: size * 0.03, height: size * 0.02)
                    .rotationEffect(.degrees(180))
                Text("w")
                    .font(.system(size: size * 0.04, weight: .bold))
                    .foregroundStyle(palette.secondaryText)
            }
        case .bunny:
            Circle()
                .fill(Color(hex: "#FF8E9E"))
                .frame(width: size * 0.025, height: size * 0.025)
        case .bear:
            VStack(spacing: 1) {
                Circle()
                    .fill(palette.primaryText)
                    .frame(width: size * 0.035, height: size * 0.025)
                Rectangle()
                    .fill(palette.primaryText)
                    .frame(width: 1, height: size * 0.02)
            }
        }
    }

    private var mascotBaseColor: Color {
        switch mascotType {
        case .cat: return Color(hex: "#FFFDF9") // Warm cream white
        case .bunny: return Color(hex: "#FFFFFF") // Pure white
        case .bear: return Color(hex: "#E8D8C8") // Warm soft bear beige
        }
    }

    // MARK: - Clock Hands (The Mascot's Arms!)

    private func mascotArms(size: CGFloat) -> some View {
        let hour = Double(calendar.component(.hour, from: date) % 12)
        let minute = Double(calendar.component(.minute, from: date))
        let second = Double(calendar.component(.second, from: date))

        // Hour arm angle (30 degrees per hour + 0.5 deg per minute)
        let hourAngle = (hour + minute / 60.0) * 30.0

        // Minute arm angle (6 degrees per minute + 0.1 deg per second)
        let minuteAngle = (minute + second / 60.0) * 6.0

        return ZStack {
            // HOUR ARM (Shorter, thicker arm pointing to hour)
            clockArm(
                length: size * 0.28,
                thickness: size * 0.032,
                pawRadius: size * 0.042,
                color: palette.primaryText
            )
            .rotationEffect(.degrees(hourAngle), anchor: .bottom)
            .offset(y: -size * 0.14) // Centers bottom of arm at the shoulder

            // MINUTE ARM (Longer, sleeker arm pointing to minute)
            clockArm(
                length: size * 0.38,
                thickness: size * 0.026,
                pawRadius: size * 0.038,
                color: palette.accent
            )
            .rotationEffect(.degrees(minuteAngle), anchor: .bottom)
            .offset(y: -size * 0.19) // Centers bottom of arm at the shoulder
        }
    }

    private func clockArm(length: CGFloat, thickness: CGFloat, pawRadius: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            // White Paw Glove at tip!
            Circle()
                .fill(Color.white)
                .frame(width: pawRadius * 2, height: pawRadius * 2)
                .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)

            // Arm Sleeve
            RoundedRectangle(cornerRadius: thickness / 2)
                .fill(color)
                .frame(width: thickness, height: length - pawRadius)
        }
        .frame(height: length)
    }

    private func centerPin(size: CGFloat) -> some View {
        Circle()
            .fill(palette.accent)
            .frame(width: size * 0.065, height: size * 0.065)
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
    }

    // MARK: - Helpers

    private var digitalTimeString: String {
        let formatter = DateFormatter()
        if let timeZoneIdentifier, let tz = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = tz
        }
        formatter.locale = localization.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var resolvedCityName: String? {
        guard let timeZoneIdentifier else { return nil }
        return timeZoneIdentifier.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Triangle Shape for Ears

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
