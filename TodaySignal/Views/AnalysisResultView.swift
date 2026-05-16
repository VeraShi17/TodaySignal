import SwiftUI

struct AnalysisResultView: View {
    @State private var results = MockData.analysisResults
    @State private var showCardPreview = false
    @State private var previewCardType: LearningCardType = .vocabulary
    var onDone: () -> Void

    var body: some View {
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

                    // Progress meta
                    HStack(spacing: 8) {
                        Text("解析 \(results.count) 条")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.ink2)
                            .tracking(0.4)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.pinkTint)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.pink)
                                    .frame(width: geo.size.width, height: 4)
                            }
                        }
                        .frame(height: 4)

                        let vocabCount = results.flatMap(\.vocabulary).count
                        let grammarCount = results.flatMap(\.grammarPoints).count
                        Text("\(vocabCount) 个生词 · \(grammarCount) 个语法")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkMute)
                    }
                    .padding(.bottom, 14)

                    // Analysis bubble cards
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        AnalysisBubbleCardView(
                            result: result,
                            onKnowledgeAction: { pointId, action in
                                updateKnowledgeAction(resultIndex: index, pointId: pointId, action: action)
                            },
                            onShowCardPreview: { cardType in
                                previewCardType = cardType
                                showCardPreview = true
                            }
                        )
                        .padding(.bottom, 16)
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
                            Text("\(savedCount)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.pinkDeep)
                            Text(" 个卡片 + \(knownCount) 个已认识")
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
        .sheet(isPresented: $showCardPreview) {
            CardPreviewModal(
                cardType: previewCardType,
                onDismiss: { showCardPreview = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var savedCount: Int {
        results.flatMap { $0.vocabulary + $0.grammarPoints }.filter { $0.action == .saved }.count
    }

    private var knownCount: Int {
        results.flatMap { $0.vocabulary + $0.grammarPoints }.filter { $0.action == .known }.count
    }

    private func updateKnowledgeAction(resultIndex: Int, pointId: UUID, action: KnowledgeAction) {
        // Check vocabulary
        if let vi = results[resultIndex].vocabulary.firstIndex(where: { $0.id == pointId }) {
            results[resultIndex].vocabulary[vi].action = action
            return
        }
        // Check grammar
        if let gi = results[resultIndex].grammarPoints.firstIndex(where: { $0.id == pointId }) {
            results[resultIndex].grammarPoints[gi].action = action
            return
        }
    }
}

// MARK: - Analysis Bubble Card

struct AnalysisBubbleCardView: View {
    let result: AnalysisResult
    var onKnowledgeAction: (UUID, KnowledgeAction) -> Void
    var onShowCardPreview: (LearningCardType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chat bubble
            ChatBubbleView(
                bubble: ChatBubble(
                    side: result.isUserReply ? .right : .left,
                    speakerRole: result.isUserReply ? .user : .idol,
                    text: result.originalText
                ),
                idolSide: .left
            )

            if result.isUserReply {
                userReplyFeedback
            } else {
                idolBubbleAnalysis
            }
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
                        onSave: {
                            onKnowledgeAction(point.id, .saved)
                            onShowCardPreview(.vocabulary)
                        }
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
                        onSave: {
                            onKnowledgeAction(point.id, .saved)
                            onShowCardPreview(.grammar)
                        }
                    )
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: User reply feedback

    @ViewBuilder
    private var userReplyFeedback: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mint)
                    .frame(width: 22, height: 22)
                    .background(Color.bgMint)
                    .clipShape(Circle())

                Text("你的回复")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Color.ink2)

                Spacer()

                if result.replyStatus == .needsImprovement {
                    TonePillView(text: "可以更自然", kind: .cream)
                }
            }

            if let issue = result.replyIssue {
                Text(issue)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.ink2)
                    .lineSpacing(4)
            }

            if let suggested = result.suggestedReply {
                VStack(alignment: .leading, spacing: 4) {
                    Text("更自然的说法")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color(hex: "3F8F66"))
                        .tracking(0.5)

                    Text(suggested)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.ink)

                    if let suggestedZH = result.suggestedReplyZH {
                        Text(suggestedZH)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                    }
                }
                .padding(10)
                .background(Color.bgMint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mintSoft, lineWidth: 1)
        )
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        AnalysisResultView(onDone: {})
    }
}
