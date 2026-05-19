import Foundation
import Testing
@testable import TodaySignal

struct ServiceContractsTests {

    @Test("MockReplySuggestion: empty input should throw emptyContext")
    func mockReplySuggestionEmptyInputThrows() async {
        let service = MockReplySuggestionService()
        do {
            _ = try await service.generateReplies(contextBubbles: [], intentZh: "   ", tone: .natural)
            Issue.record("Expected emptyContext error")
        } catch let error as ReplySuggestionError {
            if case .emptyContext = error {
                #expect(Bool(true))
            } else {
                Issue.record("Expected emptyContext, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("MockReplySuggestion: returns 3 replies and preserves selected tone")
    func mockReplySuggestionToneAndCount() async throws {
        let service = MockReplySuggestionService()
        let bubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?"),
            ChatBubble(side: .left, speakerRole: .idol, text: "밥 먹었어?")
        ]

        let dataset: [(tone: ReplyTone, intent: String)] = [
            (.natural, "想说今天也辛苦了"),
            (.cute, "想可爱一点"),
            (.polite, "想更礼貌一点")
        ]

        var passCount = 0

        for item in dataset {
            let replies = try await service.generateReplies(contextBubbles: bubbles, intentZh: item.intent, tone: item.tone)
            let allValid = replies.count == 3
                && replies.allSatisfy { !$0.replyKo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                && replies.allSatisfy { !$0.replyZh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                && replies.allSatisfy { $0.tone == item.tone }
            if allValid {
                passCount += 1
            }
        }

        let passRate = Double(passCount) / Double(dataset.count)
        #expect(passRate == 1.0)
    }

    @Test("MockFeedbackChat: empty question should throw emptyQuestion")
    func mockFeedbackEmptyQuestionThrows() async {
        let service = MockFeedbackChatService()
        let context = FeedbackChatContext(
            focusedText: "오늘 뭐해?",
            focusedTranslationZH: "今天在干嘛？",
            focusedToneLabels: [.casual],
            focusedVocabulary: [],
            focusedGrammarPoints: [],
            nearbyBubbleTexts: [],
            myReplyCheck: nil
        )

        do {
            _ = try await service.ask(question: "   ", context: context)
            Issue.record("Expected emptyQuestion error")
        } catch let error as FeedbackChatError {
            if case .emptyQuestion = error {
                #expect(Bool(true))
            } else {
                Issue.record("Expected emptyQuestion, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("MockCardExample: canned + fallback output contracts")
    func mockCardExampleContracts() async throws {
        let service = MockCardExampleService()

        let canned = try await service.vocabularyExample(term: "오늘", originalSentence: "오늘 뭐해?")
        #expect(!canned.ko.isEmpty)
        #expect(!canned.zh.isEmpty)

        let fallback = try await service.vocabularyExample(term: "不存在词条", originalSentence: "원문")
        #expect(fallback.ko == "원문")
        #expect(fallback.zh.contains("不存在词条"))

        let grammar = try await service.grammarExamples(point: "-해?", originalSentence: "오늘 뭐해?")
        #expect(!grammar.isEmpty)
        #expect(grammar.count <= 2)
        #expect(grammar.allSatisfy { !$0.ko.isEmpty && !$0.zh.isEmpty })
    }

    @Test("AppState ReplyCheck: failure should create per-bubble visible placeholders")
    @MainActor
    func appStateReplyCheckFailureCreatesPlaceholders() async {
        let appState = AppState(
            aiAnalysisService: MockAIAnalysisService(),
            replySuggestionService: MockReplySuggestionService(),
            replyCheckService: AlwaysFailReplyCheckService(),
            feedbackChatService: MockFeedbackChatService(),
            cardExampleService: MockCardExampleService(),
            cardStorageService: .shared
        )

        appState.idolSide = .left
        appState.checkMyReplyEnabled = true
        appState.chatBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?"),
            ChatBubble(side: .right, speakerRole: .user, text: "나 지금 공부 중이야"),
            ChatBubble(side: .right, speakerRole: .user, text: "잠깐 쉬는 중")
        ]

        await appState.loadMyReplyCheckIfNeeded()

        #expect(appState.myReplyCheckResults.count == 2)
        #expect(appState.myReplyCheckResults.allSatisfy { $0.failureMessage != nil })
    }

    @Test("AppState ReplyCheck: retry single bubble should update only that bubble")
    @MainActor
    func appStateReplyCheckSingleRetry() async {
        let service = ScriptedReplyCheckService()
        let appState = AppState(
            aiAnalysisService: MockAIAnalysisService(),
            replySuggestionService: MockReplySuggestionService(),
            replyCheckService: service,
            feedbackChatService: MockFeedbackChatService(),
            cardExampleService: MockCardExampleService(),
            cardStorageService: .shared
        )

        appState.idolSide = .left
        appState.checkMyReplyEnabled = true
        let userBubble1 = ChatBubble(side: .right, speakerRole: .user, text: "나 지금 공부 중이야")
        let userBubble2 = ChatBubble(side: .right, speakerRole: .user, text: "잠깐 쉬는 중")
        appState.chatBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?"),
            userBubble1,
            userBubble2
        ]

        await appState.loadMyReplyCheckIfNeeded()
        #expect(appState.myReplyCheckResults.allSatisfy { $0.failureMessage != nil })

        await appState.retryMyReplyCheck(for: userBubble1.id)

        let updated1 = appState.myReplyCheckResults.first(where: { $0.bubbleID == userBubble1.id })
        let unchanged2 = appState.myReplyCheckResults.first(where: { $0.bubbleID == userBubble2.id })

        #expect(updated1?.failureMessage == nil)
        #expect(updated1?.status == .natural)
        #expect(unchanged2?.failureMessage != nil)
    }
}

private struct AlwaysFailReplyCheckService: ReplyCheckServicing {
    func checkReplies(myBubbles: [ChatBubble], idolContext: [ChatBubble]) async throws -> [ReplyCheckResult] {
        throw ReplyCheckError.timeout
    }
}

private final class ScriptedReplyCheckService: ReplyCheckServicing {
    private var hasFailedInitialBatch = false

    func checkReplies(myBubbles: [ChatBubble], idolContext: [ChatBubble]) async throws -> [ReplyCheckResult] {
        if myBubbles.count > 1, !hasFailedInitialBatch {
            hasFailedInitialBatch = true
            throw ReplyCheckError.timeout
        }

        return myBubbles.map { bubble in
            ReplyCheckResult(
                bubbleID: bubble.id,
                originalReply: bubble.text,
                status: .natural,
                feedbackZh: "这句表达自然。",
                issueZh: nil,
                suggestedReplyKo: nil,
                suggestedReplyZh: nil,
                failureMessage: nil
            )
        }
    }
}

// MARK: - V1 AppState Flow Contracts

struct AppStateV1FlowTests {

    // MARK: ReplySuggestion flow

    @Test("AppState ReplySuggestion: prepareReplyContextFromSelection with empty selection returns false")
    @MainActor
    func prepareReplyContextEmptyReturnsFalse() {
        let appState = makeAppState()
        appState.chatBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        appState.selectedReplyBubbleIDs = []

        let result = appState.prepareReplyContextFromSelection()

        #expect(result == false)
        #expect(appState.replyContextBubbles.isEmpty)
    }

    @Test("AppState ReplySuggestion: prepareReplyContextFromSelection seeds context and resets transient state")
    @MainActor
    func prepareReplyContextWithSelectionResetsState() {
        let appState = makeAppState()
        let bubble = ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        appState.chatBubbles = [bubble]
        appState.selectedReplyBubbleIDs = [bubble.id]
        appState.replyIntentZh = "stale intent"
        appState.selectedReplyTone = .cute
        appState.replySuggestions = [
            ReplySuggestion(replyKo: "stale", replyZh: "stale", tone: .cute, noteZh: "stale")
        ]

        let result = appState.prepareReplyContextFromSelection()

        #expect(result == true)
        #expect(appState.replyContextBubbles.count == 1)
        #expect(appState.replyContextBubbles.first?.id == bubble.id)
        #expect(appState.replyIntentZh.isEmpty)
        #expect(appState.selectedReplyTone == .natural)
        #expect(appState.replySuggestions.isEmpty)
    }

    @Test("AppState ReplySuggestion: prepareReplyContextFromHomeEntry clears all reply state")
    @MainActor
    func prepareReplyContextFromHomeClearsState() {
        let appState = makeAppState()
        appState.replyContextBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        appState.replyIntentZh = "stale intent"
        appState.selectedReplyTone = .friendly
        appState.replySuggestions = [
            ReplySuggestion(replyKo: "stale", replyZh: "stale", tone: .friendly, noteZh: "stale")
        ]

        appState.prepareReplyContextFromHomeEntry()

        #expect(appState.replyContextBubbles.isEmpty)
        #expect(appState.replyIntentZh.isEmpty)
        #expect(appState.selectedReplyTone == .natural)
        #expect(appState.replySuggestions.isEmpty)
    }

    @Test("AppState ReplySuggestion: generateReplySuggestions success populates 3 replies and clears error")
    @MainActor
    func generateReplySuggestionsSuccess() async {
        let appState = makeAppState()
        appState.replyContextBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        appState.selectedReplyTone = .polite
        appState.replyGenerationError = "stale error"

        await appState.generateReplySuggestions()

        #expect(appState.replySuggestions.count == 3)
        #expect(appState.replySuggestions.allSatisfy { $0.tone == .polite })
        #expect(appState.replyGenerationError == nil)
        #expect(appState.isGeneratingReply == false)
    }

    @Test("AppState ReplySuggestion: failure clears suggestions and exposes error message")
    @MainActor
    func generateReplySuggestionsFailure() async {
        let appState = makeAppState(replySuggestionService: AlwaysFailReplySuggestionService())
        appState.replyContextBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        appState.replySuggestions = [
            ReplySuggestion(replyKo: "stale", replyZh: "stale", tone: .natural, noteZh: "stale")
        ]

        await appState.generateReplySuggestions()

        #expect(appState.replySuggestions.isEmpty)
        #expect(appState.replyGenerationError != nil)
        #expect(appState.isGeneratingReply == false)
    }

    // MARK: FeedbackChat flow

    @Test("AppState FeedbackChat: empty question is a no-op")
    @MainActor
    func feedbackEmptyQuestionIsNoOp() async {
        let appState = makeAppState()
        let result = seedAnalysisResult(in: appState)

        await appState.sendFeedback(question: "   ", forResultID: result.id)

        #expect(appState.feedbackThreads[result.id]?.isEmpty ?? true)
        #expect(appState.feedbackErrors[result.id] == nil)
        #expect(appState.feedbackSendingForResultID == nil)
    }

    @Test("AppState FeedbackChat: unknown resultID does not mutate any thread")
    @MainActor
    func feedbackUnknownResultIDIsNoOp() async {
        let appState = makeAppState()
        let result = seedAnalysisResult(in: appState)
        let unknownID = UUID()

        await appState.sendFeedback(question: "이게 왜 이렇게 말해?", forResultID: unknownID)

        #expect(appState.feedbackThreads[unknownID] == nil)
        #expect(appState.feedbackThreads[result.id] == nil)
        #expect(appState.feedbackErrors.isEmpty)
    }

    @Test("AppState FeedbackChat: success appends user question and AI reply in order")
    @MainActor
    func feedbackSuccessAppendsBothMessages() async {
        let appState = makeAppState()
        let result = seedAnalysisResult(in: appState)

        await appState.sendFeedback(question: "이게 왜 반말이야?", forResultID: result.id)

        let thread = appState.feedbackThreads[result.id] ?? []
        #expect(thread.count == 2)
        #expect(thread.first?.isUser == true)
        #expect(thread.first?.text == "이게 왜 반말이야?")
        #expect(thread.last?.isUser == false)
        #expect(appState.feedbackErrors[result.id] == nil)
    }

    @Test("AppState FeedbackChat: failure keeps user message and surfaces error")
    @MainActor
    func feedbackFailureSetsError() async {
        let appState = makeAppState(feedbackChatService: AlwaysFailFeedbackChatService())
        let result = seedAnalysisResult(in: appState)

        await appState.sendFeedback(question: "이게 왜 반말이야?", forResultID: result.id)

        let thread = appState.feedbackThreads[result.id] ?? []
        #expect(thread.count == 1)
        #expect(thread.first?.isUser == true)
        #expect(appState.feedbackErrors[result.id] != nil)
    }

    // MARK: Bubble selection + helpers

    @Test("AppState BubbleSelection: toggle adds then removes from selection")
    @MainActor
    func toggleReplyBubbleSelectionAddsAndRemoves() {
        let appState = makeAppState()
        let bubble = ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        appState.chatBubbles = [bubble]

        appState.toggleReplyBubbleSelection(bubble.id)
        #expect(appState.selectedReplyBubbleIDs.contains(bubble.id))

        appState.toggleReplyBubbleSelection(bubble.id)
        #expect(appState.selectedReplyBubbleIDs.contains(bubble.id) == false)
    }

    @Test("AppState BubbleSelection: hasMySideBubbles reflects current idolSide")
    @MainActor
    func hasMySideBubblesReflectsIdolSide() {
        let appState = makeAppState()
        appState.idolSide = .left
        appState.chatBubbles = [
            ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        #expect(appState.hasMySideBubbles() == false)

        appState.chatBubbles.append(
            ChatBubble(side: .right, speakerRole: .user, text: "나 지금 공부 중")
        )
        #expect(appState.hasMySideBubbles() == true)

        // Swap idol side: now the previously user-side bubble becomes idol-side, so my-side disappears.
        appState.idolSide = .right
        appState.chatBubbles = [
            ChatBubble(side: .right, speakerRole: .idol, text: "오늘 뭐해?")
        ]
        #expect(appState.hasMySideBubbles() == false)
    }

    // MARK: Helpers

    @MainActor
    private func makeAppState(
        replySuggestionService: ReplySuggestionServicing = MockReplySuggestionService(),
        feedbackChatService: FeedbackChatServicing = MockFeedbackChatService()
    ) -> AppState {
        AppState(
            aiAnalysisService: MockAIAnalysisService(),
            replySuggestionService: replySuggestionService,
            replyCheckService: AlwaysFailReplyCheckService(),
            feedbackChatService: feedbackChatService,
            cardExampleService: MockCardExampleService(),
            cardStorageService: .shared
        )
    }

    @MainActor
    private func seedAnalysisResult(in appState: AppState) -> AnalysisResult {
        let bubble = ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해?")
        let result = AnalysisResult(
            bubbleID: bubble.id,
            originalText: bubble.text,
            translationZH: "今天在干嘛？",
            toneLabels: [.casual],
            vocabulary: [],
            grammarPoints: []
        )
        appState.chatBubbles = [bubble]
        appState.analysisResults = [result]
        return result
    }
}

private struct AlwaysFailReplySuggestionService: ReplySuggestionServicing {
    func generateReplies(contextBubbles: [ChatBubble], intentZh: String?, tone: ReplyTone) async throws -> [ReplySuggestion] {
        throw ReplySuggestionError.timeout
    }
}

private struct AlwaysFailFeedbackChatService: FeedbackChatServicing {
    func ask(question: String, context: FeedbackChatContext) async throws -> FeedbackMessage {
        throw FeedbackChatError.timeout
    }
}
