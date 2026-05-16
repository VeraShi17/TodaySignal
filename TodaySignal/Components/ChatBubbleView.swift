import SwiftUI

struct ChatBubbleView: View {
    let bubble: ChatBubble
    var idolSide: BubbleSide = .left
    var showEditControls: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var isLeft: Bool { bubble.side == .left }
    private var isIdol: Bool { bubble.side == idolSide }

    var body: some View {
        HStack {
            if !isLeft { Spacer(minLength: 60) }

            VStack(alignment: isLeft ? .leading : .trailing, spacing: 4) {
                if isIdol {
                    Text("IDOL · 对方")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.pink)
                        .tracking(0.4)
                        .padding(.leading, 4)
                }

                HStack(alignment: .top, spacing: 6) {
                    if !isLeft && showEditControls {
                        editButtons
                    }

                    bubbleContent

                    if isLeft && showEditControls {
                        editButtons
                    }
                }
            }

            if isLeft { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if bubble.type == .image {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FBEAE0"), Color(hex: "F8D9D0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 110)
                .overlay(
                    Text("[图片]")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "B58474"))
                )
        } else {
            Text(bubble.text)
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isLeft ? Color.white : Color.pinkTint
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isLeft ? 6 : 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: isLeft ? 18 : 6
                    )
                    .stroke(isIdol ? Color.pink : Color.line, lineWidth: isIdol ? 1.5 : 1)
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isLeft ? 6 : 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: isLeft ? 18 : 6
                    )
                )
                .shadow(color: Color(hex: "3C2832").opacity(0.04), radius: 1, y: 1)
        }
    }

    @ViewBuilder
    private var editButtons: some View {
        VStack(spacing: 6) {
            Button(action: { onEdit?() }) {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .frame(width: 22, height: 22)
                    .background(.white)
                    .foregroundStyle(Color.inkMute)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.line, lineWidth: 1))
            }
            Button(action: { onDelete?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .frame(width: 22, height: 22)
                    .background(.white)
                    .foregroundStyle(Color.inkMute)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.line, lineWidth: 1))
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubbleView(
            bubble: ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해? ㅋㅋ"),
            idolSide: .left,
            showEditControls: true
        )
        ChatBubbleView(
            bubble: ChatBubble(side: .right, speakerRole: .user, text: "나 지금 공부 중이야"),
            idolSide: .left
        )
        ChatBubbleView(
            bubble: ChatBubble(side: .left, speakerRole: .idol, type: .image, text: "[图片]"),
            idolSide: .left
        )
    }
    .padding()
    .background(Color.bgPage)
}
