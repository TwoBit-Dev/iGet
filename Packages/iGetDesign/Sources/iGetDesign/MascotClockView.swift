import SwiftUI
import AVFoundation

public enum MascotClockType: String, CaseIterable, Identifiable {
    case minnie = "minnie"
    case cat = "cat"
    case bunny = "bunny"
    case bear = "bear"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .minnie: return L10n.text("Minnie Mouse (Apple Watch)")
        case .cat: return L10n.text("Cat mascot (Mimi)")
        case .bunny: return L10n.text("Bunny mascot (Bibi)")
        case .bear: return L10n.text("Bear mascot (Kuma)")
        }
    }

    public var emoji: String {
        switch self {
        case .minnie: return "🎀"
        case .cat: return "🐱"
        case .bunny: return "🐰"
        case .bear: return "🐻"
        }
    }

    public static func from(symbol: String) -> MascotClockType? {
        switch symbol.lowercased() {
        case "minnie", "mascot-minnie", "mouse", "apple-watch", "applewatch", "🎀", "🐭": return .minnie
        case "cat", "mascot-cat", "🐈", "🐱": return .cat
        case "bunny", "mascot-bunny", "🐰": return .bunny
        case "bear", "mascot-bear", "🐻": return .bear
        case "mascot": return .minnie
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
    public var showDigitalTime: Bool = false
    public var showAppleWatchCase: Bool = true
    public var interactive: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCheering = false
    @State private var heartOpacity: Double = 0
    @State private var heartOffset: CGFloat = 0

    private static let speechSynthesizer = AVSpeechSynthesizer()

    private var calendar: Calendar {
        var cal = Calendar.current
        if let timeZoneIdentifier, let tz = TimeZone(identifier: timeZoneIdentifier) {
            cal.timeZone = tz
        }
        return cal
    }

    public init(
        date: Date,
        mascotType: MascotClockType = .minnie,
        palette: ThemePalette,
        isLarge: Bool = false,
        timeZoneIdentifier: String? = nil,
        showDigitalTime: Bool = false,
        showAppleWatchCase: Bool = true,
        interactive: Bool = true
    ) {
        self.date = date
        self.mascotType = mascotType
        self.palette = palette
        self.isLarge = isLarge
        self.timeZoneIdentifier = timeZoneIdentifier
        self.showDigitalTime = showDigitalTime
        self.showAppleWatchCase = showAppleWatchCase
        self.interactive = interactive
    }

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            if mascotType == .minnie && showAppleWatchCase {
                appleWatchCase(width: w, height: h) { dialSize in
                    watchDialContent(size: dialSize)
                }
            } else {
                let dialSize = min(w, h)
                watchDialContent(size: dialSize)
                    .frame(width: w, height: h)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            triggerCheer()
        }
    }

    // MARK: - Watch Dial Content

    private func watchDialContent(size: CGFloat) -> some View {
        ZStack {
            // 1. Dial Background & Numbers
            dialBackground(size: size)

            // 2. City or Header Label
            if let cityName = resolvedCityName, mascotType != .minnie {
                VStack {
                    Text(cityName.uppercased(with: localization.locale))
                        .font(.system(size: max(8, size * 0.05), weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(palette.secondaryText)
                        .padding(.top, size * 0.12)
                    Spacer()
                }
            }

            // 3. Floating Interactive Cheer Heart/Sparkle
            if heartOpacity > 0 {
                Text(mascotType == .minnie ? "💖" : "✨")
                    .font(.system(size: size * 0.16))
                    .offset(y: -size * 0.28 + heartOffset)
                    .opacity(heartOpacity)
            }

            // 4. Center Mascot Body & Head
            mascotFigure(size: size)
                .scaleEffect(isCheering ? 1.12 : 1.0)
                .offset(y: isCheering ? -5 : 0)

            // 5. Clock Hands (The Mascot's Arms!)
            mascotArms(size: size)

            // 6. Center Pin / Bowtie
            centerPin(size: size)

            // 7. Optional Digital Time Readout Pill
            if showDigitalTime {
                VStack {
                    Spacer()
                    Text(digitalTimeString)
                        .font(.system(size: max(9, size * 0.065), weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(mascotType == .minnie ? Color.white : palette.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (mascotType == .minnie ? Color.black.opacity(0.8) : palette.background.opacity(0.85)),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                mascotType == .minnie ? Color.white.opacity(0.2) : palette.subtleBorder,
                                lineWidth: 1
                            )
                        )
                        .padding(.bottom, size * 0.08)
                }
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Apple Watch Case

    private func appleWatchCase<Content: View>(width: CGFloat, height: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) -> some View {
        let caseW = min(width, height * 0.88)
        let caseH = caseW / 0.88
        let cornerRadius = caseW * 0.24
        let screenW = caseW * 0.84
        let screenH = caseH * 0.84
        let screenRadius = cornerRadius * 0.72
        let dialContentSize = min(screenW, screenH)

        return ZStack {
            // Digital Crown & Side Button on the right
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: caseH * 0.07) {
                    // Digital Crown with ridges
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.86), Color(white: 0.52), Color(white: 0.76)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: caseW * 0.045, height: caseH * 0.16)
                        .overlay(
                            VStack(spacing: 2) {
                                ForEach(0..<5) { _ in
                                    Rectangle().fill(Color(white: 0.35)).frame(height: 1)
                                }
                            }
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
                        .offset(y: -caseH * 0.11)

                    // Side Button
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.82), Color(white: 0.62)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: caseW * 0.022, height: caseH * 0.13)
                        .offset(y: -caseH * 0.03)
                }
                .offset(x: caseW * 0.02)
            }
            .frame(width: caseW, height: caseH)

            // Silver Aluminum Watch Body
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.94),
                            Color(white: 0.76),
                            Color(white: 0.86),
                            Color(white: 0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color(white: 0.58)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .frame(width: caseW, height: caseH)

            // OLED Screen Frame
            RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                .fill(Color.black)
                .frame(width: screenW, height: screenH)
                .overlay(
                    RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .overlay(
                    content(dialContentSize)
                        .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
                )
        }
        .frame(width: width, height: height)
    }

    // MARK: - Tap Reaction & Voice Announcement

    private func triggerCheer() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.52)) {
            isCheering = true
            heartOpacity = 1.0
            heartOffset = -18
        }
        speakCurrentTime()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.28)) {
                isCheering = false
                heartOpacity = 0.0
                heartOffset = -30
            }
        }
    }

    private func speakCurrentTime() {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let hour12 = hour % 12 == 0 ? 12 : hour % 12

        let text: String
        let voiceLang: String

        if localization.locale.identifier.starts(with: "tr") {
            if minute == 0 {
                text = "Saat tam \(hour12)!"
            } else {
                text = "Saat \(hour12)'i \(minute) geçiyor!"
            }
            voiceLang = "tr-TR"
        } else if localization.locale.identifier.starts(with: "de") {
            if minute == 0 {
                text = "Es ist genau \(hour12) Uhr!"
            } else {
                text = "Es ist \(hour12) Uhr \(minute)!"
            }
            voiceLang = "de-DE"
        } else {
            if minute == 0 {
                text = "It's \(hour12) o'clock!"
            } else {
                text = "It's \(hour12):\(String(format: "%02d", minute))!"
            }
            voiceLang = "en-US"
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLang)
        utterance.pitchMultiplier = 1.35 // Cheerful higher pitch like Minnie!
        utterance.rate = 0.50
        Self.speechSynthesizer.stopSpeaking(at: .immediate)
        Self.speechSynthesizer.speak(utterance)
    }

    // MARK: - Dial Background & Markers

    @ViewBuilder
    private func dialBackground(size: CGFloat) -> some View {
        if mascotType == .minnie {
            minnieDialBackground(size: size)
        } else {
            classicMascotDialBackground(size: size)
        }
    }

    private func minnieDialBackground(size: CGFloat) -> some View {
        ZStack {
            // Deep OLED black background with central radial spotlight
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(Color.black)

            // Radial spotlight behind Minnie
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.32),
                            Color(white: 0.16),
                            Color.black
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.44
                    )
                )
                .frame(width: size * 0.88, height: size * 0.88)

            // Apple Watch Watch Face Numerals: 12, 1, 2, 3, 4, 8, 9, 10, 11
            // (5, 6, 7 are omitted behind Minnie's dress & shoes)
            let numerals: [Int] = [12, 1, 2, 3, 4, 8, 9, 10, 11]
            ForEach(numerals, id: \.self) { hour in
                let angle = Double(hour) * 30.0 * .pi / 180.0
                let radius = size * 0.395
                let x = radius * sin(angle)
                let y = -radius * cos(angle)

                Text("\(hour)")
                    .font(.system(size: max(11, size * 0.088), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.8), radius: 2, y: 1)
                    .offset(x: x, y: y)
            }
        }
    }

    private func classicMascotDialBackground(size: CGFloat) -> some View {
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

    // MARK: - Mascot Figure

    @ViewBuilder
    private func mascotFigure(size: CGFloat) -> some View {
        if mascotType == .minnie {
            minnieFigure(size: size)
        } else {
            classicMascotFigure(size: size)
        }
    }

    // MARK: - Authentic Minnie Mouse Figure

    private func minnieFigure(size: CGFloat) -> some View {
        let sec = Double(calendar.component(.second, from: date))
        let isTapping = !reduceMotion && (Int(sec) % 2 == 0)

        return ZStack {
            // 1. Daisy Flower reaching up to 12
            minnieDaisyFlower(size: size)
                .offset(x: size * 0.06, y: -size * 0.23)

            // 2. Ears
            ZStack {
                // Left Ear
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.165, height: size * 0.165)
                    .offset(x: -size * 0.10, y: -size * 0.17)

                // Right Ear
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.165, height: size * 0.165)
                    .offset(x: size * 0.10, y: -size * 0.17)
            }

            // 3. Red Pillbox Hat
            ZStack {
                Ellipse()
                    .fill(Color(hex: "#E52535"))
                    .frame(width: size * 0.13, height: size * 0.08)
                    .overlay(
                        Ellipse()
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(10))
            }
            .offset(x: size * 0.025, y: -size * 0.155)

            // 4. Head & Face
            ZStack {
                // Black Head Dome
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .offset(y: -size * 0.075)

                // Cream Face Mask (Vintage 1930s Mickey/Minnie muzzle mask)
                ZStack {
                    // Cheeks / Snout base
                    Capsule()
                        .fill(Color(hex: "#FFFDF6"))
                        .frame(width: size * 0.21, height: size * 0.13)
                        .offset(y: -size * 0.045)

                    // Eye Mask / Forehead arches
                    HStack(spacing: 2) {
                        Capsule().fill(Color(hex: "#FFFDF6")).frame(width: size * 0.085, height: size * 0.11)
                        Capsule().fill(Color(hex: "#FFFDF6")).frame(width: size * 0.085, height: size * 0.11)
                    }
                    .offset(y: -size * 0.09)

                    // Vintage Eyes with 3 Delicate Eyelashes!
                    HStack(spacing: size * 0.022) {
                        minnieEye(size: size, isLeft: true)
                        minnieEye(size: size, isLeft: false)
                    }
                    .offset(y: -size * 0.082)

                    // Cute Black Button Nose
                    Ellipse()
                        .fill(Color.black)
                        .frame(width: size * 0.048, height: size * 0.034)
                        .offset(y: -size * 0.042)

                    // Cheerful Smile with Red Tongue
                    minnieSmile(size: size)
                        .offset(y: -size * 0.015)
                }
            }

            // 5. Torso & Red Polka-Dot Skirt
            ZStack {
                // Black Waist
                Capsule()
                    .fill(Color.black)
                    .frame(width: size * 0.08, height: size * 0.06)
                    .offset(y: size * 0.06)

                // Red Polka-Dot Skirt
                minniePolkaDotSkirt(size: size)
                    .offset(y: size * 0.12)
            }

            // 6. Black Legs & Yellow Cartoon Shoes
            HStack(spacing: size * 0.07) {
                // Left Leg & Yellow High-Heel Shoe (Taps to the seconds!)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 4, height: size * 0.07)
                    minnieYellowShoe(size: size, isLeft: true)
                }
                .offset(y: isTapping ? -4 : 0)
                .rotationEffect(.degrees(isTapping ? -12 : 0), anchor: .top)

                // Right Leg & Yellow High-Heel Shoe
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 4, height: size * 0.07)
                    minnieYellowShoe(size: size, isLeft: false)
                }
            }
            .offset(y: size * 0.20)
        }
    }

    // MARK: - Minnie Details (Flower, Eyes, Smile, Skirt, Shoes)

    private func minnieDaisyFlower(size: CGFloat) -> some View {
        ZStack {
            // Thin Stem
            Rectangle()
                .fill(Color(hex: "#386641"))
                .frame(width: 2, height: size * 0.07)
                .rotationEffect(.degrees(-8))

            // White Daisy Petals
            ForEach(0..<5) { i in
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.018, height: size * 0.038)
                    .offset(y: -size * 0.022)
                    .rotationEffect(.degrees(Double(i) * 72.0))
            }

            // Yellow Center Pistil
            Circle()
                .fill(Color(hex: "#FFD200"))
                .frame(width: size * 0.024, height: size * 0.024)
        }
    }

    private func minnieEye(size: CGFloat, isLeft: Bool) -> some View {
        ZStack(alignment: .top) {
            // 3 Eyelashes extending upward
            HStack(spacing: 2) {
                ForEach(0..<3) { lash in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: size * 0.02)
                        .rotationEffect(.degrees(Double(lash - 1) * 18.0 + (isLeft ? -10 : 10)))
                }
            }
            .offset(y: -size * 0.012)

            // Eye Oval
            ZStack(alignment: isLeft ? .bottomTrailing : .bottomLeading) {
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.040, height: size * 0.072)
                    .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1))

                // Black Pupil with Vintage Sparkle
                ZStack(alignment: .topTrailing) {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: size * 0.026, height: size * 0.048)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.009, height: size * 0.009)
                        .offset(x: -1, y: 1)
                }
                .offset(x: isLeft ? -1 : 1, y: -2)
            }
        }
    }

    private func minnieSmile(size: CGFloat) -> some View {
        ZStack {
            // Open smiling mouth curve
            Circle()
                .trim(from: 0.1, to: 0.5)
                .fill(Color(hex: "#1A0000"))
                .frame(width: size * 0.13, height: size * 0.08)
                .overlay(
                    // Red tongue inside
                    Circle()
                        .fill(Color(hex: "#E52535"))
                        .frame(width: size * 0.065, height: size * 0.04)
                        .offset(y: size * 0.015)
                )
                .overlay(
                    Circle()
                        .trim(from: 0.1, to: 0.5)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: size * 0.13, height: size * 0.08)
                )
        }
    }

    private func minniePolkaDotSkirt(size: CGFloat) -> some View {
        ZStack {
            // Red Skirt Shape
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(Color(hex: "#E52535"))
                .frame(width: size * 0.23, height: size * 0.12)
                .overlay(
                    // White Scalloped Ruffles at bottom
                    HStack(spacing: -1) {
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(Color.white)
                                .frame(width: size * 0.048, height: size * 0.048)
                        }
                    }
                    .offset(y: size * 0.055)
                    .mask(
                        RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                            .frame(width: size * 0.23, height: size * 0.12)
                    )
                )

            // Polka Dots on the skirt!
            VStack(spacing: size * 0.018) {
                HStack(spacing: size * 0.035) {
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                }
                HStack(spacing: size * 0.032) {
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                    Circle().fill(Color.white).frame(width: size * 0.026, height: size * 0.026)
                }
            }
        }
    }

    private func minnieYellowShoe(size: CGFloat, isLeft: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Yellow shoe body
            Capsule()
                .fill(Color(hex: "#FFD200"))
                .frame(width: size * 0.088, height: size * 0.042)
                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1.5))

            // Shoe Collar / Vamp opening
            Ellipse()
                .fill(Color.black)
                .frame(width: size * 0.035, height: size * 0.02)
                .offset(x: size * 0.015, y: -size * 0.015)

            // Cute Small Heel
            Rectangle()
                .fill(Color(hex: "#FFD200"))
                .frame(width: size * 0.016, height: size * 0.02)
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
                .offset(x: size * 0.01, y: size * 0.015)
        }
        .rotationEffect(.degrees(isLeft ? -8 : 8))
    }

    // MARK: - Classic Mascot Figure (Cat, Bunny, Bear)

    private func classicMascotFigure(size: CGFloat) -> some View {
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
                    HStack(spacing: size * 0.09) {
                        Text("^").font(.system(size: size * 0.08, weight: .bold)).foregroundStyle(palette.primaryText)
                        Text("^").font(.system(size: size * 0.08, weight: .bold)).foregroundStyle(palette.primaryText)
                    }
                    .offset(y: -size * 0.01)
                } else {
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

                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: size * 0.10, height: size * 0.10)
            }
            .offset(y: -size * 0.02)

            // Feet (Rhythmic foot tap)
            HStack(spacing: size * 0.06) {
                Capsule()
                    .fill(palette.primaryText.opacity(0.8))
                    .frame(width: size * 0.07, height: size * 0.035)

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
        case .minnie:
            EmptyView()
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
        case .minnie:
            EmptyView()
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
        case .minnie: return Color.black
        case .cat: return Color(hex: "#FFFDF9")
        case .bunny: return Color(hex: "#FFFFFF")
        case .bear: return Color(hex: "#E8D8C8")
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
            // HOUR ARM (Shorter arm pointing to hour)
            if mascotType == .minnie {
                minnieGloveArm(
                    length: size * 0.26,
                    thickness: size * 0.030,
                    isPointing: false,
                    size: size
                )
                .rotationEffect(.degrees(hourAngle), anchor: .bottom)
                .offset(y: -size * 0.13)
            } else {
                clockArm(
                    length: size * 0.28,
                    thickness: size * 0.032,
                    pawRadius: size * 0.042,
                    color: palette.primaryText
                )
                .rotationEffect(.degrees(hourAngle), anchor: .bottom)
                .offset(y: -size * 0.14)
            }

            // MINUTE ARM (Longer arm pointing to minute)
            if mascotType == .minnie {
                minnieGloveArm(
                    length: size * 0.37,
                    thickness: size * 0.026,
                    isPointing: true,
                    size: size
                )
                .rotationEffect(.degrees(minuteAngle), anchor: .bottom)
                .offset(y: -size * 0.185)
            } else {
                clockArm(
                    length: size * 0.38,
                    thickness: size * 0.026,
                    pawRadius: size * 0.038,
                    color: palette.accent
                )
                .rotationEffect(.degrees(minuteAngle), anchor: .bottom)
                .offset(y: -size * 0.19)
            }
        }
    }

    // Authentic Minnie Cartoon Glove Arm
    private func minnieGloveArm(length: CGFloat, thickness: CGFloat, isPointing: Bool, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            // White Cartoon Glove with 4 fingers and black dart ribs
            ZStack {
                // Glove Palm
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.075, height: size * 0.075)
                    .overlay(Circle().strokeBorder(Color.black, lineWidth: 1.5))

                if isPointing {
                    // Outstretched pointing index finger
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.022, height: size * 0.048)
                        .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1.2))
                        .offset(y: -size * 0.028)

                    // Thumb
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.020, height: size * 0.032)
                        .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1.2))
                        .rotationEffect(.degrees(-45))
                        .offset(x: -size * 0.022, y: -size * 0.005)
                } else {
                    // Open Palm Fingers
                    HStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            Capsule()
                                .fill(Color.white)
                                .frame(width: size * 0.018, height: size * 0.032)
                                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1))
                                .offset(y: -size * 0.016)
                        }
                    }

                    // Thumb
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.018, height: size * 0.028)
                        .overlay(Capsule().strokeBorder(Color.black, lineWidth: 1))
                        .rotationEffect(.degrees(-50))
                        .offset(x: -size * 0.024, y: 0)
                }

                // 3 Black Dart lines on the back of the glove
                HStack(spacing: 2.5) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1.2, height: size * 0.020)
                    }
                }
                .offset(y: size * 0.005)
            }
            .shadow(color: Color.black.opacity(0.35), radius: 3, y: 1.5)

            // Black Arm Sleeve
            RoundedRectangle(cornerRadius: thickness / 2)
                .fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: thickness / 2).strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                .frame(width: thickness, height: max(10, length - size * 0.075))
        }
        .frame(height: length)
    }

    private func clockArm(length: CGFloat, thickness: CGFloat, pawRadius: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.white)
                .frame(width: pawRadius * 2, height: pawRadius * 2)
                .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)

            RoundedRectangle(cornerRadius: thickness / 2)
                .fill(color)
                .frame(width: thickness, height: length - pawRadius)
        }
        .frame(height: length)
    }

    private func centerPin(size: CGFloat) -> some View {
        Circle()
            .fill(mascotType == .minnie ? Color.black : palette.accent)
            .frame(width: size * 0.055, height: size * 0.055)
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
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
