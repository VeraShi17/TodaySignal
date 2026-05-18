import Foundation
import os

enum ReplySuggestionError: LocalizedError {
    case emptyContext
    case timeout
    case missingAPIKey
    case unauthorized(message: String?)
    case rateLimited(message: String?)
    case serverError(message: String?)
    case serviceUnavailable(message: String?)
    case invalidResponse(message: String?)

    var errorDescription: String? {
        switch self {
        case .emptyContext:
            return "先选择一条想回复的消息，或输入你想说的话。"
        case .timeout:
            return "回复生成超时，请稍后重试。"
        case .missingAPIKey:
            return "未配置 OpenAI API Key。"
        case .unauthorized:
            return "API Key 无效或权限不足（401）。"
        case .rateLimited:
            return "请求过于频繁或额度不足（429），请稍后再试。"
        case .serverError:
            return "OpenAI 服务暂时不可用（5xx），请稍后重试。"
        case .serviceUnavailable:
            return "回复服务暂时不可用，请稍后重试。"
        case .invalidResponse:
            return "回复结果格式异常，请重试。"
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

protocol ReplySuggestionServicing {
    func generateReplies(contextBubbles: [ChatBubble], intentZh: String?, tone: ReplyTone) async throws -> [ReplySuggestion]
}

struct MockReplySuggestionService: ReplySuggestionServicing {
    func generateReplies(contextBubbles: [ChatBubble], intentZh: String?, tone: ReplyTone) async throws -> [ReplySuggestion] {
        let hasContext = !contextBubbles.isEmpty || !(intentZh?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        guard hasContext else { throw ReplySuggestionError.emptyContext }

        #if DEBUG
        DebugTelemetry.increment(.replySuggestionRequestTotal)
        #endif

        try await Task.sleep(for: .milliseconds(450))

        return MockData.v1ReplySuggestions.map {
            ReplySuggestion(replyKo: $0.replyKo, replyZh: $0.replyZh, tone: tone, noteZh: toneNote(for: tone))
        }
    }

    private func toneNote(for tone: ReplyTone) -> String {
        switch tone {
        case .natural: return "自然、舒服的日常聊天感。"
        case .cute: return "更可爱，带一点撒娇感。"
        case .polite: return "更礼貌、稳妥。"
        case .friendly: return "像朋友一样轻松亲近。"
        case .subtleFlirty: return "轻微暧昧感，保持边界。"
        }
    }
}

struct OpenAIReplySuggestionService: ReplySuggestionServicing {
    private let apiKey: String
    private let model: String
    private let showDebugErrorDetails: Bool
    private let logger = Logger(subsystem: "TodaySignal", category: "ReplySuggestion")

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw ReplySuggestionError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func generateReplies(contextBubbles: [ChatBubble], intentZh: String?, tone: ReplyTone) async throws -> [ReplySuggestion] {
        let hasContext = !contextBubbles.isEmpty || !(intentZh?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        guard hasContext else { throw ReplySuggestionError.emptyContext }

        let contextText = contextBubbles.map { "- \($0.text)" }.joined(separator: "\n")
        let intentText = intentZh?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "用户选择要回复的对方消息 selected_messages:\n\(contextText.isEmpty ? "(无)" : contextText)\n\n用户想表达 intent_zh(可选):\n\(intentText.isEmpty ? "(无)" : intentText)\n\n目标语气 reply_tone:\n\(tone.rawValue)"
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "reply_suggestion_output",
                    "strict": true,
                    "schema": responseSchema
                ]
            ],
            "temperature": 0.4
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
                throw ReplySuggestionError.serviceUnavailable(message: "Invalid HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let serverMessage = extractOpenAIErrorMessage(from: data)
                logger.error("Reply suggestion failed. status=\(http.statusCode)")
                throw mapStatusCodeToError(http.statusCode, serverMessage: serverMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAIReplyChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw ReplySuggestionError.invalidResponse(message: "Missing choices[0].message.content")
            }

            let parsed = try JSONDecoder().decode(OpenAIReplySuggestionEnvelope.self, from: Data(content.utf8))
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.info("Reply suggestion succeeded. count=\(parsed.items.count), elapsed=\(elapsed, format: .fixed(precision: 3))s")

            let validationResult = validateSuggestions(parsed.items, tone: tone)
            if let validated = validationResult.suggestions {
                return validated
            }

            logger.error("Reply suggestion fallback applied. reason=\(validationResult.reason?.rawValue ?? "unknown")")
            #if DEBUG
            DebugTelemetry.increment(.replySuggestionFallbackTotal)
            if let reason = validationResult.reason {
                trackValidationFailure(reason)
            }
            #endif
            return fallbackSuggestions(tone: tone, intentText: intentText)
        } catch let error as ReplySuggestionError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw ReplySuggestionError.timeout
        } catch let error as URLError {
            throw ReplySuggestionError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            throw ReplySuggestionError.invalidResponse(message: error.localizedDescription)
        }
    }

    private var systemPrompt: String {
        """
        你是韩语聊天回复助手，帮助中文母语者给韩语聊天中的对方消息生成自然回复。

        场景：
        - 对方可能是 idol / 博主 / 朋友式聊天对象。
        - 用户选择的 selected_messages 是“想回复的目标消息”。
        - 如果用户提供了 intent_zh，必须优先表达用户意图。
        - 如果用户没有提供意图，请根据对方消息生成自然、轻松、不会尴尬的回应。

        生成要求：
        1) 生成 3 条韩语回复建议，每条都必须可以直接复制发送。
        2) 每条回复尽量简短，通常 1 句即可；最多 2 句。
        3) 语气必须贴合目标语气：自然 / 可爱 / 礼貌 / 朋友感 / 暧昧感。
        4) 保持粉丝与 idol 场景边界：不要露骨、不要冒犯、不要过度亲密、不要像现实情侣一样要求对方。
        5) 可以使用自然聊天元素，如 ㅋㅋ、ㅎㅎ、ㅠㅠ、~，但不要堆砌。
        6) 不要编造上下文没有的信息，不要提到截图外的事实。
        7) 如果对方消息是问句，回复要直接回应问题。
        8) 如果对方消息是情绪表达，回复要先接住情绪，再自然回应。
        9) 输出中文释义 reply_zh，说明这句韩语的大意。
        10) note_zh 简要说明语气特点和适合发送的场景。
        11) 只输出 JSON，不要输出额外文本。
        """
    }

    private var responseSchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "items": [
                    "type": "array",
                    "minItems": 3,
                    "maxItems": 3,
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "reply_ko": ["type": "string"],
                            "reply_zh": ["type": "string"],
                            "note_zh": ["type": "string"]
                        ],
                        "required": ["reply_ko", "reply_zh", "note_zh"]
                    ]
                ]
            ],
            "required": ["items"]
        ]
    }

    private func mapStatusCodeToError(_ statusCode: Int, serverMessage: String?) -> ReplySuggestionError {
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
        guard let payload = try? JSONDecoder().decode(OpenAIReplyErrorEnvelope.self, from: data) else {
            return nil
        }
        return payload.error.message
    }

    private func validateSuggestions(_ items: [OpenAIReplySuggestionItem], tone: ReplyTone) -> SuggestionValidationResult {
        guard items.count == 3 else {
            return SuggestionValidationResult(suggestions: nil, reason: .itemCountMismatch)
        }

        var usedNormalizedKo = Set<String>()
        var results: [ReplySuggestion] = []

        for item in items {
            let replyKo = item.replyKo.trimmingCharacters(in: .whitespacesAndNewlines)
            let replyZh = item.replyZh.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteZh = item.noteZh.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !replyKo.isEmpty, !replyZh.isEmpty, !noteZh.isEmpty else {
                return SuggestionValidationResult(suggestions: nil, reason: .emptyField)
            }

            guard replyKo.count <= 120, replyZh.count <= 120, noteZh.count <= 100 else {
                return SuggestionValidationResult(suggestions: nil, reason: .tooLong)
            }

            guard containsHangul(replyKo) else {
                return SuggestionValidationResult(suggestions: nil, reason: .missingHangul)
            }

            let normalizedKo = replyKo.replacingOccurrences(of: " ", with: "").lowercased()
            guard usedNormalizedKo.insert(normalizedKo).inserted else {
                return SuggestionValidationResult(suggestions: nil, reason: .duplicateReply)
            }

            results.append(ReplySuggestion(replyKo: replyKo, replyZh: replyZh, tone: tone, noteZh: noteZh))
        }

        return SuggestionValidationResult(suggestions: results, reason: nil)
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

    private func fallbackSuggestions(tone: ReplyTone, intentText: String) -> [ReplySuggestion] {
        let intentNote = intentText.isEmpty ? "根据对方消息给出的稳妥回复。" : "优先贴合你输入的意图，做了稳妥表达。"
        return [
            ReplySuggestion(replyKo: "좋은 이야기 고마워요 ㅎㅎ", replyZh: "谢谢你分享这个呀，嘿嘿。", tone: tone, noteZh: "礼貌自然，适合大多数场景。\(intentNote)"),
            ReplySuggestion(replyKo: "나도 그렇게 생각했어 ㅋㅋ", replyZh: "我也是这么想的，哈哈。", tone: tone, noteZh: "朋友感更强，轻松不生硬。\(intentNote)"),
            ReplySuggestion(replyKo: "맞아, 진짜 공감돼요!", replyZh: "对，真的很有同感！", tone: tone, noteZh: "先接住情绪，再表达认同。\(intentNote)")
        ]
    }

    #if DEBUG
    private func trackValidationFailure(_ reason: SuggestionValidationFailureReason) {
        switch reason {
        case .itemCountMismatch:
            DebugTelemetry.increment(.replyItemCountMismatch)
        case .emptyField:
            DebugTelemetry.increment(.replyEmptyField)
        case .tooLong:
            DebugTelemetry.increment(.replyTooLong)
        case .missingHangul:
            DebugTelemetry.increment(.replyMissingHangul)
        case .duplicateReply:
            DebugTelemetry.increment(.replyDuplicateReply)
        }
    }
    #endif
}

struct ReplySuggestionServiceFactory {
    static func makeDefaultService() -> ReplySuggestionServicing {
        let config = OpenAIConfig.load()

        if config.useRealService {
            if let service = try? OpenAIReplySuggestionService(config: config) {
                return service
            }
        }

        return MockReplySuggestionService()
    }
}

private struct OpenAIReplyChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIReplyErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String
    }

    let error: OpenAIError
}

private struct OpenAIReplySuggestionEnvelope: Decodable {
    let items: [OpenAIReplySuggestionItem]
}

private struct OpenAIReplySuggestionItem: Decodable {
    let replyKo: String
    let replyZh: String
    let noteZh: String

    enum CodingKeys: String, CodingKey {
        case replyKo = "reply_ko"
        case replyZh = "reply_zh"
        case noteZh = "note_zh"
    }
}

private struct SuggestionValidationResult {
    let suggestions: [ReplySuggestion]?
    let reason: SuggestionValidationFailureReason?
}

private enum SuggestionValidationFailureReason: String {
    case itemCountMismatch = "item_count_mismatch"
    case emptyField = "empty_field"
    case tooLong = "too_long"
    case missingHangul = "missing_hangul"
    case duplicateReply = "duplicate_reply"
}
