import Foundation
import os

enum CardExampleError: LocalizedError {
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
            return "例句生成超时，请稍后重试。"
        case .missingAPIKey:
            return "未配置 OpenAI API Key。"
        case .unauthorized:
            return "API Key 无效或权限不足（401）。"
        case .rateLimited:
            return "请求过于频繁或额度不足（429），请稍后再试。"
        case .serverError:
            return "OpenAI 服务暂时不可用（5xx），请稍后重试。"
        case .serviceUnavailable:
            return "例句服务暂时不可用，请稍后重试。"
        case .invalidResponse:
            return "例句格式异常，请重试。"
        }
    }
}

protocol CardExampleServicing {
    func vocabularyExample(term: String, originalSentence: String) async throws -> (ko: String, zh: String)
    func grammarExamples(point: String, originalSentence: String) async throws -> [(ko: String, zh: String)]
}

struct MockCardExampleService: CardExampleServicing {
    func vocabularyExample(term: String, originalSentence: String) async throws -> (ko: String, zh: String) {
        if let canned = MockData.vocabularyCards.first(where: { $0.word == term }) {
            return (canned.exampleSentence, canned.exampleTranslationZH)
        }
        return (originalSentence, "包含「\(term)」的例句。")
    }

    func grammarExamples(point: String, originalSentence: String) async throws -> [(ko: String, zh: String)] {
        if let canned = MockData.grammarCards.first(where: { $0.point == point }) {
            return canned.exampleSentences
        }
        return [(originalSentence, "包含「\(point)」的例句。")]
    }
}

struct OpenAICardExampleService: CardExampleServicing {
    private let apiKey: String
    private let model: String
    private let showDebugErrorDetails: Bool
    private let logger = Logger(subsystem: "TodaySignal", category: "CardExample")

    init(config: OpenAIConfig) throws {
        guard let key = config.apiKey, !key.isEmpty else {
            throw CardExampleError.missingAPIKey
        }
        self.apiKey = key
        self.model = config.model
        self.showDebugErrorDetails = config.showDebugErrorDetails
    }

    func vocabularyExample(term: String, originalSentence: String) async throws -> (ko: String, zh: String) {
        let prompt = """
        target_word:
        \(term)

        source_sentence:
        \(originalSentence)

        task:
        请生成新的例句，不要直接复制 source_sentence。
        """
        let payload = buildPayload(
            systemPrompt: vocabularySystemPrompt,
            userPrompt: prompt,
            schemaName: "vocab_card_example_output",
            schema: vocabularySchema,
            temperature: 0.3
        )

        let parsed = try await request(payload: payload)
        let item = try JSONDecoder().decode(OpenAIVocabExampleEnvelope.self, from: Data(parsed.utf8))
        let ko = item.exampleKo.trimmingCharacters(in: .whitespacesAndNewlines)
        let zh = item.exampleZh.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ko.isEmpty, !zh.isEmpty, containsHangul(ko), ko.count <= 120, zh.count <= 120 else {
            throw CardExampleError.invalidResponse(message: "Invalid vocabulary example payload")
        }
        return (ko, zh)
    }

    func grammarExamples(point: String, originalSentence: String) async throws -> [(ko: String, zh: String)] {
        let prompt = """
        target_grammar:
        \(point)

        source_sentence:
        \(originalSentence)

        task:
        请生成 1-2 条新的例句，每条例句都要体现 target_grammar。
        """
        let payload = buildPayload(
            systemPrompt: grammarSystemPrompt,
            userPrompt: prompt,
            schemaName: "grammar_card_examples_output",
            schema: grammarSchema,
            temperature: 0.3
        )

        let parsed = try await request(payload: payload)
        let item = try JSONDecoder().decode(OpenAIGrammarExamplesEnvelope.self, from: Data(parsed.utf8))

        let examples = item.items.map {
            ($0.exampleKo.trimmingCharacters(in: .whitespacesAndNewlines), $0.exampleZh.trimmingCharacters(in: .whitespacesAndNewlines))
        }.filter { !$0.0.isEmpty && !$0.1.isEmpty }

        guard !examples.isEmpty, examples.count <= 2 else {
            throw CardExampleError.invalidResponse(message: "Invalid grammar examples count")
        }

        for example in examples {
            guard containsHangul(example.0), example.0.count <= 120, example.1.count <= 120 else {
                throw CardExampleError.invalidResponse(message: "Invalid grammar example item")
            }
        }

        return examples
    }

    private func request(payload: [String: Any]) async throws -> String {
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
                throw CardExampleError.serviceUnavailable(message: "Invalid HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let serverMessage = extractOpenAIErrorMessage(from: data)
                logger.error("Card example failed. status=\(http.statusCode)")
                throw mapStatusCodeToError(http.statusCode, serverMessage: serverMessage)
            }

            let chatResponse = try JSONDecoder().decode(OpenAICardExampleChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content else {
                throw CardExampleError.invalidResponse(message: "Missing choices[0].message.content")
            }
            return content
        } catch let error as CardExampleError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw CardExampleError.timeout
        } catch let error as URLError {
            throw CardExampleError.serviceUnavailable(message: "Network error: \(error.localizedDescription)")
        } catch {
            throw CardExampleError.invalidResponse(message: error.localizedDescription)
        }
    }

    private func buildPayload(systemPrompt: String, userPrompt: String, schemaName: String, schema: [String: Any], temperature: Double) -> [String: Any] {
        [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": schemaName,
                    "strict": true,
                    "schema": schema
                ]
            ],
            "temperature": temperature
        ]
    }

    private var vocabularySystemPrompt: String {
        """
        你是韩语学习卡片例句生成助手。请基于词条和原句，生成 1 条自然的韩语例句及中文意思。

        要求：
        1) 韩语例句必须包含该词条本身，或该词条在自然韩语中的合理活用形。
           例如词条是 맛있다，例句可以使用 맛있어 / 맛있어요。
        2) 例句要简短自然，像真实聊天或日常口语，适合初中级学习者。
        3) 尽量贴近原句语境，但不要复制原句；需要生成新的例句。
        4) 不要生成太书面、太复杂、太长的句子。
        5) 中文意思要准确、口语化。
        6) 只输出 JSON，不要输出额外文本。
        """
    }

    private var grammarSystemPrompt: String {
        """
        你是韩语语法卡片例句生成助手。请基于语法点和原句，生成 1-2 条自然韩语例句及中文意思。

        要求：
        1) 每条例句必须清楚体现该语法点的常见用法。
        2) 例句中必须实际使用该语法点，或使用它在自然韩语中的合理变体。
           例如语法点是 -아/어도 되다，例句可以使用 가도 돼요 / 먹어도 돼。
        3) 例句要简短自然，优先日常聊天口语，适合初中级学习者。
        4) 尽量贴近原句语境，但不要直接复制原句。
        5) 不要使用过难词汇或复杂长句。
        6) 中文意思要准确、口语化。
        7) 只输出 JSON，不要输出额外文本。
        """
    }

    private var vocabularySchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "example_ko": ["type": "string"],
                "example_zh": ["type": "string"]
            ],
            "required": ["example_ko", "example_zh"]
        ]
    }

    private var grammarSchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "items": [
                    "type": "array",
                    "minItems": 1,
                    "maxItems": 2,
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "example_ko": ["type": "string"],
                            "example_zh": ["type": "string"]
                        ],
                        "required": ["example_ko", "example_zh"]
                    ]
                ]
            ],
            "required": ["items"]
        ]
    }

    private func mapStatusCodeToError(_ statusCode: Int, serverMessage: String?) -> CardExampleError {
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
        guard let payload = try? JSONDecoder().decode(OpenAICardExampleErrorEnvelope.self, from: data) else {
            return nil
        }
        return payload.error.message
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
}

struct CardExampleServiceFactory {
    static func makeDefaultService() -> CardExampleServicing {
        let config = OpenAIConfig.load()

        if config.useRealService {
            if let service = try? OpenAICardExampleService(config: config) {
                return service
            }
        }

        return MockCardExampleService()
    }
}

private struct OpenAICardExampleChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAICardExampleErrorEnvelope: Decodable {
    struct OpenAIError: Decodable {
        let message: String
    }
    let error: OpenAIError
}

private struct OpenAIVocabExampleEnvelope: Decodable {
    let exampleKo: String
    let exampleZh: String

    enum CodingKeys: String, CodingKey {
        case exampleKo = "example_ko"
        case exampleZh = "example_zh"
    }
}

private struct OpenAIGrammarExamplesEnvelope: Decodable {
    let items: [OpenAIGrammarExampleItem]
}

private struct OpenAIGrammarExampleItem: Decodable {
    let exampleKo: String
    let exampleZh: String

    enum CodingKeys: String, CodingKey {
        case exampleKo = "example_ko"
        case exampleZh = "example_zh"
    }
}
