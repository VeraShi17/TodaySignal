import SwiftUI

/// Shared app state that connects all views in the analysis flow.
/// Uses @Observable (iOS 17+) for automatic SwiftUI updates.
@Observable
class AppState {

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }

    // MARK: - Text Confirmation (input stage)

    var chatBubbles: [ChatBubble] = MockData.chatBubbles
    var idolSide: BubbleSide = .left
    var checkMyReplyEnabled = true
    var selectedReplyBubbleIDs: Set<UUID> = []

    var replyContextBubbles: [ChatBubble] = []
    var replySuggestions: [ReplySuggestion] = []
    var selectedReplyTone: ReplyTone = .natural
    var replyIntentZh = ""
    var isGeneratingReply = false
    var replyGenerationError: String?

    // MARK: - Analysis Results

    var analysisResults: [AnalysisResult] = []
    var isAnalyzing = false
    var analysisErrorMessage: String?
    var retryingResultIDs: Set<UUID> = []

    var myReplyCheckResults: [ReplyCheckResult] = []
    var retryingReplyCheckBubbleIDs: Set<UUID> = []
    /// Per-bubble feedback chat threads keyed by AnalysisResult.id.
    /// V1 keeps these in-memory only; never persisted.
    var feedbackThreads: [UUID: [FeedbackMessage]] = [:]
    /// AnalysisResult.id for the in-flight feedback request (nil if none).
    var feedbackSendingForResultID: UUID?
    /// Per-bubble feedback error message keyed by AnalysisResult.id.
    var feedbackErrors: [UUID: String] = [:]

    private let aiAnalysisService: AIAnalysisServicing
    private let replySuggestionService: ReplySuggestionServicing
    private let replyCheckService: ReplyCheckServicing
    private let feedbackChatService: FeedbackChatServicing
    private let cardExampleService: CardExampleServicing
    private let cardStorageService: CardStorageService
    private var persistedKnowledgeMarks: [String: KnowledgeAction]

    private let onboardingKey = "today_signal_onboarding_completed"

    #if DEBUG
    var lastDebugClearAt: Date?
    #endif

    init(
        aiAnalysisService: AIAnalysisServicing = AIAnalysisServiceFactory.makeDefaultService(),
        replySuggestionService: ReplySuggestionServicing = ReplySuggestionServiceFactory.makeDefaultService(),
        replyCheckService: ReplyCheckServicing = ReplyCheckServiceFactory.makeDefaultService(),
        feedbackChatService: FeedbackChatServicing = FeedbackChatServiceFactory.makeDefaultService(),
        cardExampleService: CardExampleServicing = CardExampleServiceFactory.makeDefaultService(),
        cardStorageService: CardStorageService = .shared
    ) {
        self.aiAnalysisService = aiAnalysisService
        self.replySuggestionService = replySuggestionService
        self.replyCheckService = replyCheckService
        self.feedbackChatService = feedbackChatService
        self.cardExampleService = cardExampleService
        self.cardStorageService = cardStorageService
        self.persistedKnowledgeMarks = cardStorageService.loadKnowledgeMarks()

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.vocabularyCards = cardStorageService.loadVocabularyCards()
        self.grammarCards = cardStorageService.loadGrammarCards()
    }

    // MARK: - Card Library (accumulated across sessions)

    var vocabularyCards: [VocabularyCard] = []
    var grammarCards: [GrammarCard] = []

    // MARK: - Navigation

    var selectedTab: MainTab = .analysis
    var navigationPath = NavigationPath()

    enum MainTab: String {
        case analysis = "解析"
        case library = "卡片库"
        case settings = "设置"
    }

    // MARK: - Card Preview

    var showCardPreview = false
    var previewVocabCard: VocabularyCard?
    var previewGrammarCard: GrammarCard?
    var isCardPreviewLoadingExamples = false
    var isRetryingCardPreviewExamples = false
    var cardPreviewExampleErrorMessage: String?
    var savingKnowledgePointIDs: Set<UUID> = []

    // MARK: - Actions

    @MainActor
    func startAnalysis() async -> Bool {
        guard !isAnalyzing else { return false }

        isAnalyzing = true
        analysisErrorMessage = nil

        defer { isAnalyzing = false }

        do {
            let request = AnalysisRequest(bubbles: chatBubbles, idolSide: idolSide)
            let results = try await aiAnalysisService.analyze(request: request)
            let merged = mergeWithFailurePlaceholders(results: results, request: request)
            let withMarks = applyPersistedKnowledgeMarks(to: merged)
            analysisResults = deduplicateKnowledgePointsGlobally(in: withMarks)
            await loadMyReplyCheckIfNeeded()
            feedbackThreads = [:]
            feedbackErrors = [:]
            feedbackSendingForResultID = nil
            return true
        } catch {
            if let knownError = error as? AIAnalysisError {
                if let debugMessage = knownError.debugMessage {
                    analysisErrorMessage = "\(knownError.errorDescription ?? "解析失败")\n\n调试信息：\(debugMessage)"
                } else {
                    analysisErrorMessage = knownError.errorDescription
                }
            } else {
                analysisErrorMessage = "解析失败，请稍后重试。"
            }
            return false
        }
    }

    func clearAnalysisError() {
        analysisErrorMessage = nil
    }

    func hasMySideBubbles() -> Bool {
        chatBubbles.contains { $0.side != idolSide }
    }

    func toggleReplyBubbleSelection(_ bubbleID: UUID) {
        if selectedReplyBubbleIDs.contains(bubbleID) {
            selectedReplyBubbleIDs.remove(bubbleID)
        } else {
            selectedReplyBubbleIDs.insert(bubbleID)
        }
    }

    func prepareReplyContextFromSelection() -> Bool {
        let selected = chatBubbles.filter { selectedReplyBubbleIDs.contains($0.id) }
        guard !selected.isEmpty else { return false }
        replyContextBubbles = selected
        replySuggestions = []
        replyIntentZh = ""
        selectedReplyTone = .natural
        return true
    }

    func prepareReplyContextFromHomeEntry() {
        replyContextBubbles = []
        replySuggestions = []
        replyIntentZh = ""
        selectedReplyTone = .natural
    }

    @MainActor
    func generateReplySuggestions() async {
        guard !isGeneratingReply else { return }
        isGeneratingReply = true
        replyGenerationError = nil
        defer { isGeneratingReply = false }

        do {
            replySuggestions = try await replySuggestionService.generateReplies(
                contextBubbles: replyContextBubbles,
                intentZh: replyIntentZh,
                tone: selectedReplyTone
            )
        } catch let error as ReplySuggestionError {
            if let debug = error.debugMessage {
                replyGenerationError = "\(error.errorDescription ?? "回复生成失败")\n\n调试信息：\(debug)"
            } else {
                replyGenerationError = error.errorDescription ?? "回复生成失败，请稍后重试。"
            }
            replySuggestions = []
        } catch {
            replyGenerationError = "回复生成失败，请稍后重试。"
            replySuggestions = []
        }
    }

    @MainActor
    func loadMyReplyCheckIfNeeded() async {
        guard checkMyReplyEnabled && hasMySideBubbles() else {
            myReplyCheckResults = []
            return
        }

        let myBubbles = chatBubbles.filter { $0.side != idolSide && $0.type == .text }
        let idolBubbles = chatBubbles.filter { $0.side == idolSide && $0.type == .text }

        guard !myBubbles.isEmpty else {
            myReplyCheckResults = []
            return
        }

        do {
            let results = try await replyCheckService.checkReplies(myBubbles: myBubbles, idolContext: idolBubbles)
            myReplyCheckResults = results
        } catch let error as ReplyCheckError {
            let message = error.errorDescription ?? "我的回复检查失败，请稍后重试。"
            myReplyCheckResults = myBubbles.map { bubble in
                ReplyCheckResult(
                    bubbleID: bubble.id,
                    originalReply: bubble.text,
                    status: .natural,
                    feedbackZh: "暂时未能完成这条回复检查。",
                    issueZh: nil,
                    suggestedReplyKo: nil,
                    suggestedReplyZh: nil,
                    failureMessage: message
                )
            }
        } catch {
            myReplyCheckResults = myBubbles.map { bubble in
                ReplyCheckResult(
                    bubbleID: bubble.id,
                    originalReply: bubble.text,
                    status: .natural,
                    feedbackZh: "暂时未能完成这条回复检查。",
                    issueZh: nil,
                    suggestedReplyKo: nil,
                    suggestedReplyZh: nil,
                    failureMessage: "我的回复检查失败，请稍后重试。"
                )
            }
        }
    }

    @MainActor
    func retryMyReplyCheck(for bubbleID: UUID) async {
        guard let bubble = chatBubbles.first(where: { $0.id == bubbleID && $0.side != idolSide && $0.type == .text }) else { return }
        guard !retryingReplyCheckBubbleIDs.contains(bubbleID) else { return }

        retryingReplyCheckBubbleIDs.insert(bubbleID)
        defer { retryingReplyCheckBubbleIDs.remove(bubbleID) }

        let idolBubbles = chatBubbles.filter { $0.side == idolSide && $0.type == .text }

        do {
            let retried = try await replyCheckService.checkReplies(myBubbles: [bubble], idolContext: idolBubbles)
            guard let first = retried.first else { return }
            if let index = myReplyCheckResults.firstIndex(where: { $0.bubbleID == bubbleID }) {
                myReplyCheckResults[index] = first
            }
        } catch let error as ReplyCheckError {
            let message = error.errorDescription ?? "我的回复检查失败，请稍后重试。"
            if let index = myReplyCheckResults.firstIndex(where: { $0.bubbleID == bubbleID }) {
                myReplyCheckResults[index] = ReplyCheckResult(
                    bubbleID: bubbleID,
                    originalReply: bubble.text,
                    status: .natural,
                    feedbackZh: "暂时未能完成这条回复检查。",
                    issueZh: nil,
                    suggestedReplyKo: nil,
                    suggestedReplyZh: nil,
                    failureMessage: message
                )
            }
        } catch {
            if let index = myReplyCheckResults.firstIndex(where: { $0.bubbleID == bubbleID }) {
                myReplyCheckResults[index] = ReplyCheckResult(
                    bubbleID: bubbleID,
                    originalReply: bubble.text,
                    status: .natural,
                    feedbackZh: "暂时未能完成这条回复检查。",
                    issueZh: nil,
                    suggestedReplyKo: nil,
                    suggestedReplyZh: nil,
                    failureMessage: "我的回复检查失败，请稍后重试。"
                )
            }
        }
    }

    @MainActor
    func sendFeedback(question: String, forResultID resultID: UUID) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, feedbackSendingForResultID == nil else { return }

        guard let focused = analysisResults.first(where: { $0.id == resultID }) else { return }

        feedbackErrors[resultID] = nil
        feedbackSendingForResultID = resultID
        feedbackThreads[resultID, default: []].append(FeedbackMessage(isUser: true, text: trimmed))
        defer { feedbackSendingForResultID = nil }

        let nearbyTexts = analysisResults
            .filter { $0.id != resultID }
            .map { $0.originalText }

        let context = FeedbackChatContext(
            focusedText: focused.originalText,
            focusedTranslationZH: focused.translationZH,
            focusedToneLabels: focused.toneLabels,
            focusedVocabulary: focused.vocabulary,
            focusedGrammarPoints: focused.grammarPoints,
            nearbyBubbleTexts: nearbyTexts,
            myReplyCheck: nil
        )

        do {
            let answer = try await feedbackChatService.ask(question: trimmed, context: context)
            feedbackThreads[resultID, default: []].append(answer)
        } catch let error as FeedbackChatError {
            if let debug = error.debugMessage {
                feedbackErrors[resultID] = "\(error.errorDescription ?? "追问失败")\n\n调试信息：\(debug)"
            } else {
                feedbackErrors[resultID] = error.errorDescription ?? "追问失败，请稍后重试。"
            }
        } catch {
            feedbackErrors[resultID] = "追问失败，请稍后重试。"
        }
    }

    @MainActor
    func retryFailedResult(resultID: UUID) async {
        guard let resultIndex = analysisResults.firstIndex(where: { $0.id == resultID }) else { return }
        let current = analysisResults[resultIndex]
        guard current.failureMessage != nil else { return }
        guard let bubble = chatBubbles.first(where: { $0.id == current.bubbleID }) else { return }

        retryingResultIDs.insert(resultID)
        defer { retryingResultIDs.remove(resultID) }

        do {
            let request = AnalysisRequest(bubbles: [bubble], idolSide: bubble.side)
            let retried = try await aiAnalysisService.analyze(request: request)
            guard let first = retried.first else {
                analysisResults[resultIndex] = makeFailedAnalysisResult(
                    for: bubble,
                    resultID: current.id,
                    reason: "单条重试未返回可用结果（返回条目与原文不一致）。"
                )
                return
            }

            analysisResults[resultIndex] = applyPersistedKnowledgeMarks(to: [
                AnalysisResult(
                    id: current.id,
                    bubbleID: bubble.id,
                    originalText: first.originalText,
                    translationZH: first.translationZH,
                    toneLabels: first.toneLabels,
                    vocabulary: first.vocabulary,
                    grammarPoints: first.grammarPoints
                )
            ])[0]
            analysisResults = deduplicateKnowledgePointsGlobally(in: analysisResults)
        } catch {
            let reason = analysisFailureReason(from: error)
            analysisResults[resultIndex] = makeFailedAnalysisResult(for: bubble, resultID: current.id, reason: reason)
        }
    }

    /// Update a knowledge point's action state
    func updateKnowledgeAction(resultIndex: Int, pointId: UUID, action: KnowledgeAction) {
        guard resultIndex < analysisResults.count else { return }

        if action == .saved, savingKnowledgePointIDs.contains(pointId) {
            return
        }

        #if DEBUG
        if action == .saved {
            DebugTelemetry.increment(.cardExampleRequestTotal)
        }
        #endif

        // Check vocabulary
        if let vi = analysisResults[resultIndex].vocabulary.firstIndex(where: { $0.id == pointId }) {
            let previousAction = analysisResults[resultIndex].vocabulary[vi].action
            analysisResults[resultIndex].vocabulary[vi].action = action

            let point = analysisResults[resultIndex].vocabulary[vi]
            persistKnowledgeMark(for: point, action: action)

            if action == .saved {
                savingKnowledgePointIDs.insert(pointId)

                let placeholderCard = VocabularyCard(
                    word: point.term,
                    meaningZH: point.meaningZH,
                    pronunciation: point.pronunciation ?? "",
                    partOfSpeech: point.partOfSpeech ?? "",
                    originalSentence: analysisResults[resultIndex].originalText,
                    exampleSentence: "正在生成例句…",
                    exampleTranslationZH: "",
                    usageNote: point.usageNote,
                    sourcePointId: point.id
                )
                previewVocabCard = placeholderCard
                previewGrammarCard = nil
                isCardPreviewLoadingExamples = true
                cardPreviewExampleErrorMessage = nil
                showCardPreview = true

                Task { @MainActor in
                    defer { savingKnowledgePointIDs.remove(pointId) }
                    let created = await createVocabularyCard(from: point, sentence: analysisResults[resultIndex].originalText)
                    let card = created.card
                    let finalCard: VocabularyCard
                    if let existing = existingVocabularyCard(for: point.term) {
                        finalCard = existing
                    } else {
                        vocabularyCards.insert(card, at: 0)
                        persistCards()
                        finalCard = card
                    }
                    previewVocabCard = finalCard
                    previewGrammarCard = nil
                    isCardPreviewLoadingExamples = false
                    if finalCard.exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        cardPreviewExampleErrorMessage = created.errorMessage ?? "AI 例句暂未生成成功，请点击“重试生成例句”。"
                    }
                }
            } else if previousAction == .saved {
                // Undo: remove the card that was generated from this point
                removeVocabCardForPoint(pointId)
            }
            return
        }

        // Check grammar
        if let gi = analysisResults[resultIndex].grammarPoints.firstIndex(where: { $0.id == pointId }) {
            let previousAction = analysisResults[resultIndex].grammarPoints[gi].action
            analysisResults[resultIndex].grammarPoints[gi].action = action

            let point = analysisResults[resultIndex].grammarPoints[gi]
            persistKnowledgeMark(for: point, action: action)

            if action == .saved {
                savingKnowledgePointIDs.insert(pointId)

                let placeholderCard = GrammarCard(
                    point: point.term,
                    meaningZH: point.meaningZH,
                    toneNote: point.toneNote ?? "",
                    originalSentence: analysisResults[resultIndex].originalText,
                    exampleSentences: [("正在生成例句…", "")],
                    usageContext: point.usageNote,
                    sourcePointId: point.id
                )
                previewGrammarCard = placeholderCard
                previewVocabCard = nil
                isCardPreviewLoadingExamples = true
                cardPreviewExampleErrorMessage = nil
                showCardPreview = true

                Task { @MainActor in
                    defer { savingKnowledgePointIDs.remove(pointId) }
                    let created = await createGrammarCard(from: point, sentence: analysisResults[resultIndex].originalText)
                    let card = created.card
                    let finalCard: GrammarCard
                    if let existing = existingGrammarCard(for: point.term) {
                        finalCard = existing
                    } else {
                        grammarCards.insert(card, at: 0)
                        persistCards()
                        finalCard = card
                    }
                    previewGrammarCard = finalCard
                    previewVocabCard = nil
                    isCardPreviewLoadingExamples = false
                    if finalCard.exampleSentences.isEmpty {
                        cardPreviewExampleErrorMessage = created.errorMessage ?? "AI 例句暂未生成成功，请点击“重试生成例句”。"
                    }
                }
            } else if previousAction == .saved {
                // Undo: remove the card that was generated from this point
                removeGrammarCardForPoint(pointId)
            }
            return
        }
    }

    /// Navigate to library tab
    func navigateToLibrary() {
        navigationPath = NavigationPath()
        selectedTab = .library
    }

    /// Delete a vocabulary card
    func deleteVocabCard(_ cardId: UUID) {
        vocabularyCards.removeAll { $0.id == cardId }
        persistCards()
    }

    /// Delete a grammar card
    func deleteGrammarCard(_ cardId: UUID) {
        grammarCards.removeAll { $0.id == cardId }
        persistCards()
    }

    /// Reset analysis state for a new session
    func resetForNewSession() {
        chatBubbles = MockData.chatBubbles
        idolSide = .left
        analysisResults = []
        analysisErrorMessage = nil
        isAnalyzing = false
        retryingResultIDs = []
        checkMyReplyEnabled = true
        selectedReplyBubbleIDs = []
        replyContextBubbles = []
        replySuggestions = []
        selectedReplyTone = .natural
        replyIntentZh = ""
        isGeneratingReply = false
        replyGenerationError = nil
        myReplyCheckResults = []
        retryingReplyCheckBubbleIDs = []
        savingKnowledgePointIDs = []
        isRetryingCardPreviewExamples = false
        cardPreviewExampleErrorMessage = nil
        feedbackThreads = [:]
        feedbackSendingForResultID = nil
        feedbackErrors = [:]
        navigationPath = NavigationPath()
        selectedTab = .analysis
    }

    // MARK: - Computed Properties

    var savedCount: Int {
        analysisResults.flatMap { $0.vocabulary + $0.grammarPoints }
            .filter { $0.action == .saved }.count
    }

    var knownCount: Int {
        analysisResults.flatMap { $0.vocabulary + $0.grammarPoints }
            .filter { $0.action == .known }.count
    }

    var totalCardCount: Int {
        vocabularyCards.count + grammarCards.count
    }

    // MARK: - Private Helpers

    private func mergeWithFailurePlaceholders(results: [AnalysisResult], request: AnalysisRequest) -> [AnalysisResult] {
        let idolBubbles = request.bubbles.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.type == .text &&
            $0.side == request.idolSide
        }

        var resultsByBubbleID: [UUID: AnalysisResult] = [:]
        for result in results {
            resultsByBubbleID[result.bubbleID] = result
        }

        let total = idolBubbles.count
        let success = resultsByBubbleID.count
        let failureReason = mergeFailureReason(total: total, success: success)

        return idolBubbles.map { bubble in
            if let found = resultsByBubbleID[bubble.id] {
                return found
            }
            return makeFailedAnalysisResult(for: bubble, reason: failureReason)
        }
    }

    private func makeFailedAnalysisResult(for bubble: ChatBubble, resultID: UUID = UUID(), reason: String? = nil) -> AnalysisResult {
        let base = "该条消息解析失败，可单独重试。"
        let combinedMessage: String = {
            guard let reason, !reason.isEmpty else { return base }
            return "\(base)\n\n原因：\(reason)"
        }()
        return AnalysisResult(
            id: resultID,
            bubbleID: bubble.id,
            originalText: bubble.text,
            translationZH: "",
            toneLabels: [],
            vocabulary: [],
            grammarPoints: [],
            failureMessage: combinedMessage
        )
    }

    private func mergeFailureReason(total: Int, success: Int) -> String? {
        guard total > 0 else { return nil }
        guard success < total else { return nil }
        if success == 0 {
            return "未拿到可用解析结果，常见于模型返回结构不匹配或服务波动。"
        }
        return "仅 \(success)/\(total) 条返回可用结果，其余条目返回结构不匹配。"
    }

    private func analysisFailureReason(from error: Error) -> String {
        if let aiError = error as? AIAnalysisError {
            if let debug = aiError.debugMessage, !debug.isEmpty {
                return debug
            }
            switch aiError {
            case .unauthorized:
                return "鉴权失败（API Key 无效或权限不足）。"
            case .rateLimited:
                return "请求限流或额度不足。"
            case .serverError, .serviceUnavailable:
                return "服务暂时不可用或网络异常。"
            case .invalidResponse:
                return "返回结构不匹配，无法映射到对应消息。"
            case .timeout:
                return "请求超时。"
            case .missingAPIKey:
                return "未配置 API Key。"
            case .emptyInput:
                return "输入为空，未找到可解析文本。"
            }
        }
        return "网络或服务异常。"
    }

    /// Create a VocabularyCard from a KnowledgePoint
    private func createVocabularyCard(from point: KnowledgePoint, sentence: String) async -> (card: VocabularyCard, errorMessage: String?) {
        let example: (ko: String, zh: String)
        var errorMessage: String?
        do {
            example = try await cardExampleService.vocabularyExample(term: point.term, originalSentence: sentence)
        } catch {
            #if DEBUG
            DebugTelemetry.increment(.cardExampleFallbackTotal)
            #endif
            errorMessage = cardExampleFailureMessage(from: error)
            if let canned = MockData.vocabularyCards.first(where: { $0.word == point.term }) {
                example = (canned.exampleSentence, canned.exampleTranslationZH)
            } else {
                example = ("", "")
            }
        }

        let card = VocabularyCard(
            word: point.term,
            meaningZH: point.meaningZH,
            pronunciation: point.pronunciation ?? "",
            partOfSpeech: point.partOfSpeech ?? "",
            originalSentence: sentence,
            exampleSentence: example.ko,
            exampleTranslationZH: example.zh,
            usageNote: point.usageNote,
            sourcePointId: point.id
        )
        return (card, errorMessage)
    }

    /// Create a GrammarCard from a KnowledgePoint
    private func createGrammarCard(from point: KnowledgePoint, sentence: String) async -> (card: GrammarCard, errorMessage: String?) {
        let examples: [(ko: String, zh: String)]
        var errorMessage: String?
        do {
            examples = try await cardExampleService.grammarExamples(point: point.term, originalSentence: sentence)
        } catch {
            #if DEBUG
            DebugTelemetry.increment(.cardExampleFallbackTotal)
            #endif
            errorMessage = cardExampleFailureMessage(from: error)
            if let canned = MockData.grammarCards.first(where: { $0.point == point.term }) {
                examples = canned.exampleSentences
            } else {
                examples = []
            }
        }

        let card = GrammarCard(
            point: point.term,
            meaningZH: point.meaningZH,
            toneNote: point.toneNote ?? "",
            originalSentence: sentence,
            exampleSentences: examples,
            usageContext: point.usageNote,
            sourcePointId: point.id
        )
        return (card, errorMessage)
    }


    /// Remove a vocabulary card that was generated from a specific knowledge point
    private func removeVocabCardForPoint(_ pointId: UUID) {
        vocabularyCards.removeAll { $0.sourcePointId == pointId }
        persistCards()
    }

    /// Remove a grammar card that was generated from a specific knowledge point
    private func removeGrammarCardForPoint(_ pointId: UUID) {
        grammarCards.removeAll { $0.sourcePointId == pointId }
        persistCards()
    }

    private func persistCards() {
        cardStorageService.replaceAll(vocabularyCards: vocabularyCards, grammarCards: grammarCards)
    }

    private func persistKnowledgeMark(for point: KnowledgePoint, action: KnowledgeAction) {
        let key = knowledgeMarkKey(for: point)
        persistedKnowledgeMarks[key] = action
        cardStorageService.saveKnowledgeMark(key: key, action: action)
    }

    private func applyPersistedKnowledgeMarks(to results: [AnalysisResult]) -> [AnalysisResult] {
        results.map { result in
            var updated = result

            updated.vocabulary = result.vocabulary.map { point in
                var p = point
                let key = knowledgeMarkKey(for: p)
                if let persistedAction = persistedKnowledgeMarks[key] {
                    p.action = persistedAction
                }
                return p
            }

            updated.grammarPoints = result.grammarPoints.map { point in
                var p = point
                let key = knowledgeMarkKey(for: p)
                if let persistedAction = persistedKnowledgeMarks[key] {
                    p.action = persistedAction
                }
                return p
            }

            return updated
        }
    }

    private func knowledgeMarkKey(for point: KnowledgePoint) -> String {
        "\(point.type.rawValue)|\(point.term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    private func deduplicateKnowledgePointsGlobally(in results: [AnalysisResult]) -> [AnalysisResult] {
        var seenVocabulary = Set<String>()
        var seenGrammar = Set<String>()

        return results.map { result in
            var updated = result

            updated.vocabulary = result.vocabulary.filter { point in
                let key = globalPointDedupKey(for: point)
                if seenVocabulary.contains(key) {
                    return false
                }
                seenVocabulary.insert(key)
                return true
            }

            updated.grammarPoints = result.grammarPoints.filter { point in
                let key = globalPointDedupKey(for: point)
                if seenGrammar.contains(key) {
                    return false
                }
                seenGrammar.insert(key)
                return true
            }

            return updated
        }
    }

    @MainActor
    func retryPreviewCardExamples() async {
        guard !isCardPreviewLoadingExamples, !isRetryingCardPreviewExamples else { return }
        guard previewVocabCard != nil || previewGrammarCard != nil else { return }

        isRetryingCardPreviewExamples = true
        cardPreviewExampleErrorMessage = nil
        defer { isRetryingCardPreviewExamples = false }

        #if DEBUG
        DebugTelemetry.increment(.cardExampleRequestTotal)
        #endif

        if let card = previewVocabCard {
            do {
                let example = try await cardExampleService.vocabularyExample(
                    term: card.word,
                    originalSentence: card.originalSentence
                )
                let updated = VocabularyCard(
                    id: card.id,
                    word: card.word,
                    meaningZH: card.meaningZH,
                    pronunciation: card.pronunciation,
                    partOfSpeech: card.partOfSpeech,
                    originalSentence: card.originalSentence,
                    exampleSentence: example.ko,
                    exampleTranslationZH: example.zh,
                    usageNote: card.usageNote,
                    sourcePointId: card.sourcePointId
                )
                previewVocabCard = updated
                if let index = vocabularyCards.firstIndex(where: { $0.id == card.id }) {
                    vocabularyCards[index] = updated
                    persistCards()
                }
            } catch {
                #if DEBUG
                DebugTelemetry.increment(.cardExampleFallbackTotal)
                #endif
                cardPreviewExampleErrorMessage = cardExampleFailureMessage(from: error)
            }
            return
        }

        if let card = previewGrammarCard {
            do {
                let examples = try await cardExampleService.grammarExamples(
                    point: card.point,
                    originalSentence: card.originalSentence
                )
                let updated = GrammarCard(
                    id: card.id,
                    point: card.point,
                    meaningZH: card.meaningZH,
                    toneNote: card.toneNote,
                    originalSentence: card.originalSentence,
                    exampleSentences: examples,
                    usageContext: card.usageContext,
                    sourcePointId: card.sourcePointId
                )
                previewGrammarCard = updated
                if let index = grammarCards.firstIndex(where: { $0.id == card.id }) {
                    grammarCards[index] = updated
                    persistCards()
                }
            } catch {
                #if DEBUG
                DebugTelemetry.increment(.cardExampleFallbackTotal)
                #endif
                cardPreviewExampleErrorMessage = cardExampleFailureMessage(from: error)
            }
        }
    }

    private func cardExampleFailureMessage(from error: Error) -> String {
        if let cardError = error as? CardExampleError {
            let base = cardError.errorDescription ?? "例句生成失败，请稍后再试。"
            switch cardError {
            case .invalidResponse(let message):
                if let message, !message.isEmpty {
                    return "\(base)\n\n原因：\(message)"
                }
                return base
            case .serviceUnavailable(let message),
                 .unauthorized(let message),
                 .rateLimited(let message),
                 .serverError(let message):
                if let message, !message.isEmpty {
                    return "\(base)\n\n原因：\(message)"
                }
                return base
            default:
                return base
            }
        }
        return "例句生成失败，请稍后再试。"
    }

    private func globalPointDedupKey(for point: KnowledgePoint) -> String {
        let normalizedTerm = point.term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedMeaning = point.meaningZH.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(point.type.rawValue)|\(normalizedTerm)|\(normalizedMeaning)"
    }

    private func existingVocabularyCard(for term: String) -> VocabularyCard? {
        let normalized = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return vocabularyCards.first {
            $0.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    private func existingGrammarCard(for term: String) -> GrammarCard? {
        let normalized = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return grammarCards.first {
            $0.point.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    #if DEBUG
    func clearAllLocalDataForDebug() {
        cardStorageService.clearAllPersistedData()
        UserDefaults.standard.removeObject(forKey: onboardingKey)

        hasCompletedOnboarding = false
        vocabularyCards = []
        grammarCards = []
        persistedKnowledgeMarks = [:]
        resetForNewSession()
        lastDebugClearAt = Date()
    }
    #endif
}

// MARK: - Navigation Routes

enum AnalysisRoute: Hashable {
    case textConfirmation
    case analysisLoading
    case analysisResult
    case replySuggestion
}
