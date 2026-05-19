import SwiftUI

struct AnalysisResultView: View {
    @Environment(AppState.self) private var appState
    @State private var feedbackInput: String = ""
    @State private var focusedResultID: UUID?
    @State private var showExitConfirmation = false
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

                    // Follow chat order: idol bubble analysis + inline my-reply checks.
                    let analysisIndexByBubbleID = Dictionary(
                        uniqueKeysWithValues: appState.analysisResults.enumerated().map { ($0.element.bubbleID, $0.offset) }
                    )
                    let myReplyCheckPairs: [(UUID, ReplyCheckResult)] = appState.myReplyCheckResults.compactMap { check in
                        guard let bubbleID = check.bubbleID else { return nil }
                        return (bubbleID, check)
                    }
                    let myReplyCheckByBubbleID = Dictionary(uniqueKeysWithValues: myReplyCheckPairs)

                    ForEach(appState.chatBubbles.filter { $0.type == .text }, id: \.id) { bubble in
                        if bubble.side == appState.idolSide,
                           let resultIndex = analysisIndexByBubbleID[bubble.id] {
                            let result = appState.analysisResults[resultIndex]
                            AnalysisBubbleCardView(
                                result: result,
                                idolSide: appState.idolSide,
                                isRetrying: appState.retryingResultIDs.contains(result.id),
                                isSavingKnowledgePoint: { pointID in
                                    appState.savingKnowledgePointIDs.contains(pointID)
                                },
                                onRetryFailed: {
                                    Task {
                                        await appState.retryFailedResult(resultID: result.id)
                                    }
                                },
                                onKnowledgeAction: { pointId, action in
                                    appState.updateKnowledgeAction(resultIndex: resultIndex, pointId: pointId, action: action)
                                },
                                onShowCardPreview: { _ in
                                    // Card preview is now triggered by AppState.updateKnowledgeAction
                                },
                                onAskQuestion: {
                                    feedbackInput = ""
                                    focusedResultID = result.id
                                }
                            )
                            .padding(.bottom, 16)
                        } else if appState.checkMyReplyEnabled,
                                  bubble.side != appState.idolSide,
                                  let check = myReplyCheckByBubbleID[bubble.id] {
                            myReplyCheckCard(check)
                                .padding(.bottom, 16)
                        }
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { showExitConfirmation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                    }
                    .foregroundStyle(Color.pink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { onDone() }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pink)
            }
        }
        .alert("退出当前页面？", isPresented: $showExitConfirmation) {
            Button("留在这里", role: .cancel) {}
            Button("退出", role: .destructive) {
                appState.navigationPath = NavigationPath()
            }
        } message: {
            Text("当前分析结果不会被保存，已保存到卡片库的内容不受影响。")
        }
        .sheet(isPresented: $appState.showCardPreview) {
            CardPreviewModal(
                vocabCard: appState.previewVocabCard,
                grammarCard: appState.previewGrammarCard,
                isLoadingExamples: appState.isCardPreviewLoadingExamples,
                isRetryingExamples: appState.isRetryingCardPreviewExamples,
                exampleErrorMessage: appState.cardPreviewExampleErrorMessage,
                onRetryExamples: {
                    Task { await appState.retryPreviewCardExamples() }
                },
                onDismiss: {
                    appState.showCardPreview = false
                    appState.isCardPreviewLoadingExamples = false
                    appState.cardPreviewExampleErrorMessage = nil
                },
                onGoToLibrary: {
                    appState.showCardPreview = false
                    appState.isCardPreviewLoadingExamples = false
                    appState.cardPreviewExampleErrorMessage = nil
                    onDone()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { focusedResultID != nil },
            set: { isPresented in
                if !isPresented { focusedResultID = nil }
            }
        )) {
            if let id = focusedResultID,
               let result = appState.analysisResults.first(where: { $0.id == id }) {
                focusedFeedbackSheet(result: result)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private func myReplyCheckCard(_ check: ReplyCheckResult) -> some View {
        let isFailed = check.failureMessage != nil
        let isNatural = check.status == .natural
        let bubbleID = check.bubbleID
        let isRetrying = bubbleID.map { appState.retryingReplyCheckBubbleIDs.contains($0) } ?? false

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("我的回复")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color(hex: "3F8F66"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Color.bgMint)
                    .clipShape(Capsule())

                if isFailed {
                    TonePillView(text: "检查失败", kind: .cream)
                } else {
                    TonePillView(
                        text: isNatural ? "✓ 表达自然" : "可以更自然一点",
                        kind: isNatural ? .mint : .cream
                    )
                }
                Spacer()
            }

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

            if isFailed, let failureMessage = check.failureMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("这条回复暂时没检查成功，可单独重试。")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ink2)
                        .lineSpacing(4)
                    Text(failureMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkMute)
                    if let bubbleID {
                        Button {
                            Task { await appState.retryMyReplyCheck(for: bubbleID) }
                        } label: {
                            HStack(spacing: 4) {
                                if isRetrying {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                Text(isRetrying ? "重试中…" : "重试这条")
                                    .font(.system(size: 12.5, weight: .semibold))
                            }
                            .foregroundStyle(Color(hex: "B34A5E"))
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.line2, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(isRetrying)
                    }
                }
                .padding(12)
                .background(Color.bgSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text(check.feedbackZh)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ink2)
                    .lineSpacing(4)
            }

            if !isFailed, !isNatural, let suggestedKo = check.suggestedReplyKo {
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
                .stroke(isFailed ? Color.pinkSoft : (isNatural ? Color.mintSoft : Color.pinkSoft), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func focusedFeedbackSheet(result: AnalysisResult) -> some View {
        let thread = appState.feedbackThreads[result.id] ?? []
        let isSending = appState.feedbackSendingForResultID == result.id
        let errorMessage = appState.feedbackErrors[result.id]

        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.bgLavender)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "sparkle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "7860B3"))
                        }
                    Text("关于这句话提问")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                }

                Text(result.originalText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.bgLavender.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.lavenderSoft, lineWidth: 1)
                    )
                    .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Divider()

            // Conversation thread
            ScrollView {
                VStack(spacing: 10) {
                    if thread.isEmpty {
                        Text("点选下方快捷问题，或直接输入你想问的。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    } else {
                        ForEach(thread) { msg in
                            messageBubble(msg)
                        }
                    }

                    if isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("正在继续解释这个表达…")
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.inkMute)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    if let errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("追问失败，可重试")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Color(hex: "B34A5E"))

                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.inkMute)
                                .lineSpacing(3)

                            Button {
                                retryFocusedFeedback(resultID: result.id)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("重试发送")
                                        .font(.system(size: 12.5, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: "B34A5E"))
                                .padding(.horizontal, 10)
                                .frame(height: 30)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.line2, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(isSending)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.bgSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            Divider()

            // Quick chips + input
            VStack(alignment: .leading, spacing: 10) {
                WrapLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(["这是敬语还是平语？", "解释下当前句尾的意义？", "和相似句尾有什么区别？", "这句在聊天里自然吗？"], id: \.self) { chip in
                        Button {
                            feedbackInput = chip
                        } label: {
                            Text(chip)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "7860B3"))
                                .padding(.horizontal, 12)
                                .frame(height: 28)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.lavenderSoft, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    TextField("例如：为什么这里用 -아/어도 되다？", text: $feedbackInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.leading, 14)
                        .padding(.trailing, 6)
                        .frame(height: 36)
                        .font(.system(size: 14))

                    Button {
                        sendFocusedFeedback(resultID: result.id)
                    } label: {
                        Text("发送")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(canSendFeedback(isSending: isSending) ? Color(hex: "7860B3") : Color(hex: "E5DFEE"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendFeedback(isSending: isSending))
                    .padding(.trailing, 4)
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lavenderSoft, lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(Color.bgPage)
        }
        .background(Color.bgPage.ignoresSafeArea())
    }

    @ViewBuilder
    private func messageBubble(_ msg: FeedbackMessage) -> some View {
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

    private func canSendFeedback(isSending: Bool) -> Bool {
        !isSending && !feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendFocusedFeedback(resultID: UUID) {
        let question = feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        feedbackInput = ""
        Task {
            await appState.sendFeedback(question: question, forResultID: resultID)
        }
    }

    private func retryFocusedFeedback(resultID: UUID) {
        guard appState.feedbackSendingForResultID == nil else { return }
        let lastUserMessage = (appState.feedbackThreads[resultID] ?? []).last(where: { $0.isUser })?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let question = lastUserMessage, !question.isEmpty else { return }
        Task {
            await appState.sendFeedback(question: question, forResultID: resultID)
        }
    }
}

// MARK: - WrapLayout (used by tone chips, feedback quick chips)

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
    var isSavingKnowledgePoint: (UUID) -> Bool = { _ in false }
    var onRetryFailed: (() -> Void)?
    var onKnowledgeAction: (UUID, KnowledgeAction) -> Void
    var onShowCardPreview: (LearningCardType) -> Void
    var onAskQuestion: () -> Void = {}

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
        .overlay(alignment: .topTrailing) {
            // Per-bubble follow-up question button
            Button(action: onAskQuestion) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color(hex: "7860B3"))
                    .padding(.top, 10)
                    .padding(.trailing, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("针对这句话提问")
        }
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
                        isGenerating: isSavingKnowledgePoint(point.id),
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
                        isGenerating: isSavingKnowledgePoint(point.id),
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
