import SwiftUI

/// A generic rounded card container with soft styling
struct SignalCard<Content: View>: View {
    var hasBorder: Bool = true
    var hasShadow: Bool = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(22)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(hasBorder ? Color.line : .clear, lineWidth: 1)
        )
        .shadow(
            color: hasShadow ? Color(hex: "3C2832").opacity(0.12) : .clear,
            radius: 20,
            y: 12
        )
    }
}

#Preview {
    SignalCard {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEW SIGNAL")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.ink2)
            Text("上传聊天截图")
                .font(.system(size: 17, weight: .semibold))
        }
    }
    .padding()
    .background(Color.bgPage)
}
