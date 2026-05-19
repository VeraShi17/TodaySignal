import Foundation

// MARK: - Enums

enum BubbleSide: String, Codable {
    case left, right
}

enum SpeakerRole: String, Codable {
    case idol, user
}

enum BubbleType: String, Codable {
    case text, image
}

enum ToneLabel: String, Codable, CaseIterable {
    case neutral = "普通陈述"
    case casual = "亲近随意"
    case cute = "可爱 / 撒娇"
    case joking = "吐槽 / 开玩笑"
    case caring = "安慰 / 关心"
    case polite = "礼貌表达"
    case cold = "冷淡 / 简短"

    var pillKind: TonePillKind {
        switch self {
        case .neutral: return .gray
        case .casual: return .pink
        case .cute: return .coral
        case .joking: return .gray
        case .caring: return .lavender
        case .polite: return .mint
        case .cold: return .gray
        }
    }
}

enum TonePillKind {
    case pink, coral, lavender, mint, cream, gray
}

enum KnowledgePointType: String, Codable {
    case vocabulary
    case grammar
}

enum KnowledgeAction: String, Codable {
    case open         // not yet acted on
    case known        // user marked as known
    case dismissed    // unknown but no card
    case saved        // card generated
}

enum LearningCardType: String, Codable {
    case vocabulary
    case grammar
}

enum ReplyTone: String, Codable, CaseIterable {
    case natural = "自然"
    case cute = "可爱"
    case polite = "礼貌"
    case friendly = "朋友感"
    case subtleFlirty = "暧昧感"
}

enum ReplyCheckStatus: String, Codable {
    case natural
    case needsImprovement
}

// MARK: - Models

struct ChatBubble: Identifiable {
    let id: UUID
    var side: BubbleSide
    var speakerRole: SpeakerRole
    var type: BubbleType
    var text: String
    var isEditable: Bool

    init(id: UUID = UUID(), side: BubbleSide, speakerRole: SpeakerRole, type: BubbleType = .text, text: String, isEditable: Bool = true) {
        self.id = id
        self.side = side
        self.speakerRole = speakerRole
        self.type = type
        self.text = text
        self.isEditable = isEditable
    }
}

struct KnowledgePoint: Identifiable {
    let id: UUID
    let type: KnowledgePointType
    let term: String            // word or grammar point
    let meaningZH: String
    let pronunciation: String?  // only for vocab
    let partOfSpeech: String?   // only for vocab
    let toneNote: String?       // only for grammar
    let usageNote: String
    var action: KnowledgeAction

    init(id: UUID = UUID(), type: KnowledgePointType, term: String, meaningZH: String, pronunciation: String? = nil, partOfSpeech: String? = nil, toneNote: String? = nil, usageNote: String, action: KnowledgeAction = .open) {
        self.id = id
        self.type = type
        self.term = term
        self.meaningZH = meaningZH
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.toneNote = toneNote
        self.usageNote = usageNote
        self.action = action
    }
}

struct AnalysisResult: Identifiable {
    let id: UUID
    let bubbleID: UUID
    let originalText: String
    let translationZH: String
    let toneLabels: [ToneLabel]
    var vocabulary: [KnowledgePoint]
    var grammarPoints: [KnowledgePoint]
    let failureMessage: String?

    init(id: UUID = UUID(), bubbleID: UUID = UUID(), originalText: String, translationZH: String, toneLabels: [ToneLabel], vocabulary: [KnowledgePoint] = [], grammarPoints: [KnowledgePoint] = [], failureMessage: String? = nil) {
        self.id = id
        self.bubbleID = bubbleID
        self.originalText = originalText
        self.translationZH = translationZH
        self.toneLabels = toneLabels
        self.vocabulary = vocabulary
        self.grammarPoints = grammarPoints
        self.failureMessage = failureMessage
    }
}

struct VocabularyCard: Identifiable {
    let id: UUID
    let word: String
    let meaningZH: String
    let pronunciation: String
    let partOfSpeech: String
    let originalSentence: String
    let exampleSentence: String
    let exampleTranslationZH: String
    let usageNote: String
    let sourcePointId: UUID?  // tracks which KnowledgePoint generated this card

    init(id: UUID = UUID(), word: String, meaningZH: String, pronunciation: String, partOfSpeech: String, originalSentence: String, exampleSentence: String, exampleTranslationZH: String, usageNote: String, sourcePointId: UUID? = nil) {
        self.id = id
        self.word = word
        self.meaningZH = meaningZH
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.originalSentence = originalSentence
        self.exampleSentence = exampleSentence
        self.exampleTranslationZH = exampleTranslationZH
        self.usageNote = usageNote
        self.sourcePointId = sourcePointId
    }
}

struct GrammarCard: Identifiable {
    let id: UUID
    let point: String
    let meaningZH: String
    let toneNote: String
    let originalSentence: String
    let exampleSentences: [(ko: String, zh: String)]
    let usageContext: String
    let sourcePointId: UUID?  // tracks which KnowledgePoint generated this card

    init(id: UUID = UUID(), point: String, meaningZH: String, toneNote: String, originalSentence: String, exampleSentences: [(ko: String, zh: String)], usageContext: String, sourcePointId: UUID? = nil) {
        self.id = id
        self.point = point
        self.meaningZH = meaningZH
        self.toneNote = toneNote
        self.originalSentence = originalSentence
        self.exampleSentences = exampleSentences
        self.usageContext = usageContext
        self.sourcePointId = sourcePointId
    }
}

struct ReplySuggestion: Identifiable {
    let id: UUID
    let replyKo: String
    let replyZh: String
    let tone: ReplyTone
    let noteZh: String

    init(id: UUID = UUID(), replyKo: String, replyZh: String, tone: ReplyTone, noteZh: String) {
        self.id = id
        self.replyKo = replyKo
        self.replyZh = replyZh
        self.tone = tone
        self.noteZh = noteZh
    }
}

struct ReplyCheckResult: Identifiable {
    let id: UUID
    let bubbleID: UUID?
    let originalReply: String
    let status: ReplyCheckStatus
    let feedbackZh: String
    let issueZh: String?
    let suggestedReplyKo: String?
    let suggestedReplyZh: String?
    let failureMessage: String?

    init(
        id: UUID = UUID(),
        bubbleID: UUID?,
        originalReply: String,
        status: ReplyCheckStatus,
        feedbackZh: String,
        issueZh: String?,
        suggestedReplyKo: String?,
        suggestedReplyZh: String?,
        failureMessage: String? = nil
    ) {
        self.id = id
        self.bubbleID = bubbleID
        self.originalReply = originalReply
        self.status = status
        self.feedbackZh = feedbackZh
        self.issueZh = issueZh
        self.suggestedReplyKo = suggestedReplyKo
        self.suggestedReplyZh = suggestedReplyZh
        self.failureMessage = failureMessage
    }
}

struct FeedbackMessage: Identifiable {
    let id: UUID
    let isUser: Bool
    let text: String

    init(id: UUID = UUID(), isUser: Bool, text: String) {
        self.id = id
        self.isUser = isUser
        self.text = text
    }
}

// MARK: - Mock Data

struct MockData {

    // MARK: Chat Bubbles (for TextConfirmationView)
    static let chatBubbles: [ChatBubble] = [
        ChatBubble(side: .left, speakerRole: .idol, text: "오늘 뭐해? ㅋㅋ"),
        ChatBubble(side: .right, speakerRole: .user, text: "나 지금 공부 중이야"),
        ChatBubble(side: .left, speakerRole: .idol, type: .image, text: "[图片]"),
        ChatBubble(side: .left, speakerRole: .idol, text: "이거 봤어? 너무 귀엽잖아ㅋㅋ"),
        ChatBubble(side: .right, speakerRole: .user, text: "ㅋㅋㅋㅋ 진짜 귀엽다"),
    ]

    // MARK: Analysis Results (for AnalysisResultView)
    static let analysisResults: [AnalysisResult] = [
        AnalysisResult(
            originalText: "오늘 뭐해? ㅋㅋ",
            translationZH: "今天在干嘛？哈哈",
            toneLabels: [.casual],
            vocabulary: [
                KnowledgePoint(type: .vocabulary, term: "오늘", meaningZH: "今天", pronunciation: "[오늘]", partOfSpeech: "名词 / 副词", usageNote: "聊天中常用于开启话题，类似中文的\"今天\"。"),
            ],
            grammarPoints: [
                KnowledgePoint(type: .grammar, term: "-해?", meaningZH: "做……吗？", toneNote: "平语疑问，语气自然亲近", usageNote: "适合朋友、熟人、亲近关系中使用。"),
            ]
        ),
        AnalysisResult(
            originalText: "이거 봤어? 너무 귀엽잖아ㅋㅋ",
            translationZH: "看到这个了吗？真的太可爱了哈哈",
            toneLabels: [.cute, .joking],
            vocabulary: [
                KnowledgePoint(type: .vocabulary, term: "귀엽다", meaningZH: "可爱", pronunciation: "[귀엽따]", partOfSpeech: "形容词", usageNote: "韩语中常用来形容可爱的事物，聊天中高频出现。"),
            ],
            grammarPoints: [
                KnowledgePoint(type: .grammar, term: "-잖아", meaningZH: "不是……嘛 / 你也知道……", toneNote: "带有提醒、强调或拉近关系的语气", usageNote: "常用于熟人、朋友、亲近关系中。正式场合需谨慎使用。"),
            ]
        ),
    ]

    // MARK: Vocabulary Cards (for CardLibraryView)
    static let vocabularyCards: [VocabularyCard] = [
        VocabularyCard(word: "번역", meaningZH: "翻译", pronunciation: "[버녁]", partOfSpeech: "名词", originalSentence: "이거 번역해줄 수 있어?", exampleSentence: "한국어 문장을 중국어로 번역했어요.", exampleTranslationZH: "我把韩语句子翻译成了中文。", usageNote: "常用于表示翻译文本或语言内容。"),
        VocabularyCard(word: "응원", meaningZH: "应援 / 加油", pronunciation: "[응원]", partOfSpeech: "名词", originalSentence: "항상 응원하고 있어요!", exampleSentence: "콘서트에서 응원봉을 흔들었어요.", exampleTranslationZH: "在演唱会上挥舞了应援棒。", usageNote: "粉丝文化中的高频词，表示支持和加油。"),
        VocabularyCard(word: "귀엽다", meaningZH: "可爱", pronunciation: "[귀엽따]", partOfSpeech: "形容词", originalSentence: "너무 귀엽잖아ㅋㅋ", exampleSentence: "이 강아지 진짜 귀엽다!", exampleTranslationZH: "这只小狗真的好可爱！", usageNote: "韩语中形容可爱的高频词，口语和书面语都常用。"),
        VocabularyCard(word: "오늘", meaningZH: "今天", pronunciation: "[오늘]", partOfSpeech: "名词 / 副词", originalSentence: "오늘 뭐해?", exampleSentence: "오늘 날씨가 정말 좋다.", exampleTranslationZH: "今天天气真好。", usageNote: "日常高频词，用于开启话题或描述当日事务。"),
    ]

    // MARK: Grammar Cards (for CardLibraryView)
    static let grammarCards: [GrammarCard] = [
        GrammarCard(point: "-잖아", meaningZH: "不是……嘛 / 你也知道……", toneNote: "带提醒、强调、拉近关系的语气", originalSentence: "나 어제 말했잖아.", exampleSentences: [("우리 친구잖아.", "我们不是朋友嘛。"), ("그거 내가 했잖아.", "那个不是我做的嘛。")], usageContext: "常用于熟人、朋友、亲近关系中。正式场合需谨慎使用。"),
        GrammarCard(point: "-해?", meaningZH: "做……吗？", toneNote: "平语疑问，自然亲近", originalSentence: "오늘 뭐해? ㅋㅋ", exampleSentences: [("지금 뭐 해?", "你现在在做什么？"), ("내일 시간 있어?", "明天有时间吗？")], usageContext: "平语疑问句，适合朋友和熟人之间使用。"),
        GrammarCard(point: "-아/어 줄 수 있어?", meaningZH: "可以……吗？", toneNote: "请求，语气友好", originalSentence: "이거 번역해줄 수 있어?", exampleSentences: [("이거 좀 도와줄 수 있어?", "你能帮我一下吗？")], usageContext: "友好地请求帮助时使用，比较自然随和。"),
    ]

    // MARK: Recent analyses (for HomeView)
    static let recentAnalyses: [(tag: String, preview: String, meta: String, pillKind: TonePillKind)] = [
        (tag: "亲近随意", preview: "오늘 뭐해? ㅋㅋ", meta: "今天 · 3 个新卡片", pillKind: .pink),
        (tag: "可爱 / 撒娇", preview: "나 보고 싶었어?", meta: "昨天 · 2 个新卡片", pillKind: .coral),
        (tag: "安慰 / 关心", preview: "괜찮아, 무리하지 마", meta: "5月10日 · 1 个新卡片", pillKind: .lavender),
    ]

    static let v1ReplySuggestions: [ReplySuggestion] = [
        ReplySuggestion(replyKo: "오늘도 고생 많았어. 따뜻한 거 꼭 챙겨 먹어♡", replyZh: "今天也辛苦了，记得吃点热的♡", tone: .natural, noteZh: "自然温柔，适合日常关心。"),
        ReplySuggestion(replyKo: "헉 너무 귀엽다… 나 또 심장 아파 ㅋㅋ", replyZh: "啊太可爱了…我又心动了哈哈", tone: .cute, noteZh: "可爱+轻松玩笑感。"),
        ReplySuggestion(replyKo: "오늘도 덕분에 힘났어요. 푹 쉬어요!", replyZh: "今天也因为你获得力量了。好好休息！", tone: .polite, noteZh: "更礼貌，适合偏正式粉丝语气。")
    ]

    static let v1ReplyCheckNatural = ReplyCheckResult(
        bubbleID: nil,
        originalReply: "오늘도 수고했어요!",
        status: .natural,
        feedbackZh: "这句表达自然，没有明显问题。语气礼貌、温柔，适合粉丝回复 idol。",
        issueZh: nil,
        suggestedReplyKo: nil,
        suggestedReplyZh: nil
    )

    static let v1ReplyCheckNeedsImprovement = ReplyCheckResult(
        bubbleID: nil,
        originalReply: "나는 너를 많이 좋아해요",
        status: .needsImprovement,
        feedbackZh: "这句可以更自然一点。意思能理解，但语气稍微有点直接。",
        issueZh: "建议换成更常见的粉丝表达，既自然又不冒犯边界。",
        suggestedReplyKo: "항상 응원하고 있어요!",
        suggestedReplyZh: "我一直都在为你应援！"
    )

    static let v1FeedbackMock: [FeedbackMessage] = [
        FeedbackMessage(isUser: true, text: "这里为什么用 -는데？"),
        FeedbackMessage(isUser: false, text: "这里的 -는데 有承接语气，先铺垫背景再引出后文，所以语气会更自然。")
    ]
}
