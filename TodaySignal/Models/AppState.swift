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

    // MARK: - Analysis Results

    var analysisResults: [AnalysisResult] = []
    var isAnalyzing = false
    var analysisErrorMessage: String?
    var retryingResultIDs: Set<UUID> = []

    private let aiAnalysisService: AIAnalysisServicing
    private let cardStorageService: CardStorageService
    private var persistedKnowledgeMarks: [String: KnowledgeAction]

    private let onboardingKey = "today_signal_onboarding_completed"

    #if DEBUG
    var lastDebugClearAt: Date?
    #endif

    init(
        aiAnalysisService: AIAnalysisServicing = AIAnalysisServiceFactory.makeDefaultService(),
        cardStorageService: CardStorageService = .shared
    ) {
        self.aiAnalysisService = aiAnalysisService
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
                analysisResults[resultIndex] = makeFailedAnalysisResult(for: bubble, resultID: current.id)
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
                    grammarPoints: first.grammarPoints,
                    isUserReply: false
                )
            ])[0]
            analysisResults = deduplicateKnowledgePointsGlobally(in: analysisResults)
        } catch {
            analysisResults[resultIndex] = makeFailedAnalysisResult(for: bubble, resultID: current.id)
        }
    }

    /// Update a knowledge point's action state
    func updateKnowledgeAction(resultIndex: Int, pointId: UUID, action: KnowledgeAction) {
        guard resultIndex < analysisResults.count else { return }

        // Check vocabulary
        if let vi = analysisResults[resultIndex].vocabulary.firstIndex(where: { $0.id == pointId }) {
            let previousAction = analysisResults[resultIndex].vocabulary[vi].action
            analysisResults[resultIndex].vocabulary[vi].action = action

            let point = analysisResults[resultIndex].vocabulary[vi]
            persistKnowledgeMark(for: point, action: action)

            if action == .saved {
                let card = createVocabularyCard(from: point, sentence: analysisResults[resultIndex].originalText)
                vocabularyCards.insert(card, at: 0)
                persistCards()
                previewVocabCard = card
                previewGrammarCard = nil
                showCardPreview = true
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
                let card = createGrammarCard(from: point, sentence: analysisResults[resultIndex].originalText)
                grammarCards.insert(card, at: 0)
                persistCards()
                previewGrammarCard = card
                previewVocabCard = nil
                showCardPreview = true
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

        return idolBubbles.map { bubble in
            if let found = resultsByBubbleID[bubble.id] {
                return found
            }
            return makeFailedAnalysisResult(for: bubble)
        }
    }

    private func makeFailedAnalysisResult(for bubble: ChatBubble, resultID: UUID = UUID()) -> AnalysisResult {
        AnalysisResult(
            id: resultID,
            bubbleID: bubble.id,
            originalText: bubble.text,
            translationZH: "",
            toneLabels: [],
            vocabulary: [],
            grammarPoints: [],
            isUserReply: false,
            failureMessage: "该条消息解析失败，可单独重试。"
        )
    }

    /// Create a VocabularyCard from a KnowledgePoint
    private func createVocabularyCard(from point: KnowledgePoint, sentence: String) -> VocabularyCard {
        VocabularyCard(
            word: point.term,
            meaningZH: point.meaningZH,
            pronunciation: point.pronunciation ?? "",
            partOfSpeech: point.partOfSpeech ?? "",
            originalSentence: sentence,
            exampleSentence: "예문이 곧 생성됩니다.",
            exampleTranslationZH: "例句即将生成。",
            usageNote: point.usageNote,
            sourcePointId: point.id
        )
    }

    /// Create a GrammarCard from a KnowledgePoint
    private func createGrammarCard(from point: KnowledgePoint, sentence: String) -> GrammarCard {
        GrammarCard(
            point: point.term,
            meaningZH: point.meaningZH,
            toneNote: point.toneNote ?? "",
            originalSentence: sentence,
            exampleSentences: [],
            usageContext: point.usageNote,
            sourcePointId: point.id
        )
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
                if let persistedAction = persistedKnowledgeMarks[key], persistedAction != .saved {
                    p.action = persistedAction
                }
                return p
            }

            updated.grammarPoints = result.grammarPoints.map { point in
                var p = point
                let key = knowledgeMarkKey(for: p)
                if let persistedAction = persistedKnowledgeMarks[key], persistedAction != .saved {
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

    private func globalPointDedupKey(for point: KnowledgePoint) -> String {
        let normalizedTerm = point.term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedMeaning = point.meaningZH.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(point.type.rawValue)|\(normalizedTerm)|\(normalizedMeaning)"
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
}
