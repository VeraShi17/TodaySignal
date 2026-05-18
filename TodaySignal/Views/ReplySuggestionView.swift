import SwiftUI

struct ReplySuggestionView: View {
    @Environment(AppState.self) private var appState
    @State private var contextInput = ""
    @State private var showEmptyContextAlert = false

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    contextSection
                    intentSection
                    toneSection
                    contentStateSection
                    Spacer().frame(height: appState.replySuggestions.isEmpty ? 120 : 24)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
            }

            if appState.replySuggestions.isEmpty {
                bottomGenerateBar
            }
        }
        .navigationTitle("生成回复建议")
        .navigationBarTitleDisplayMode(.inline)
        .alert("先选一条想回复的消息", isPresented: $showEmptyContextAlert) {
            Button("我知道了", role: .cancel) { }
        } message: {
            Text("回到 OCR 页面勾选 idol 气泡，或在这里输入你想说的话。")
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(appState.replyContextBubbles.isEmpty ? "对方说了什么？" : "你想回复这些消息")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.bottom, 6)

            if !appState.replyContextBubbles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(appState.replyContextBubbles) { bubble in
                        HStack(alignment: .top, spacing: 8) {
                            Text("IDOL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.pinkDeep)
                                .padding(.top, 3)

                            Text(bubble.text)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.pinkTint)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pinkSoft, lineWidth: 1)
                        )
                    }
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pinkSoft, lineWidth: 1)
                )
            } else {
                VStack(spacing: 8) {
                    quickEntryButton(title: "上传截图", icon: "camera")

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $contextInput)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 84)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.line, lineWidth: 1)
                            )

                        if contextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("或直接粘贴 idol 原文 / 对话内容…")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.inkFaint)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.line, lineWidth: 1)
                )
            }
        }
    }

    private var intentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("你想表达什么？")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.inkMute)
                    .tracking(0.6)
                Text("· 可选")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
            }
            .padding(.top, 18)
            .padding(.bottom, 6)

            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { appState.replyIntentZh },
                    set: { appState.replyIntentZh = $0 }
                ))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 76)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.line, lineWidth: 1)
                    )

                if appState.replyIntentZh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("例如：今天也辛苦啦，要好好吃饭")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkFaint)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            Text("不填也可以，系统会根据对方消息生成自然回复。")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkMute)
                .padding(.top, 4)
        }
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("回复语气")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.inkMute)
                    .tracking(0.6)

                if appState.selectedReplyTone == .subtleFlirty {
                    Text("轻微心动感，不越界")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Color(hex: "7860B3"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.bgLavender)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 8)

            WrapLayout(spacing: 6, lineSpacing: 6) {
                ForEach(ReplyTone.allCases, id: \.self) { tone in
                    toneChip(tone: tone)
                }
            }
        }
    }

    @ViewBuilder
    private func toneChip(tone: ReplyTone) -> some View {
        let isSelected = tone == appState.selectedReplyTone

        Button {
            appState.selectedReplyTone = tone
        } label: {
            HStack(spacing: 4) {
                Text(tone.rawValue)
                    .font(.system(size: 13, weight: .semibold))

                Text("· \(toneHint(for: tone))")
                    .font(.system(size: 10.5, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundStyle(isSelected ? .white : Color.ink2)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(isSelected ? Color.pink : .white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.pink : Color.line2, lineWidth: 1.5)
            )
            .shadow(color: isSelected ? Color.pink.opacity(0.45) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contentStateSection: some View {
        if appState.isGeneratingReply {
            loadingSection
                .padding(.top, 22)
        } else if let errorMessage = appState.replyGenerationError {
            Text(errorMessage)
                .font(.system(size: 12.5))
                .foregroundStyle(Color(hex: "B34A5E"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.bgSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 12)
        } else if !appState.replySuggestions.isEmpty {
            resultsSection
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.white, Color.bgLavender.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color(hex: "7860B3"))
                        Text("正在帮你组织自然韩语回复…")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.ink)
                        Text("根据 idol 的消息 + 你的语气偏好\n生成 3 条候选")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                            .multilineTextAlignment(.center)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.lavenderSoft, lineWidth: 1)
                )

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.lavenderSoft, lineWidth: 1)
                    )
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("3 条建议")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.ink2)
                Spacer()
                Button {
                    Task { await appState.generateReplySuggestions() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("换一批")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color.pinkDeep)
                }
            }
            .padding(.top, 22)
            .padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach(appState.replySuggestions) { suggestion in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TonePillView(
                                text: "\(suggestion.tone.rawValue) · \(suggestion.noteZh)",
                                kind: suggestionPillKind(for: suggestion.tone)
                            )
                            Spacer()
                            Button("复制") {
                                UIPasteboard.general.string = suggestion.replyKo
                            }
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color.pinkDeep)
                        }

                        Text(suggestion.replyKo)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .lineSpacing(3)

                        Text(suggestion.replyZh)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkMute)
                    }
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.line, lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "3C2832").opacity(0.12), radius: 10, y: 4)
                }
            }
        }
    }

    private var bottomGenerateBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                let trimmedContext = contextInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedIntent = appState.replyIntentZh.trimmingCharacters(in: .whitespacesAndNewlines)

                if appState.replyContextBubbles.isEmpty && trimmedContext.isEmpty && trimmedIntent.isEmpty {
                    showEmptyContextAlert = true
                    return
                }

                if appState.replyContextBubbles.isEmpty && !trimmedContext.isEmpty {
                    appState.replyContextBubbles = [ChatBubble(side: .left, speakerRole: .idol, text: trimmedContext)]
                }
                Task {
                    await appState.generateReplySuggestions()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .semibold))
                    Text(appState.isGeneratingReply ? "正在帮你组织自然韩语回复…" : "生成 3 条回复")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(appState.isGeneratingReply ? Color(hex: "E5DFEE") : Color(hex: "7860B3"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(
                    color: appState.isGeneratingReply ? .clear : Color(hex: "7860B3").opacity(0.55),
                    radius: 12,
                    y: 6
                )
            }
            .disabled(appState.isGeneratingReply)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 30)
            .background(Color.bgPage.opacity(0.97).background(.ultraThinMaterial))
        }
    }

    private func toneHint(for tone: ReplyTone) -> String {
        switch tone {
        case .natural: return "日常"
        case .cute: return "撒娇"
        case .polite: return "尊敬"
        case .friendly: return "亲近"
        case .subtleFlirty: return "不越界"
        }
    }

    private func quickEntryButton(title: String, icon: String) -> some View {
        Button {
            // UI-only placeholder; to be connected in V1-C+.
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color.clear)
            .foregroundStyle(Color.ink2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.line2, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func suggestionPillKind(for tone: ReplyTone) -> TonePillKind {
        switch tone {
        case .natural: return .pink
        case .cute: return .coral
        case .polite: return .lavender
        case .friendly: return .mint
        case .subtleFlirty: return .lavender
        }
    }
}

#Preview {
    NavigationStack {
        ReplySuggestionView()
            .environment(AppState())
    }
}
