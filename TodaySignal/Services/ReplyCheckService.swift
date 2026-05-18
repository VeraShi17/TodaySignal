import Foundation
import os

enum ReplyCheckError: LocalizedError {
    case timeout
    case missingAPIKey
    case unauthorized(message: String?)
    case rateLimited(message: String?)
    case serverError(message: String?)
    case serviceUnavailable(message: String?)
    case invalidResponse(message: String?)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "我的回复检查超时，请稍后重试。"
        case .missingAPIKey:
            return "未配置 OpenAI API Key。"
        case .unauthorized:
            return "API Key 无效或权限不足（401）。"
        case .rateLimited:
            return "请求过于频繁或额度不足（429），请稍后再试。"
        case .serverError:
            return "OpenAI 服务暂时不可用（5xx），请稍后重试。"
        case .serviceUnavailable:
            return "我的回复检查服务暂时不可用，请稍后重试。"
        case .invalidResponse:
            return "检查结果格式异常，请重试。"
        }
    }

    var debugMessage: String? {
        switch self {
        case .unauthorized(let message),
             .rateLimited(let message),
             .serverError(let message),
             .serviceUnavailable(let message),
             .invalidResponse(let message):
            return message
        default:
            return nil
        }
    }
}

protocol ReplyCheckServicing {
    func checkReplies(myBubbles: [ChatBubble], idolContext: [ChatBubble]) async throws -> [ReplyCheckResult]
}

struct MockReplyCheckService: ReplyCheckServicing {
    func checkReplies(myBubbles: [ChatBubble], idolContext: [ChatBubble]) async throws -> [ReplyCheckResult] {
        try await Task.sleep(for: .milliseconds(500))

        return myBubbles.enumerated().map { index, bubble in
            // Alternate natural / needs-improvement so the UI shows both states in mock mode.
            let natural = index % 2 == 0
            if natural {
                return ReplyCheckResult(
                    bubbleID: bubble.id,
                    originalReply: bubble.text,
                    status: .natural,
                    feedbackZh: "这句表达自然，没有明显问题。语气合适，适合粉丝回复 idol。",
                    issueZh: nil,
                    suggestedReplyKo: nil,
                    suggestedReplyZh: nil
                )
            } else {
                return ReplyCheckResult(
                    bubbleID: bubble.id,
                    originalReply: bubble.text,
                    status: .needsImprovement,
                    feedbackZh: "意思能理解，但在粉丝回复 idol 的语境中稍微有点直接。",
                    issueZh: "建议换成更常见的粉丝表达，既自然又不冒犯边界。",
                    suggestedReplyKo: "항상 응원하고 있어요!",
                    suggestedReplyZh: "我一直都在为你应援！"
                )
            }
        }
    }
}

struct OpenAIReplyCheckService: ReplyCheckServicing {
    private let apiKey: String
    private let model: String
    private let showDebugErrorDetails: Bool
    private let logger = Logger(subsystem: "TodaySignal", category: "ReplyCheck")

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw ReplyCheckError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func checkReplies(myBubbles: [ChatBubble], idolContext: [ChatBubble]) async throws -> [ReplyCheckResult] {
        guard !myBubbles.isEmpty else { return [] }

        #if DEBUG
        DebugTelemetry.increment(.replyCheckRequestTotal)
        #endif

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": buildUserContent(myBubbles: myBubbles, idolContext: idolContext)]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "reply_check_output",
                    "strict": true,
                    "schema": responseSchema
                ]
            ],
            "temperature": 0.2
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = body
        urlRequest.timeoutInterval = 60

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 65
        let session = URLSession(configuration: sessionConfig)

        do {
            let startedAt = Date()
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw ReplyCheckError.serviceUnavailable(message: "Invalid HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let serverMessage = extractOpenAIErrorMessage(from: data)
                logger.error("Reply check failed. status=\(http.statusCode)")
                throw mapStatusCodeToError(http.statusCode, serverMessage: serverMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAIReplyCheckChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw ReplyCheckError.invalidResponse(message: "Missing choices[0].message.content")
            }

            let parsed = try JSONDecoder().decode(OpenAIReplyCheckEnvelope.self, from: Data(content.utf8))
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.info("Reply check succeeded. count=\(parsed.items.count), elapsed=\(elapsed, format: .fixed(precision: 3))s")

            let validation = validateItems(parsed.items, expectedCount: myBubbles.count)
            if let results = validation.results {
                return zip(myBubbles, results).map { bubble, result in
                    ReplyCheckResult(
                        bubbleID: bubble.id,
                        originalReply: bubble.text,
                        status: result.status,
                        feedbackZh: result.feedbackZh,
                        issueZh: result.issueZh,
                        suggestedReplyKo: result.suggestedReplyKo,
                        suggestedReplyZh: result.suggestedReplyZh
                    )
                }
            }

            logger.error("Reply check fallback applied. reason=\(validation.reason?.rawValue ?? "unknown")")
            #if DEBUG
            DebugTelemetry.increment(.replyCheckFallbackTotal)
            if let reason = validation.reason {
                trackValidationFailure(reason)
            }
            #endif
            return fallbackResults(for: myBubbles)
        } catch let error as ReplyCheckError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw ReplyCheckError.timeout
        } catch let error as URLError {
            throw ReplyCheckError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            throw ReplyCheckError.invalidResponse(message: error.localizedDescription)
        }
    }

    private var systemPrompt: String {
        """
        你是面向中文母语者的韩语聊天回复检查助手。
        你的任务是判断“用户已经发出或准备发出的韩语回复”是否自然、得体、符合当前聊天语境。

        场景：
        - 用户是粉丝，对方可能是 idol / 博主 / 朋友式聊天对象。
        - idol_context 只用于理解上下文语气和对方在说什么。
        - 不要脱离 my_replies 自行扩展剧情，不要编造截图中没有的信息。

        判断原则（逐条 my_replies）：
        1) 优先判断这句能不能自然发出去，而不是追求最完美表达。
        2) 只有当表达明显不自然、语法或词尾错误、搭配奇怪、礼貌程度不合适、语气越界或容易误解时，才标记为 "needs_improvement"。
        3) 如果原句可以理解，也像真实聊天中会出现的韩语，即使还有更地道的说法，也标记为 "natural"。
        4) 如果句子已自然，不要硬改，不要为了提供建议而强行判错。
        5) 如果用户混用了中文、英文、emoji、ㅋㅋ、ㅎㅎ、ㅠㅠ、~，只要在聊天里自然，就不要当作错误。
        6) 粉丝与 idol 场景中要保持边界：避免过度亲密、控制欲、现实情侣式要求、露骨或冒犯表达。
        7) 对平语与敬语要结合语境判断：若像朋友式互动，平语不一定错误；若可能显得太直接，请温和说明。
        8) 如果 my_replies 看起来像 OCR 误识别导致的明显乱码或残缺，不要强行解释；标记为 "needs_improvement"，并在 issue_zh 里提示“可能是识别错误，建议先检查原文”。

        输出要求：
        - 返回 items，长度必须与 my_replies 完全一致，顺序一致。
        - status 仅可为 "natural" 或 "needs_improvement"。
        - feedback_zh：简短、温和、可执行，说明为什么自然或哪里需要调整。
        - 若 status = "natural"：issue_zh / suggested_reply_ko / suggested_reply_zh 必须为空字符串。
        - 若 status = "needs_improvement"：必须给出 issue_zh、suggested_reply_ko、suggested_reply_zh。
        - suggested_reply_ko 必须是可直接发送的自然韩语，通常 1 句，最多 2 句。
        - suggested_reply_zh 必须是 suggested_reply_ko 的中文意思。
        - 不要生成露骨、冒犯、控制欲或现实情侣式要求表达。
        - 只输出 JSON，不要输出额外文本。
        """
    }

    private func buildUserContent(myBubbles: [ChatBubble], idolContext: [ChatBubble]) -> String {
        var lines: [String] = []
        lines.append("idol_context:")
        let validIdolBubbles = idolContext.filter { !$0.text.isEmpty && $0.type == .text }
        if validIdolBubbles.isEmpty {
            lines.append("(无)")
        } else {
            for bubble in validIdolBubbles {
                lines.append("[opponent] \(bubble.text)")
            }
        }

        lines.append("")
        lines.append("my_replies:")
        for (index, bubble) in myBubbles.enumerated() {
            lines.append("[\(index)] [me] \(bubble.text)")
        }
        return lines.joined(separator: "\n")
    }

    private var responseSchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "items": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "status": [
                                "type": "string",
                                "enum": ["natural", "needs_improvement"]
                            ],
                            "feedback_zh": ["type": "string"],
                            "issue_zh": ["type": "string"],
                            "suggested_reply_ko": ["type": "string"],
                            "suggested_reply_zh": ["type": "string"]
                        ],
                        "required": ["status", "feedback_zh", "issue_zh", "suggested_reply_ko", "suggested_reply_zh"]
                    ]
                ]
            ],
            "required": ["items"]
        ]
    }

    private func mapStatusCodeToError(_ statusCode: Int, serverMessage: String?) -> ReplyCheckError {
        let debugSuffix: String? = {
            guard showDebugErrorDetails else { return nil }
            guard let serverMessage, !serverMessage.isEmpty else { return "HTTP \(statusCode)" }
            return "HTTP \(statusCode): \(serverMessage)"
        }()

        switch statusCode {
        case 401, 403:
            return .unauthorized(message: debugSuffix)
        case 429:
            return .rateLimited(message: debugSuffix)
        case 500...599:
            return .serverError(message: debugSuffix)
        default:
            return .serviceUnavailable(message: debugSuffix)
        }
    }

    private func extractOpenAIErrorMessage(from data: Data) -> String? {
        guard let payload = try? JSONDecoder().decode(OpenAIReplyCheckErrorEnvelope.self, from: data) else {
            return nil
        }
        return payload.error.message
    }

    private func validateItems(_ items: [OpenAIReplyCheckItem], expectedCount: Int) -> ReplyCheckValidationResult {
        guard items.count == expectedCount else {
            return ReplyCheckValidationResult(results: nil, reason: .itemCountMismatch)
        }

        var results: [ValidatedReplyCheckItem] = []

        for item in items {
            let feedbackZh = item.feedbackZh.trimmingCharacters(in: .whitespacesAndNewlines)
            let issueZh = item.issueZh.trimmingCharacters(in: .whitespacesAndNewlines)
            let suggestedKo = item.suggestedReplyKo.trimmingCharacters(in: .whitespacesAndNewlines)
            let suggestedZh = item.suggestedReplyZh.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !feedbackZh.isEmpty else {
                return ReplyCheckValidationResult(results: nil, reason: .emptyFeedback)
            }

            guard feedbackZh.count <= 140, issueZh.count <= 140, suggestedKo.count <= 120, suggestedZh.count <= 120 else {
                return ReplyCheckValidationResult(results: nil, reason: .suggestionTooLong)
            }

            if item.status == "natural" {
                if !issueZh.isEmpty || !suggestedKo.isEmpty || !suggestedZh.isEmpty {
                    return ReplyCheckValidationResult(results: nil, reason: .naturalHasSuggestion)
                }

                results.append(
                    ValidatedReplyCheckItem(
                        status: .natural,
                        feedbackZh: feedbackZh,
                        issueZh: nil,
                        suggestedReplyKo: nil,
                        suggestedReplyZh: nil
                    )
                )
                continue
            }

            if item.status == "needs_improvement" {
                guard !issueZh.isEmpty, !suggestedKo.isEmpty, !suggestedZh.isEmpty else {
                    return ReplyCheckValidationResult(results: nil, reason: .needsSuggestionMissing)
                }

                guard containsHangul(suggestedKo) else {
                    return ReplyCheckValidationResult(results: nil, reason: .suggestionMissingHangul)
                }

                results.append(
                    ValidatedReplyCheckItem(
                        status: .needsImprovement,
                        feedbackZh: feedbackZh,
                        issueZh: issueZh,
                        suggestedReplyKo: suggestedKo,
                        suggestedReplyZh: suggestedZh
                    )
                )
                continue
            }

            return ReplyCheckValidationResult(results: nil, reason: .needsSuggestionMissing)
        }

        return ReplyCheckValidationResult(results: results, reason: nil)
    }

    private func containsHangul(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if (0x1100...0x11FF).contains(scalar.value) ||
                (0x3130...0x318F).contains(scalar.value) ||
                (0xAC00...0xD7AF).contains(scalar.value) {
                return true
            }
        }
        return false
    }

    private func fallbackResults(for myBubbles: [ChatBubble]) -> [ReplyCheckResult] {
        myBubbles.map { bubble in
            ReplyCheckResult(
                bubbleID: bubble.id,
                originalReply: bubble.text,
                status: .natural,
                feedbackZh: "这句可以先保留。系统暂时无法稳定完成细致检查；如果你想确认是否更自然，可以继续追问让我单独解释。",
                issueZh: nil,
                suggestedReplyKo: nil,
                suggestedReplyZh: nil
            )
        }
    }

    #if DEBUG
    private func trackValidationFailure(_ reason: ReplyCheckValidationFailureReason) {
        switch reason {
        case .itemCountMismatch:
            DebugTelemetry.increment(.replyCheckItemCountMismatch)
        case .emptyFeedback:
            DebugTelemetry.increment(.replyCheckEmptyFeedback)
        case .naturalHasSuggestion:
            DebugTelemetry.increment(.replyCheckNaturalHasSuggestion)
        case .needsSuggestionMissing:
            DebugTelemetry.increment(.replyCheckNeedsSuggestionMissing)
        case .suggestionMissingHangul:
            DebugTelemetry.increment(.replyCheckSuggestionMissingHangul)
        case .suggestionTooLong:
            DebugTelemetry.increment(.replyCheckSuggestionTooLong)
        }
    }
    #endif
}

struct ReplyCheckServiceFactory {
    static func makeDefaultService() -> ReplyCheckServicing {
        let config = OpenAIConfig.load()

        if config.useRealService {
            if let service = try? OpenAIReplyCheckService(config: config) {
                return service
            }
        }

        return MockReplyCheckService()
    }
}

private struct OpenAIReplyCheckChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAIReplyCheckErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String
    }
    let error: OpenAIError
}

private struct OpenAIReplyCheckEnvelope: Decodable {
    let items: [OpenAIReplyCheckItem]
}

private struct OpenAIReplyCheckItem: Decodable {
    let status: String
    let feedbackZh: String
    let issueZh: String
    let suggestedReplyKo: String
    let suggestedReplyZh: String

    enum CodingKeys: String, CodingKey {
        case status
        case feedbackZh = "feedback_zh"
        case issueZh = "issue_zh"
        case suggestedReplyKo = "suggested_reply_ko"
        case suggestedReplyZh = "suggested_reply_zh"
    }
}

private struct ValidatedReplyCheckItem {
    let status: ReplyCheckStatus
    let feedbackZh: String
    let issueZh: String?
    let suggestedReplyKo: String?
    let suggestedReplyZh: String?
}

private struct ReplyCheckValidationResult {
    let results: [ValidatedReplyCheckItem]?
    let reason: ReplyCheckValidationFailureReason?
}

private enum ReplyCheckValidationFailureReason: String {
    case itemCountMismatch = "item_count_mismatch"
    case emptyFeedback = "empty_feedback"
    case naturalHasSuggestion = "natural_has_suggestion"
    case needsSuggestionMissing = "needs_suggestion_missing"
    case suggestionMissingHangul = "suggestion_missing_hangul"
    case suggestionTooLong = "suggestion_too_long"
}
