import SwiftUI

struct AnalysisResultView: View {
    @Environment(AppState.self) private var appState
    @State private var feedbackInput: String = ""
    var onDone: () -> Void

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top note
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.lavender)
                        Text("默认从对方气泡提取学习点。你可以选择要生成卡片的内容。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: "5E4C8A"))
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.bgLavender)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 16)

                    // Analysis bubble cards
                    ForEach(Array(appState.analysisResults.enumerated()), id: \.element.id) { index, result in
                        AnalysisBubbleCardView(
                            result: result,
                            idolSide: appState.idolSide,
                            isRetrying: appState.retryingResultIDs.contains(result.id),
                            onRetryFailed: {
                                Task {
                                    await appState.retryFailedResult(resultID: result.id)
                                }
                            },
                            onKnowledgeAction: { pointId, action in
                                appState.updateKnowledgeAction(resultIndex: index, pointId: pointId, action: action)
                            },
                            onShowCardPreview: { cardType in
                                // Card preview is now triggered by AppState.updateKnowledgeAction
                            }
                        )
                        .padding(.bottom, 16)
                    }

                    if appState.checkMyReplyEnabled, appState.hasMySideBubbles(), let check = appState.myReplyCheckResult {
                        myReplyCheckSection(check)
                            .padding(.bottom, 16)
                    }

                    feedbackChatInputBlock

                    if !appState.feedbackMessages.isEmpty || appState.isSendingFeedback || appState.feedbackErrorMessage != nil {
                        feedbackConversationBlock
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }

            // Bottom save bar
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已选学习点")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkMute)
                        HStack(spacing: 0) {
                            Text("\(appState.savedCount)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.pinkDeep)
                            Text(" 个卡片 + \(appState.knownCount) 个已认识")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.ink)
                        }
                    }

                    Spacer()

                    Button(action: onDone) {
                        Label("查看卡片库", systemImage: "bookmark.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.pink.opacity(0.4), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .background(
                    Color.bgPage.opacity(0.97)
                        .background(.ultraThinMaterial)
                )
                .overlay(alignment: .top) { Divider() }
            }
        }
        .navigationTitle("解析结果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { onDone() }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pink)
            }
        }
        .sheet(isPresented: $appState.showCardPreview) {
            CardPreviewModal(
                vocabCard: appState.previewVocabCard,
                grammarCard: appState.previewGrammarCard,
                onDismiss: { appState.showCardPreview = false },
                onGoToLibrary: {
                    appState.showCardPreview = false
                    onDone()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func myReplyCheckSection(_ check: ReplyCheckResult) -> some View {
        let isNatural = check.status == .natural

        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.bgMint)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "3F8F66"))
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text("我的回复检查")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Text(isNatural ? "1 条 · 表达自然" : "1 条 · 可以更自然")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.inkMute)
                }
                Spacer()
            }

            // Reply check card
            VStack(alignment: .leading, spacing: 10) {
                // status badges row
                HStack(spacing: 6) {
                    Text("我的回复")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Color(hex: "3F8F66"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color.bgMint)
                        .clipShape(Capsule())

                    TonePillView(
                        text: isNatural ? "✓ 表达自然" : "可以更自然一点",
                        kind: isNatural ? .mint : .cream
                    )
                    Spacer()
                }

                // Original Korean reply
                Text(check.originalReply)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.line, lineWidth: 1)
                    )

                // Body feedback
                Text(check.feedbackZh)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ink2)
                    .lineSpacing(4)

                // Suggestion box (only when needs improvement)
                if !isNatural, let suggestedKo = check.suggestedReplyKo {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("更自然的说法")
                                .font(.system(size: 10.5, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(Color(hex: "3F8F66"))
                            Spacer()
                            Button {
                                UIPasteboard.general.string = suggestedKo
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("复制")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.ink2)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.line2, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Text(suggestedKo)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(Color.ink)

                        if let suggestedZh = check.suggestedReplyZh {
                            Text(suggestedZh)
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.inkMute)
                        }
                    }
                    .padding(12)
                    .background(Color.bgMint)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.mintSoft, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                }
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isNatural ? Color.mintSoft : Color.pinkSoft, lineWidth: 1)
            )
        }
    }

    private var feedbackChatInputBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "7860B3"))
                    }
                Text("还有哪里不懂？")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
            }

            Text("关于这次聊天的追问 · 答案不会保存为卡片")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkMute)
                .padding(.leading, 36)
                .padding(.bottom, 4)

            // Quick chips
            FlowChips(items: ["这里为什么这么说？", "这几条要连起来看吗？", "这个语气自然吗？"]) { text in
                feedbackInput = text
            }

            // Input row
            HStack(spacing: 6) {
                TextField("例如：这里为什么用 -는데？", text: $feedbackInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.leading, 14)
                    .padding(.trailing, 6)
                    .frame(height: 36)
                    .font(.system(size: 14))

                Button {
                    sendFeedback()
                } label: {
                    Text("发送")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(hex: "E5DFEE") : Color(hex: "7860B3"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(appState.isSendingFeedback || feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing, 4)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lavenderSoft, lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.white, Color.bgLavender.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.lavenderSoft, lineWidth: 1)
        )
    }

    private var feedbackConversationBlock: some View {
        VStack(spacing: 10) {
            ForEach(appState.feedbackMessages) { msg in
                if msg.isUser {
                    HStack {
                        Spacer(minLength: 40)
                        Text(msg.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "7860B3"))
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 18,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 18,
                                    topTrailingRadius: 6
                                )
                            )
                    }
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.bgLavender)
                            .frame(width: 26, height: 26)
                            .overlay {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "7860B3"))
                            }
                        Text(msg.text)
                            .font(.system(size: 13.5))
                            .foregroundStyle(Color.ink2)
                            .lineSpacing(4)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.white)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 6,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 18,
                                    topTrailingRadius: 18
                                )
                            )
                            .overlay(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 6,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 18,
                                    topTrailingRadius: 18
                                )
                                .stroke(Color.lavenderSoft, lineWidth: 1)
                            )
                        Spacer(minLength: 40)
                    }
                }
            }

            if appState.isSendingFeedback {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在继续解释这个表达…")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.inkMute)
                    Spacer()
                }
            }

            if let feedbackErrorMessage = appState.feedbackErrorMessage {
                Text(feedbackErrorMessage)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color(hex: "B34A5E"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bgSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func sendFeedback() {
        let question = feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        feedbackInput = ""
        Task {
            await appState.sendMockFeedback(question: question)
        }
    }
}

// MARK: - Flow Chips (wrap layout for feedback quick chips)

private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        FlexibleHStack(spacing: 6, lineSpacing: 6) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "7860B3"))
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.lavenderSoft, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FlexibleHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Simple wrap using Layout protocol (iOS 16+); fallback works on iOS 17.
        WrapLayout(spacing: spacing, lineSpacing: lineSpacing) {
            content()
        }
    }
}

struct WrapLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth, lineWidth > 0 {
                width = max(width, lineWidth - spacing)
                totalHeight += lineHeight + lineSpacing
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        width = max(width, lineWidth - spacing)
        totalHeight += lineHeight
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            _ = maxWidth
        }
    }
}

// MARK: - Analysis Bubble Card

struct AnalysisBubbleCardView: View {
    let result: AnalysisResult
    var idolSide: BubbleSide = .left
    var isRetrying: Bool = false
    var onRetryFailed: (() -> Void)?
    var onKnowledgeAction: (UUID, KnowledgeAction) -> Void
    var onShowCardPreview: (LearningCardType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chat bubble (idol side)
            ChatBubbleView(
                bubble: ChatBubble(
                    side: idolSide,
                    speakerRole: .idol,
                    text: result.originalText
                ),
                idolSide: idolSide
            )

            idolBubbleAnalysis
        }
        .padding(14)
        .background(Color.bgElev)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    // MARK: Idol bubble analysis

    @ViewBuilder
    private var idolBubbleAnalysis: some View {
        if let failureMessage = result.failureMessage {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "D96A1D"))
                    Text("该条解析失败")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color.ink2)
                }

                Text(failureMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkMute)

                Button {
                    onRetryFailed?()
                } label: {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isRetrying ? "重试中…" : "重试该条")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Color.pinkDeep)
                }
                .disabled(isRetrying)
            }
            .padding(12)
            .background(Color(hex: "FFF4EA"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 10)
        } else {

        // Translation
        VStack(alignment: .leading, spacing: 4) {
            Text("中文翻译")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
            Text(result.translationZH)
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)
                .lineSpacing(4)
        }
        .padding(.top, 12)

        // Tone labels
        VStack(alignment: .leading, spacing: 4) {
            Text("语气")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
            HStack(spacing: 6) {
                ForEach(result.toneLabels, id: \.self) { tone in
                    TonePillView(text: tone.rawValue, kind: tone.pillKind)
                }
            }
        }
        .padding(.top, 8)

        // Vocabulary
        if !result.vocabulary.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("生词")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.inkMute)
                    .tracking(0.6)

                ForEach(result.vocabulary) { point in
                    KnowledgePointView(
                        point: point,
                        onKnow: { onKnowledgeAction(point.id, .known) },
                        onSkip: { onKnowledgeAction(point.id, .dismissed) },
                        onSave: { onKnowledgeAction(point.id, .saved) },
                        onUndo: { onKnowledgeAction(point.id, .open) }
                    )
                }
            }
            .padding(.top, 12)
        }

        // Grammar
        if !result.grammarPoints.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("语法 / 词尾")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.inkMute)
                    .tracking(0.6)

                ForEach(result.grammarPoints) { point in
                    KnowledgePointView(
                        point: point,
                        onKnow: { onKnowledgeAction(point.id, .known) },
                        onSkip: { onKnowledgeAction(point.id, .dismissed) },
                        onSave: { onKnowledgeAction(point.id, .saved) },
                        onUndo: { onKnowledgeAction(point.id, .open) }
                    )
                }
            }
            .padding(.top, 12)
        }
        }
    }

}

#Preview {
    NavigationStack {
        AnalysisResultView(onDone: {})
            .environment({
                let state = AppState()
                state.analysisResults = MockData.analysisResults
                return state
            }())
    }
}
