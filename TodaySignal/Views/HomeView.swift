import SwiftUI

struct HomeView: View {
    var onUploadScreenshot: () -> Void
    var onPasteText: () -> Void
    var onQuickReply: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPage.ignoresSafeArea()

            VStack {
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "FFE4EC"), .clear],
                        center: UnitPoint(x: 0.2, y: 0),
                        startRadius: 0,
                        endRadius: 280
                    )
                    RadialGradient(
                        colors: [Color.bgLavender, .clear],
                        center: UnitPoint(x: 0.9, y: 0.1),
                        startRadius: 0,
                        endRadius: 240
                    )
                }
                .frame(height: 320)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    Text("오늘의 시그널")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .tracking(-0.5)

                    Text("韩语聊天截图学习助手")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ink2)
                        .padding(.top, 6)

                    learningCard
                        .padding(.top, 22)

                    quickReplyCard
                        .padding(.top, 14)

                    privacyNote
                        .padding(.top, 18)

                    recentHeader
                        .padding(.top, 22)

                    recentList

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFB6C7"), Color.pink, Color.pinkDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.pink.opacity(0.4), radius: 8, y: 4)

                Text("TODAY'S SIGNAL")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkMute)
                    .tracking(0.4)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.line, lineWidth: 1)
                    )
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.inkMute)
            }
        }
        .padding(.bottom, 22)
    }

    private var learningCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 6, height: 6)
                        Text("A · 学习解析")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.pinkDeep)
                            .tracking(0.6)
                    }

                    Text("读懂 idol 在说什么")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .padding(.top, 6)

                    Text("上传聊天截图，看翻译、生词、语气和语法。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.inkMute)
                        .lineSpacing(3)
                        .padding(.top, 4)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pinkTint)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "sparkle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.pinkDeep)
                    }
            }

            VStack(spacing: 8) {
                PrimaryButton(title: "上传聊天截图", icon: "camera.fill", action: onUploadScreenshot)
                SecondaryButton(title: "粘贴韩语文本", icon: "doc.on.clipboard", action: onPasteText)
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.line, lineWidth: 1)
        )
        .shadow(color: Color(hex: "3C2832").opacity(0.16), radius: 20, y: 10)
    }

    private var quickReplyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "7860B3"))
                            .frame(width: 6, height: 6)
                        Text("B · 快速实时回复")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "7860B3"))
                            .tracking(0.6)
                    }

                    Text("想马上回一句韩语？")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .padding(.top, 6)

                    Text("输入内容或上传截图，生成自然回复。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.inkMute)
                        .lineSpacing(3)
                        .padding(.top, 4)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 14)
                    .fill(.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.lavenderSoft, lineWidth: 1)
                    )
                    .overlay {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: "7860B3"))
                    }
            }

            Button(action: onQuickReply) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("快速实时回复")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(hex: "7860B3"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color(hex: "7860B3").opacity(0.45), radius: 10, y: 5)
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.white, Color.bgLavender.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.lavenderSoft, lineWidth: 1)
        )
        .shadow(color: Color(hex: "7860B3").opacity(0.18), radius: 18, y: 9)
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkMute)

            Text("原始截图不会长期保存。")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkMute)
                .lineSpacing(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    private var recentHeader: some View {
        HStack {
            Text("最近")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.ink2)
                .tracking(0.4)
            Spacer()
            Text("本机 · 3 条")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkMute)
        }
        .padding(.bottom, 10)
    }

    private var recentList: some View {
        VStack(spacing: 8) {
            ForEach(Array(MockData.recentAnalyses.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(item.pillKind == .lavender ? Color.bgLavender : Color.pinkTint)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(item.pillKind == .lavender ? Color(hex: "7860B3") : Color.pinkDeep)
                        }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.preview)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                        Text(item.meta.replacingOccurrences(of: " · ", with: " · 学习解析 · "))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkMute)
                            .lineLimit(1)
                    }

                    Spacer()
                    TonePillView(text: item.tag, kind: item.pillKind)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.line, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    HomeView(onUploadScreenshot: {}, onPasteText: {}, onQuickReply: {})
}
