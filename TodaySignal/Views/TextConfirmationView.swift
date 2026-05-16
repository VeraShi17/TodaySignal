import SwiftUI

struct TextConfirmationView: View {
    @Environment(AppState.self) private var appState
    var onAnalyze: () -> Void
    var onBack: () -> Void

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Info banner
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.pinkDeep)
                            .padding(.top, 1)

                        Text("请检查 OCR 识别结果。你可以修改、删除气泡，或标记哪一侧是对方。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: "7A4A55"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.bgSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 16)

                    // Chat bubbles
                    VStack(spacing: 10) {
                        ForEach(appState.chatBubbles) { bubble in
                            ChatBubbleView(
                                bubble: bubble,
                                idolSide: appState.idolSide,
                                showEditControls: true,
                                onDelete: {
                                    withAnimation {
                                        appState.chatBubbles.removeAll { $0.id == bubble.id }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Fallback hint
                    HStack {
                        Text("气泡识别不太准确？")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                        Text("切换为逐行文本")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color.pinkDeep)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.line2, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 18)

                    Spacer().frame(height: 240)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
            }

            // Bottom panel
            VStack(spacing: 0) {
                Divider()

                VStack(alignment: .leading, spacing: 14) {
                    Text("哪一侧是 IDOL / 对方？")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color.ink2)
                        .tracking(0.4)

                    // Side selector
                    HStack(spacing: 0) {
                        ForEach([BubbleSide.left, .right], id: \.self) { side in
                            let isSelected = side == appState.idolSide
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { appState.idolSide = side } }) {
                                HStack(spacing: 6) {
                                    Text(side == .left ? "← 左侧" : "右侧 →")
                                        .font(.system(size: 14, weight: .semibold))
                                    if isSelected {
                                        Text("IDOL")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Color.pink)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(isSelected ? .white : .clear)
                                .foregroundStyle(isSelected ? Color.pinkDeep : Color.inkMute)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: isSelected ? Color(hex: "3C2832").opacity(0.06) : .clear, radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color(hex: "F2EAEC"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Action buttons
                    HStack(spacing: 10) {
                        PrimaryButton(title: "开始解析", icon: "sparkle", action: onAnalyze)

                        SecondaryButton(title: "重新上传", isFullWidth: false, action: onBack)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 30)
                .background(
                    Color.bgPage.opacity(0.97)
                        .background(.ultraThinMaterial)
                )
            }
        }
        .navigationTitle("确认聊天内容")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("编辑")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pink)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TextConfirmationView(onAnalyze: {}, onBack: {})
            .environment(AppState())
    }
}
