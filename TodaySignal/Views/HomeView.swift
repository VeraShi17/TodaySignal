import SwiftUI

struct HomeView: View {
    var onUploadScreenshot: () -> Void
    var onPasteText: () -> Void
    var ocrErrorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPage.ignoresSafeArea()

            // Decorative gradient
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
                    // Header row
                    HStack {
                        HStack(spacing: 10) {
                            // App mark
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
                    }
                    .padding(.bottom, 26)

                    // App title
                    Text("오늘의 시그널")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .tracking(-0.5)

                    HStack(spacing: 4) {
                        Text("韩语聊天截图学习助手")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.ink2)
                        Text("·")
                            .foregroundStyle(Color.pinkDeep)
                        Text("for K-pop fans")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.ink2)
                    }
                    .padding(.top, 8)

                    if let ocrErrorMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "D96A1D"))
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(ocrErrorMessage)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Color.ink2)
                                    .lineSpacing(3)

                                Button("重新上传截图") {
                                    onUploadScreenshot()
                                }
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Color.pinkDeep)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(hex: "FFF4EA"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 14)
                    }

                    // Main action card
                    SignalCard {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.pink)
                                .frame(width: 6, height: 6)
                            Text("NEW SIGNAL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.ink2)
                                .tracking(0.6)
                        }
                        .padding(.bottom, 16)

                        VStack(spacing: 10) {
                            PrimaryButton(title: "上传聊天截图", icon: "camera.fill", action: onUploadScreenshot)
                            SecondaryButton(title: "粘贴韩语文本", icon: "doc.on.clipboard", action: onPasteText)
                        }

                        Text("支持 idol bubble、DM、社交平台聊天截图。\n上传后会先让你确认文字，再开始 AI 解析。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                            .lineSpacing(4)
                            .padding(.top, 16)
                    }
                    .padding(.top, 32)

                    // Privacy note
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.lavender)

                        Text("原始截图不会长期保存，学习卡片仅保存在本机。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: "5E4C8A"))
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.bgLavender)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 18)

                    // Recent analyses
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近解析")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.ink2)
                                .tracking(0.4)
                            Spacer()
                            Text("本机 · 3 条")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.inkMute)
                        }

                        ForEach(Array(MockData.recentAnalyses.enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.pinkDeep)
                                    .frame(width: 36, height: 36)
                                    .background(Color.pinkTint)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.preview)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.ink)
                                        .lineLimit(1)
                                    Text(item.meta)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Color.inkMute)
                                }

                                Spacer()

                                TonePillView(text: item.tag, kind: item.pillKind)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.line, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 26)

                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
            }
        }
    }
}

#Preview {
    HomeView(onUploadScreenshot: {}, onPasteText: {}, ocrErrorMessage: nil)
}
