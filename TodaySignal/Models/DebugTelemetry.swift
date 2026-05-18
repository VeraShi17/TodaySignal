import Foundation

#if DEBUG
enum DebugTelemetry {
    private static let prefix = "debug.telemetry"

    enum Counter: String, CaseIterable {
        case feedbackEmptyAnswer = "feedback.empty_answer"
        case feedbackAnswerTooLong = "feedback.answer_too_long"
        case feedbackTooGeneric = "feedback.too_generic"

        case replyItemCountMismatch = "reply.item_count_mismatch"
        case replyEmptyField = "reply.empty_field"
        case replyTooLong = "reply.too_long"
        case replyMissingHangul = "reply.missing_hangul"
        case replyDuplicateReply = "reply.duplicate_reply"

        case replyCheckItemCountMismatch = "reply_check.item_count_mismatch"
        case replyCheckEmptyFeedback = "reply_check.empty_feedback"
        case replyCheckNaturalHasSuggestion = "reply_check.natural_has_suggestion"
        case replyCheckNeedsSuggestionMissing = "reply_check.needs_suggestion_missing"
        case replyCheckSuggestionMissingHangul = "reply_check.suggestion_missing_hangul"
        case replyCheckSuggestionTooLong = "reply_check.suggestion_too_long"

        case replyCheckRequestTotal = "reply_check.request_total"
        case replyCheckFallbackTotal = "reply_check.fallback_total"

        case feedbackRequestTotal = "feedback.request_total"
        case feedbackFallbackTotal = "feedback.fallback_total"

        case replySuggestionRequestTotal = "reply_suggestion.request_total"
        case replySuggestionFallbackTotal = "reply_suggestion.fallback_total"

        case cardExampleRequestTotal = "card_example.request_total"
        case cardExampleFallbackTotal = "card_example.fallback_total"
    }

    static func increment(_ counter: Counter) {
        let key = storageKey(for: counter)
        let next = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(next, forKey: key)
    }

    static func value(for counter: Counter) -> Int {
        UserDefaults.standard.integer(forKey: storageKey(for: counter))
    }

    static func snapshot() -> [(counter: Counter, value: Int)] {
        Counter.allCases.map { ($0, value(for: $0)) }
    }

    static func resetAll() {
        for counter in Counter.allCases {
            UserDefaults.standard.removeObject(forKey: storageKey(for: counter))
        }
    }

    private static func storageKey(for counter: Counter) -> String {
        "\(prefix).\(counter.rawValue)"
    }
}
#endif
