import Foundation
import os

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
    private let logger = Logger(subsystem: "TodaySignal", category: "AIAnalysis")

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw AIAnalysisError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func analyze(request: AnalysisRequest) async throws -> [AnalysisResult] {
        let startedAt = Date()
        logger.info("AI analysis started. model=\(self.model, privacy: .public), bubbles=\(request.bubbles.count)")

        let idolBubbles = request.bubbles.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.side == request.idolSide &&
            $0.type == .text
        }

        guard !idolBubbles.isEmpty else {
            throw AIAnalysisError.emptyInput
        }

        let userLines = idolBubbles.enumerated()
            .map { "[\($0.offset)] \($0.element.text)" }
            .joined(separator: "\n")

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "请分析以下韩语聊天句子（均来自对方气泡）。每条句子前的 [N] 是该句的 bubble_index，请在对应 item 的 bubble_index 字段里原样回填：\n\n\(userLines)"
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
                let elapsed = Date().timeIntervalSince(startedAt)
                logger.error("AI analysis failed. status=\(http.statusCode), elapsed=\(elapsed, format: .fixed(precision: 3))s")
                throw mapStatusCodeToError(http.statusCode, serverMessage: apiErrorMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw AIAnalysisError.invalidResponse(message: "Missing choices[0].message.content")
            }

            let outputData = Data(content.utf8)
            let parsed = try JSONDecoder().decode(OpenAIAnalysisEnvelope.self, from: outputData)

            let elapsed = Date().timeIntervalSince(startedAt)
            let returnedIndexes = parsed.items.map { $0.bubbleIndex }
            logger.info("AI analysis succeeded. items=\(parsed.items.count), elapsed=\(elapsed, format: .fixed(precision: 3))s")
            print("[AIAnalysis] model=\(model) idol=\(idolBubbles.count) items=\(parsed.items.count) returnedIndexes=\(returnedIndexes) elapsed=\(String(format: "%.3f", elapsed))s")

            return parsed.items
                .filter { $0.bubbleIndex >= 0 && $0.bubbleIndex < idolBubbles.count }
                .map { item in
                    let sourceBubble = idolBubbles[item.bubbleIndex]

                    let vocabPoints = item.vocabulary
                        .filter { !shouldDropVocabularyAsGrammarLike($0.word) }
                        .map { vocab in
                            KnowledgePoint(
                                type: .vocabulary,
                                term: vocab.word,
                                meaningZH: vocab.meaningZH,
                                pronunciation: vocab.pronunciation,
                                partOfSpeech: vocab.partOfSpeech,
                                usageNote: buildVocabularyUsageNote(surfaceForm: vocab.surfaceForm, usageNote: vocab.usageNote)
                            )
                        }

                    let grammarPoints = item.grammarPoints
                        .filter { !shouldDropGrammarPoint($0) }
                        .map {
                        KnowledgePoint(
                            type: .grammar,
                            term: $0.point.trimmingCharacters(in: .whitespacesAndNewlines),
                            meaningZH: normalizeGrammarMeaning(point: $0.point, meaning: $0.meaningZH),
                            toneNote: $0.toneNote,
                            usageNote: buildGrammarUsageContext(surfaceForm: $0.surfaceForm, usageContext: $0.usageContext, category: $0.category)
                        )
                    }

                    return AnalysisResult(
                        bubbleID: sourceBubble.id,
                        originalText: item.originalText,
                        translationZH: item.translationZH,
                        toneLabels: mapToneLabels(item.toneLabels),
                        vocabulary: deduplicatedKnowledgePoints(vocabPoints),
                        grammarPoints: deduplicatedKnowledgePoints(grammarPoints)
                    )
                }
        } catch let error as AIAnalysisError {
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.error("AI analysis failed with AIAnalysisError. elapsed=\(elapsed, format: .fixed(precision: 3))s")
            throw error
        } catch let error as URLError where error.code == .timedOut {
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.error("AI analysis timeout. elapsed=\(elapsed, format: .fixed(precision: 3))s")
            throw AIAnalysisError.timeout
        } catch let error as URLError {
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.error("AI analysis network failure. elapsed=\(elapsed, format: .fixed(precision: 3))s")
            throw AIAnalysisError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            let elapsed = Date().timeIntervalSince(startedAt)
            logger.error("AI analysis invalid response. elapsed=\(elapsed, format: .fixed(precision: 3))s")
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

    private func buildGrammarUsageContext(surfaceForm: String?, usageContext: String, category: String?) -> String {
        let categoryPrefix: String = {
            guard let category, !category.isEmpty else { return "" }
            return "类别：\(category)\n"
        }()

        guard let surfaceForm, !surfaceForm.isEmpty else {
            return "\(categoryPrefix)\(usageContext)"
        }
        return "\(categoryPrefix)原句片段：\(surfaceForm)\n\(usageContext)"
    }

    private func normalizeGrammarMeaning(point: String, meaning: String) -> String {
        let key = point.replacingOccurrences(of: " ", with: "")
        let overrides: [String: String] = [
            "-에": "在/到（地点、时间、方向等）",
            "에": "在/到（地点、时间、方向等）",
            "-에서": "在……（动作发生地点）/从……",
            "에서": "在……（动作发生地点）/从……",
            "-은/는": "主题/对比标记",
            "은/는": "主题/对比标记",
            "-이/가": "主语标记",
            "이/가": "主语标记",
            "-을/를": "宾语标记",
            "을/를": "宾语标记",
            "-도": "也",
            "도": "也",
            "-(으)면": "如果……的话",
            "(으)면": "如果……的话",
            "-아/어": "非敬语平语句尾",
            "-아/어?": "非敬语平语疑问句尾",
            "-ㄹ게": "我会……/我来……"
        ]

        return overrides[key] ?? meaning
    }

    private func shouldDropVocabularyAsGrammarLike(_ word: String) -> Bool {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let grammarLikeVocabulary: Set<String> = [
            "에", "은", "는", "이", "가", "을", "를", "도", "만", "에서", "으로", "하고"
        ]
        return grammarLikeVocabulary.contains(normalized)
    }

    private func shouldDropGrammarPoint(_ item: OpenAIGrammarItem) -> Bool {
        let point = item.point.trimmingCharacters(in: .whitespacesAndNewlines)
        let surface = item.surfaceForm?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if point.isEmpty { return true }

        let bannedCategoryNames: Set<String> = [
            "语气助词", "疑问词", "动词", "形容词", "名词", "副词",
            "助词", "词尾", "语法", "口语表达", "语气表达"
        ]
        if bannedCategoryNames.contains(point) { return true }

        let lowValuePatterns = [
            #"^~+$"#,
            #"^\.+$"#,
            #"^!+$"#,
            #"^\?+$"#,
            #"^[ㅋㅎㅠㅜ]+$"#,
            #"^[~.!?ㅋㅎㅠㅜ]+$"#
        ]

        for pattern in lowValuePatterns {
            if point.range(of: pattern, options: .regularExpression) != nil { return true }
            if surface.range(of: pattern, options: .regularExpression) != nil { return true }
        }

        let hasHangul = point.range(of: #"[가-힣ㄱ-ㅎㅏ-ㅣ]"#, options: .regularExpression) != nil
        let looksLikeGrammarNotation = point.contains("-") || point.contains("(") || point.contains("/")
        if !hasHangul && !looksLikeGrammarNotation { return true }

        return false
    }

    private func deduplicatedKnowledgePoints(_ points: [KnowledgePoint]) -> [KnowledgePoint] {
        var seen = Set<String>()
        var unique: [KnowledgePoint] = []

        for point in points {
            let normalizedTerm = point.term
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let normalizedMeaning = point.meaningZH
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let key = "\(point.type.rawValue)|\(normalizedTerm)|\(normalizedMeaning)"

            if seen.insert(key).inserted {
                unique.append(point)
            }
        }

        return unique
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

        输入与输出对应规则（极重要，违反会导致整次解析作废）：
        - user message 中每条句子前都带形如 [N] 的索引（N 从 0 开始连续递增）。
        - 你必须在 items[*].bubble_index 中严格回填该句子前的 N。不要自创、不要偏移、不要重新编号、不要使用 1-based。
        - items 数量必须等于 user message 中实际给出的句子数；不要漏掉任何一条。
        - 同一条句子只能产生 1 个 item，不要拆分或合并句子。

        核心目标：
        1. vocabulary.word 必须优先输出词典形/原型，不要输出表面活用形。
        2. 韩语是黏着语，必须拆分词干、助词、词尾、连接语法。
        3. 表面形放到 surface_form；不要把助词/词尾放入 vocabulary。

        生词规则：
        - 动词/形容词还原：먹으면 -> 먹다，맛있어 -> 맛있다。
        - 名词可保留原形：샌드위치、한번。
        - 活用形、缩写、可爱化写法要在 usage_note 中说明对应标准形。
        - 每条最多 3 个高价值生词。

        字段职责：
        - vocabulary.word：必须是具体词条，优先词典形。例如 언제、가다、맛있다。不能写“疑问词”“动词”“助词”这类类别名。
        - vocabulary.meaning_zh：写词条核心含义，例如 언제=什么时候，가다=去/回。
        - vocabulary.part_of_speech：写词性，例如 疑问副词、动词、形容词、名词。

        - grammar_points.point：必须是具体语法形式，例如 -에、-도、-아/어?、(으)면。
        - grammar_points.category：必须从以下集合中选择：助词、词尾、连接语法、句型。
        - grammar_points.meaning_zh：只能写抽象语法义，不能写上下文翻译。
        - grammar_points.surface_form：写原句实际片段。
        - grammar_points.usage_context：解释该语法在原句中的作用，可以写具体翻译。

        语法规则：
        - 不要把动词活用形误放进 grammar_points，例如 가(来自 가다) 应优先作为 vocabulary。
        - grammar_points 只提取有明确学习价值的具体语法形式，不要为了凑数量提取低价值项。
        - 不要单独提取以下内容作为 grammar_points：
          1) 单独标点或语气符号：~~、~、..、!!、??
          2) 单独笑声/语气字符：ㅋㅋ、ㅎㅎ、ㅠㅠ、ㅜㅜ
          3) 中文类别名：语气助词、疑问词、动词、助词、词尾
          4) 只有语气效果但没有具体韩语语法形式的项目
        - 上述内容可放在 tone_labels 或 usage_context 说明，但不要生成 grammar point 卡片。
        - 若一句话里没有值得学习的具体语法点，grammar_points 可以为空数组。
        - “句尾”只指有实际语法功能的词尾，例如 -자、-겠-, -아/어도 되다、-(으)면、-ㄹ게、-는데。
        - 每条最多 3 个语法点。

        词类归属规则：
        - 언제、뭐、왜、어디、누구、어떻게 这类疑问词/疑问副词，应放入 vocabulary。
        - vocabulary.word 必须写具体词条，不能写“疑问词”等类别名。
        - grammar_points.point 不能写中文类别名，例如“疑问词”“语气助词”“词尾”。

        错误示例：
        - point: "-에", meaning_zh: "到家"（错误：把上下文翻译放进 meaning_zh）
        - vocabulary.word: "疑问词"（错误：word 应该是 언제）
        - point: "-가", meaning_zh: "去"（错误：这里应优先是 vocabulary: 가다）

        正确示例：
        - vocabulary.word: "언제", meaning_zh: "什么时候", part_of_speech: "疑问副词"
        - vocabulary.word: "가다", surface_form: "가", meaning_zh: "去；回", part_of_speech: "动词"
        - grammar.point: "-에", surface_form: "집에", meaning_zh: "在/到（地点、时间、方向等）"
        - grammar.point: "-아/어?", surface_form: "가??", meaning_zh: "非敬语平语疑问句尾"

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
                                        "category": [
                                            "type": "string",
                                            "enum": ["助词", "词尾", "连接语法", "句型"]
                                        ],
                                        "surface_form": ["type": ["string", "null"]],
                                        "meaning_zh": ["type": "string"],
                                        "tone_note": ["type": ["string", "null"]],
                                        "usage_context": ["type": "string"]
                                    ],
                                    "required": ["point", "category", "surface_form", "meaning_zh", "tone_note", "usage_context"]
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
    let category: String
    let surfaceForm: String?
    let meaningZH: String
    let toneNote: String?
    let usageContext: String

    enum CodingKeys: String, CodingKey {
        case point
        case category
        case surfaceForm = "surface_form"
        case meaningZH = "meaning_zh"
        case toneNote = "tone_note"
        case usageContext = "usage_context"
    }
}
