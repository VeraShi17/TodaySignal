import SwiftUI

// MARK: - App Color Palette (from design reference styles.css)

extension Color {
    // Backgrounds
    static let bgPage = Color(hex: "FAF4EE")       // warm cream
    static let bgCard = Color.white
    static let bgElev = Color(hex: "FFF8F3")
    static let bgSoft = Color(hex: "FDEEF1")        // very soft pink wash
    static let bgMint = Color(hex: "E8F6EE")
    static let bgLavender = Color(hex: "EFEAFA")

    // Brand accents
    static let pink = Color(hex: "F58CA0")           // primary CTA
    static let pinkDeep = Color(hex: "E97089")
    static let pinkSoft = Color(hex: "FFD8E1")
    static let pinkTint = Color(hex: "FCEAEF")
    static let coral = Color(hex: "FFA08A")
    static let lavender = Color(hex: "B8A5E0")
    static let lavenderSoft = Color(hex: "E0D6F5")
    static let mint = Color(hex: "6FCFA8")
    static let mintSoft = Color(hex: "C9EBD9")
    static let amber = Color(hex: "F2B86A")

    // Text
    static let ink = Color(hex: "2D2330")
    static let ink2 = Color(hex: "4E3F4A")
    static let inkMute = Color(hex: "8A7B85")
    static let inkFaint = Color(hex: "B8AAB2")

    // Strokes
    static let line = Color(hex: "F0E6E0")
    static let line2 = Color(hex: "EADDD3")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
