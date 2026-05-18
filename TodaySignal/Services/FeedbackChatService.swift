import Foundation
import os

enum FeedbackChatError: LocalizedError {
    case emptyQuestion
    case timeout
    case missingAPIKey
    case unauthorized(message: String?)
    case rateLimited(message: String?)
    case serverError(message: String?)
    case serviceUnavailable(message: String?)
    case invalidResponse(message: String?)

    var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            return "请输入你的追问内容。"
        case .timeout:
            return "回答超时，请稍后重试。"
        case .missingAPIKey:
            return "未配置 OpenAI API Key。"
        case .unauthorized:
            return "API Key 无效或权限不足（401）。"
        case .rateLimited:
            return "请求过于频繁或额度不足（429），请稍后再试。"
        case .serverError:
            return "OpenAI 服务暂时不可用（5xx），请稍后重试。"
        case .serviceUnavailable:
            return "追问服务暂时不可用，请稍后重试。"
        case .invalidResponse:
            return "回答格式异常，请重试。"
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

struct FeedbackChatContext {
    let focusedText: String
    let focusedTranslationZH: String
    let focusedToneLabels: [ToneLabel]
    let focusedVocabulary: [KnowledgePoint]
    let focusedGrammarPoints: [KnowledgePoint]
    let nearbyBubbleTexts: [String]
    let myReplyCheck: ReplyCheckResult?
}

protocol FeedbackChatServicing {
    func ask(question: String, context: FeedbackChatContext) async throws -> FeedbackMessage
}

struct MockFeedbackChatService: FeedbackChatServicing {
    func ask(question: String, context: FeedbackChatContext) async throws -> FeedbackMessage {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FeedbackChatError.emptyQuestion }

        #if DEBUG
        DebugTelemetry.increment(.feedbackRequestTotal)
        #endif

        try await Task.sleep(for: .milliseconds(450))
        return FeedbackMessage(
            isUser: false,
            text: "这是 V1 mock 回复：针对「\(context.focusedText)」的「\(trimmed)」 — 真接入 AI 后会基于这条原句的解析做针对性解释。"
        )
    }
}

struct OpenAIFeedbackChatService: FeedbackChatServicing {
    private let apiKey: String
    private let model: String
    private let showDebugErrorDetails: Bool
    private let logger = Logger(subsystem: "TodaySignal", category: "FeedbackChat")

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw FeedbackChatError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func ask(question: String, context: FeedbackChatContext) async throws -> FeedbackMessage {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FeedbackChatError.emptyQuestion }

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": buildUserContent(question: trimmed, context: context)]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "feedback_chat_output",
                    "strict": true,
                    "schema": responseSchema
                ]
            ],
            "temperature": 0.3
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
                throw FeedbackChatError.serviceUnavailable(message: "Invalid HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let serverMessage = extractOpenAIErrorMessage(from: data)
                logger.error("Feedback chat failed. status=\(http.statusCode)")
                throw mapStatusCodeToError(http.statusCode, serverMessage: serverMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAIFeedbackChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw FeedbackChatError.invalidResponse(message: "Missing choices[0].message.content")
            }

            let parsed = try JSONDecoder().decode(OpenAIFeedbackChatEnvelope.self, from: Data(content.utf8))
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.info("Feedback chat succeeded. elapsed=\(elapsed, format: .fixed(precision: 3))s")

            let (validatedAnswer, validationStatus) = sanitizeAnswer(parsed.answerZh)
            switch validationStatus {
            case .ok:
                break
            case .emptyFallback:
                logger.error("Feedback chat fallback applied. reason=empty_answer")
                #if DEBUG
                DebugTelemetry.increment(.feedbackFallbackTotal)
                DebugTelemetry.increment(.feedbackEmptyAnswer)
                #endif
            case .truncated:
                logger.error("Feedback chat fallback applied. reason=answer_too_long")
                #if DEBUG
                DebugTelemetry.increment(.feedbackFallbackTotal)
                DebugTelemetry.increment(.feedbackAnswerTooLong)
                #endif
            case .tooGeneric:
                logger.error("Feedback chat fallback applied. reason=too_generic")
                #if DEBUG
                DebugTelemetry.increment(.feedbackFallbackTotal)
                DebugTelemetry.increment(.feedbackTooGeneric)
                #endif
            }
            return FeedbackMessage(isUser: false, text: validatedAnswer)
        } catch let error as FeedbackChatError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw FeedbackChatError.timeout
        } catch let error as URLError {
            throw FeedbackChatError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            throw FeedbackChatError.invalidResponse(message: error.localizedDescription)
        }
    }

    private var systemPrompt: String {
        """
        你是面向中文母语者的韩语聊天语法学习助手。
        用户正在查看某一条韩语聊天解析卡片，并针对 focused_text、其中的词尾、语法、生词、语气进行追问。

        回答原则：
        1) 必须优先围绕 focused_text 回答。nearby_context 只能用于理解上下文，不要重新分析整段聊天。
        2) 默认进入“语法学习模式”：优先解释词尾、助词、连接语法、口语缩写、语气差异，而不是泛泛聊天或泛泛翻译。
        3) 如果用户问题不够明确，优先解释 focused_grammar_points 中最相关的语法点；若没有明显语法点，再解释 focused_vocabulary 或整体语气。
        4) 如果用户问某个词、词尾、语法点，请按顺序简短解释：
           - 基础形式或语法形式
           - 原句中的实际片段
           - 在 focused_text 里的作用
           - 中文母语者容易误解的地方
        5) 如果用户问“这句话自然吗 / 语气怎么样”，请说明亲密度、随意程度、是否像真实韩语聊天；不要过度暧昧化。
        6) 如果用户明确问“怎么回复”，只给 1-2 个简短自然韩语回复，并附中文意思；不要生成完整回复列表。
        7) 如果 context 没有足够信息，明确说“不确定”，并基于 focused_text 给出谨慎解释，不要编造截图中没有的内容。
        8) 回答要短、具体、口语化，适合初学者。默认 3-6 句话；只有用户要求详细解释时才展开。
        9) 不要输出 Markdown 表格，不要长篇展开。
        10) 只输出 JSON，不要输出额外文本。
        """
    }

    private func buildUserContent(question: String, context: FeedbackChatContext) -> String {
        var lines: [String] = []
        lines.append("focused_text:")
        lines.append(context.focusedText)

        if !context.focusedTranslationZH.isEmpty {
            lines.append("")
            lines.append("focused_translation:")
            lines.append(context.focusedTranslationZH)
        }

        if !context.focusedToneLabels.isEmpty {
            lines.append("")
            lines.append("focused_tone: \(context.focusedToneLabels.map(\.rawValue).joined(separator: ", "))")
        }

        if !context.focusedVocabulary.isEmpty {
            lines.append("")
            lines.append("focused_vocabulary:")
            for point in context.focusedVocabulary {
                lines.append("- \(point.term)(\(point.meaningZH)) | \(point.usageNote)")
            }
        }

        if !context.focusedGrammarPoints.isEmpty {
            lines.append("")
            lines.append("focused_grammar_points:")
            for point in context.focusedGrammarPoints {
                let tone = point.toneNote.map { "; 语气: \($0)" } ?? ""
                lines.append("- \(point.term)(\(point.meaningZH))\(tone) | \(point.usageNote)")
            }
        }

        if !context.nearbyBubbleTexts.isEmpty {
            lines.append("")
            lines.append("nearby_context:")
            for text in context.nearbyBubbleTexts {
                lines.append("- \(text)")
            }
        }

        if let check = context.myReplyCheck {
            lines.append("")
            lines.append("my_reply_check:")
            lines.append("- 原句: \(check.originalReply)")
            lines.append("- 状态: \(check.status == .natural ? "表达自然" : "可以更自然")")
            lines.append("- 反馈: \(check.feedbackZh)")
            if let alt = check.suggestedReplyKo {
                lines.append("- 替代表达: \(alt)")
            }
        }

        lines.append("")
        lines.append("user_question:")
        lines.append(question)
        return lines.joined(separator: "\n")
    }

    private var responseSchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "answer_zh": ["type": "string"]
            ],
            "required": ["answer_zh"]
        ]
    }

    private func mapStatusCodeToError(_ statusCode: Int, serverMessage: String?) -> FeedbackChatError {
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
        guard let payload = try? JSONDecoder().decode(OpenAIFeedbackErrorEnvelope.self, from: data) else {
            return nil
        }
        return payload.error.message
    }

    private func sanitizeAnswer(_ raw: String) -> (text: String, status: AnswerValidationStatus) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return (
                "我暂时没法稳定解析这次问题。你可以换个更具体的问法，比如直接问某个词尾、语法点或这句怎么自然回复。",
                .emptyFallback
            )
        }

        if isTooGenericAnswer(trimmed) {
            return (
                "这次回答有点笼统。你可以继续追问更具体一点：例如“这是敬语还是平语？”“这个句尾和 -네요 有什么区别？”",
                .tooGeneric
            )
        }

        let maxLength = 500
        if trimmed.count <= maxLength {
            return (trimmed, .ok)
        }

        let truncated = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        return (truncated + "…", .truncated)
    }

    private func isTooGenericAnswer(_ answer: String) -> Bool {
        let normalized = answer.replacingOccurrences(of: " ", with: "")
        let genericPhrases = [
            "就是这个意思",
            "大概是这个意思",
            "差不多是这个意思",
            "就是这样",
            "大概这样"
        ]

        if normalized.count <= 18 {
            return true
        }

        return genericPhrases.contains { normalized.contains($0) }
    }
}

private enum AnswerValidationStatus {
    case ok
    case emptyFallback
    case truncated
    case tooGeneric
}

struct FeedbackChatServiceFactory {
    static func makeDefaultService() -> FeedbackChatServicing {
        let config = OpenAIConfig.load()

        if config.useRealService {
            if let service = try? OpenAIFeedbackChatService(config: config) {
                return service
            }
        }

        return MockFeedbackChatService()
    }
}

private struct OpenAIFeedbackChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAIFeedbackErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String
    }
    let error: OpenAIError
}

private struct OpenAIFeedbackChatEnvelope: Decodable {
    let answerZh: String

    enum CodingKeys: String, CodingKey {
        case answerZh = "answer_zh"
    }
}
