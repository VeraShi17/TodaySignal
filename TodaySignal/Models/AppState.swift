import SwiftUI

/// Shared app state that connects all views in the analysis flow.
/// Uses @Observable (iOS 17+) for automatic SwiftUI updates.
@Observable
class AppState {

    // MARK: - Onboarding

    var hasCompletedOnboarding = false

    // MARK: - Text Confirmation (input stage)

    var chatBubbles: [ChatBubble] = MockData.chatBubbles
    var idolSide: BubbleSide = .left

    // MARK: - Analysis Results

    var analysisResults: [AnalysisResult] = []
    var isAnalyzing = false
    var analysisErrorMessage: String?

    private let aiAnalysisService: AIAnalysisServicing

    init(aiAnalysisService: AIAnalysisServicing = AIAnalysisServiceFactory.makeDefaultService()) {
        self.aiAnalysisService = aiAnalysisService
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
    func startAnalysis() async {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        analysisErrorMessage = nil

        defer { isAnalyzing = false }

        do {
            let request = AnalysisRequest(bubbles: chatBubbles, idolSide: idolSide)
            let results = try await aiAnalysisService.analyze(request: request)
            analysisResults = results
            navigationPath.append(AnalysisRoute.analysisResult)
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
        }
    }

    func clearAnalysisError() {
        analysisErrorMessage = nil
    }

    /// Update a knowledge point's action state
    func updateKnowledgeAction(resultIndex: Int, pointId: UUID, action: KnowledgeAction) {
        guard resultIndex < analysisResults.count else { return }

        // Check vocabulary
        if let vi = analysisResults[resultIndex].vocabulary.firstIndex(where: { $0.id == pointId }) {
            let previousAction = analysisResults[resultIndex].vocabulary[vi].action
            analysisResults[resultIndex].vocabulary[vi].action = action

            if action == .saved {
                let point = analysisResults[resultIndex].vocabulary[vi]
                let card = createVocabularyCard(from: point, sentence: analysisResults[resultIndex].originalText)
                vocabularyCards.insert(card, at: 0)
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

            if action == .saved {
                let point = analysisResults[resultIndex].grammarPoints[gi]
                let card = createGrammarCard(from: point, sentence: analysisResults[resultIndex].originalText)
                grammarCards.insert(card, at: 0)
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
    }

    /// Delete a grammar card
    func deleteGrammarCard(_ cardId: UUID) {
        grammarCards.removeAll { $0.id == cardId }
    }

    /// Reset analysis state for a new session
    func resetForNewSession() {
        chatBubbles = MockData.chatBubbles
        idolSide = .left
        analysisResults = []
        analysisErrorMessage = nil
        isAnalyzing = false
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
    }

    /// Remove a grammar card that was generated from a specific knowledge point
    private func removeGrammarCardForPoint(_ pointId: UUID) {
        grammarCards.removeAll { $0.sourcePointId == pointId }
    }
}

// MARK: - Navigation Routes

enum AnalysisRoute: Hashable {
    case textConfirmation
    case analysisResult
}
