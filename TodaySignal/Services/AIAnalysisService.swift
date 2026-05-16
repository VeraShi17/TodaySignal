import Foundation

struct AnalysisRequest {
    let bubbles: [ChatBubble]
    let idolSide: BubbleSide
}

enum AIAnalysisError: LocalizedError {
    case emptyInput
    case timeout
    case missingAPIKey
    case unauthorized(message: String?)
    case rateLimited(message: String?)
    case serverError(message: String?)
    case serviceUnavailable(message: String?)
    case invalidResponse(message: String?)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "没有可解析的聊天文本，请先确认并保留至少一条消息。"
        case .timeout:
            return "解析超时，请稍后重试。"
        case .missingAPIKey:
            return "未配置 OpenAI API Key。"
        case .unauthorized:
            return "API Key 无效或权限不足（401）。"
        case .rateLimited:
            return "请求过于频繁或额度不足（429），请稍后再试。"
        case .serverError:
            return "OpenAI 服务暂时不可用（5xx），请稍后重试。"
        case .serviceUnavailable:
            return "分析服务暂时不可用，请稍后重试。"
        case .invalidResponse:
            return "解析结果格式异常，请重试。"
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

protocol AIAnalysisServicing {
    func analyze(request: AnalysisRequest) async throws -> [AnalysisResult]
}

struct MockAIAnalysisService: AIAnalysisServicing {
    func analyze(request: AnalysisRequest) async throws -> [AnalysisResult] {
        guard request.bubbles.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw AIAnalysisError.emptyInput
        }

        try await Task.sleep(nanoseconds: 700_000_000)
        return MockData.analysisResults
    }
}

struct OpenAIAnalysisService: AIAnalysisServicing {
    private let apiKey: String
    private let model: String
    private let showDebugErrorDetails: Bool

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw AIAnalysisError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func analyze(request: AnalysisRequest) async throws -> [AnalysisResult] {
        let idolBubbles = request.bubbles.enumerated().filter {
            !$0.element.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.element.side == request.idolSide &&
            $0.element.type == .text
        }

        guard !idolBubbles.isEmpty else {
            throw AIAnalysisError.emptyInput
        }

        let userLines = idolBubbles.map { "[\($0.offset)] \($0.element.text)" }.joined(separator: "\n")

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "请分析以下韩语聊天句子（均来自对方气泡）:\n\n\(userLines)"
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "chat_analysis_output",
                    "strict": true,
                    "schema": analysisSchema
                ]
            ],
            "temperature": 0.1
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = body
        urlRequest.timeoutInterval = 60

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 65
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw AIAnalysisError.serviceUnavailable(message: "Invalid HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let apiErrorMessage = extractOpenAIErrorMessage(from: data)
                throw mapStatusCodeToError(http.statusCode, serverMessage: apiErrorMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw AIAnalysisError.invalidResponse(message: "Missing choices[0].message.content")
            }

            let outputData = Data(content.utf8)
            let parsed = try JSONDecoder().decode(OpenAIAnalysisEnvelope.self, from: outputData)

            return parsed.items.compactMap { item in
                guard item.bubbleIndex >= 0, item.bubbleIndex < request.bubbles.count else {
                    return nil
                }

                let sourceBubble = request.bubbles[item.bubbleIndex]

                return AnalysisResult(
                    bubbleID: sourceBubble.id,
                    originalText: item.originalText,
                    translationZH: item.translationZH,
                    toneLabels: mapToneLabels(item.toneLabels),
                    vocabulary: item.vocabulary.map {
                        KnowledgePoint(
                            type: .vocabulary,
                            term: $0.word,
                            meaningZH: $0.meaningZH,
                            pronunciation: $0.pronunciation,
                            partOfSpeech: $0.partOfSpeech,
                            usageNote: buildVocabularyUsageNote(surfaceForm: $0.surfaceForm, usageNote: $0.usageNote)
                        )
                    },
                    grammarPoints: item.grammarPoints.map {
                        KnowledgePoint(
                            type: .grammar,
                            term: $0.point,
                            meaningZH: $0.meaningZH,
                            toneNote: $0.toneNote,
                            usageNote: buildGrammarUsageContext(surfaceForm: $0.surfaceForm, usageContext: $0.usageContext)
                        )
                    },
                    isUserReply: false
                )
            }
        } catch let error as AIAnalysisError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw AIAnalysisError.timeout
        } catch let error as URLError {
            throw AIAnalysisError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            throw AIAnalysisError.invalidResponse(message: error.localizedDescription)
        }
    }

    private func mapToneLabels(_ labels: [String]) -> [ToneLabel] {
        let mapped = labels.compactMap { label in
            ToneLabel.allCases.first(where: { $0.rawValue == label })
        }
        return mapped.isEmpty ? [.neutral] : mapped
    }

    private func buildVocabularyUsageNote(surfaceForm: String?, usageNote: String) -> String {
        guard let surfaceForm, !surfaceForm.isEmpty else { return usageNote }
        return "原句形式：\(surfaceForm)\n\(usageNote)"
    }

    private func buildGrammarUsageContext(surfaceForm: String?, usageContext: String) -> String {
        guard let surfaceForm, !surfaceForm.isEmpty else { return usageContext }
        return "原句片段：\(surfaceForm)\n\(usageContext)"
    }

    private func mapStatusCodeToError(_ statusCode: Int, serverMessage: String?) -> AIAnalysisError {
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
        guard let payload = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) else {
            return nil
        }
        return payload.error.message
    }

    private var systemPrompt: String {
        """
        你是面向中文母语者的韩语聊天学习助手。只分析韩语原句，输出中文解释。

        核心目标：
        1. vocabulary.word 必须优先输出词典形/原型，不要输出表面活用形。
        2. 韩语是黏着语，必须拆分词干、助词、词尾、连接语法。
        3. 表面形放到 surface_form；不要把助词/词尾放入 vocabulary。

        生词规则：
        - 动词/形容词还原：먹으면 -> 먹다，맛있어 -> 맛있다。
        - 名词可保留原形：샌드위치、한번。
        - 活用形、缩写、可爱化写法要在 usage_note 中说明对应标准形。
        - 每条最多 3 个高价值生词。

        语法规则：
        - grammar_points.point 写语法形式：例如 (으)면、도、-아/어、-ㄹ게。
        - grammar_points.surface_form 写原句中对应片段。
        - usage_context 解释它在原句中的语法作用和语气。
        - 每条最多 3 个语法点。

        语气标签只能从以下集合选择：
        ["普通陈述","亲近随意","可爱 / 撒娇","吐槽 / 开玩笑","安慰 / 关心","礼貌表达","冷淡 / 简短"]。

        不要编造原文没有的内容。
        """
    }

    private var analysisSchema: [String: Any] {
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
                            "bubble_index": ["type": "integer"],
                            "original_text": ["type": "string"],
                            "translation_zh": ["type": "string"],
                            "tone_labels": [
                                "type": "array",
                                "items": [
                                    "type": "string",
                                    "enum": ["普通陈述", "亲近随意", "可爱 / 撒娇", "吐槽 / 开玩笑", "安慰 / 关心", "礼貌表达", "冷淡 / 简短"]
                                ]
                            ],
                            "vocabulary": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "additionalProperties": false,
                                    "properties": [
                                        "word": ["type": "string"],
                                        "surface_form": ["type": ["string", "null"]],
                                        "meaning_zh": ["type": "string"],
                                        "pronunciation": ["type": ["string", "null"]],
                                        "part_of_speech": ["type": ["string", "null"]],
                                        "usage_note": ["type": "string"]
                                    ],
                                    "required": ["word", "surface_form", "meaning_zh", "pronunciation", "part_of_speech", "usage_note"]
                                ]
                            ],
                            "grammar_points": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "additionalProperties": false,
                                    "properties": [
                                        "point": ["type": "string"],
                                        "surface_form": ["type": ["string", "null"]],
                                        "meaning_zh": ["type": "string"],
                                        "tone_note": ["type": ["string", "null"]],
                                        "usage_context": ["type": "string"]
                                    ],
                                    "required": ["point", "surface_form", "meaning_zh", "tone_note", "usage_context"]
                                ]
                            ]
                        ],
                        "required": ["bubble_index", "original_text", "translation_zh", "tone_labels", "vocabulary", "grammar_points"]
                    ]
                ]
            ],
            "required": ["items"]
        ]
    }
}

struct OpenAIConfig {
    let apiKey: String?
    let model: String
    let useRealService: Bool
    let showDebugErrorDetails: Bool

    static func load() -> OpenAIConfig {
        let env = ProcessInfo.processInfo.environment
        let apiKey = env["OPENAI_API_KEY"] ?? Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        let model = env["OPENAI_MODEL"] ?? "gpt-4.1-mini"

        let useRealValue = (env["USE_REAL_OPENAI"] ?? "false").lowercased()
        let useReal = ["1", "true", "yes"].contains(useRealValue)

        let debugValue = (env["OPENAI_SHOW_ERROR_DETAILS"] ?? "false").lowercased()
        let showDetails = ["1", "true", "yes"].contains(debugValue)

        return OpenAIConfig(
            apiKey: apiKey,
            model: model,
            useRealService: useReal,
            showDebugErrorDetails: showDetails
        )
    }
}

struct AIAnalysisServiceFactory {
    static func makeDefaultService() -> AIAnalysisServicing {
        let config = OpenAIConfig.load()

        if config.useRealService {
            if let service = try? OpenAIAnalysisService(config: config) {
                return service
            }
        }

        return MockAIAnalysisService()
    }
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String
        let type: String?
        let code: String?
    }

    let error: OpenAIError
}

private struct OpenAIAnalysisEnvelope: Decodable {
    let items: [OpenAIAnalysisItem]
}

private struct OpenAIAnalysisItem: Decodable {
    let bubbleIndex: Int
    let originalText: String
    let translationZH: String
    let toneLabels: [String]
    let vocabulary: [OpenAIVocabularyItem]
    let grammarPoints: [OpenAIGrammarItem]

    enum CodingKeys: String, CodingKey {
        case bubbleIndex = "bubble_index"
        case originalText = "original_text"
        case translationZH = "translation_zh"
        case toneLabels = "tone_labels"
        case vocabulary
        case grammarPoints = "grammar_points"
    }
}

private struct OpenAIVocabularyItem: Decodable {
    let word: String
    let surfaceForm: String?
    let meaningZH: String
    let pronunciation: String?
    let partOfSpeech: String?
    let usageNote: String

    enum CodingKeys: String, CodingKey {
        case word
        case surfaceForm = "surface_form"
        case meaningZH = "meaning_zh"
        case pronunciation
        case partOfSpeech = "part_of_speech"
        case usageNote = "usage_note"
    }
}

private struct OpenAIGrammarItem: Decodable {
    let point: String
    let surfaceForm: String?
    let meaningZH: String
    let toneNote: String?
    let usageContext: String

    enum CodingKeys: String, CodingKey {
        case point
        case surfaceForm = "surface_form"
        case meaningZH = "meaning_zh"
        case toneNote = "tone_note"
        case usageContext = "usage_context"
    }
}
