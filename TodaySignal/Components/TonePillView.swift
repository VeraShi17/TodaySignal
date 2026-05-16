import SwiftUI

struct TonePillView: View {
    let text: String
    var kind: TonePillKind = .pink

    private var bgColor: Color {
        switch kind {
        case .pink: return Color(hex: "FCEAEF")
        case .coral: return Color(hex: "FFEFE7")
        case .lavender: return Color(hex: "EFEAFA")
        case .mint: return Color(hex: "E2F4EA")
        case .cream: return Color(hex: "FBEFD8")
        case .gray: return Color(hex: "F1ECEE")
        }
    }

    private var fgColor: Color {
        switch kind {
        case .pink: return Color(hex: "C04D6A")
        case .coral: return Color(hex: "C8633F")
        case .lavender: return Color(hex: "7860B3")
        case .mint: return Color(hex: "3F8F66")
        case .cream: return Color(hex: "A77839")
        case .gray: return Color(hex: "776975")
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background(bgColor)
            .foregroundStyle(fgColor)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: 8) {
        TonePillView(text: "亲近随意", kind: .pink)
        TonePillView(text: "可爱 / 撒娇", kind: .coral)
        TonePillView(text: "安慰 / 关心", kind: .lavender)
        TonePillView(text: "普通陈述", kind: .gray)
    }
    .padding()
}
