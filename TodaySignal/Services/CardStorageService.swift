import Foundation
import SwiftData

@Model
final class PersistedVocabularyCard {
    @Attribute(.unique) var id: UUID
    var word: String
    var meaningZH: String
    var pronunciation: String
    var partOfSpeech: String
    var originalSentence: String
    var exampleSentence: String
    var exampleTranslationZH: String
    var usageNote: String
    var sourcePointId: UUID?

    init(
        id: UUID,
        word: String,
        meaningZH: String,
        pronunciation: String,
        partOfSpeech: String,
        originalSentence: String,
        exampleSentence: String,
        exampleTranslationZH: String,
        usageNote: String,
        sourcePointId: UUID?
    ) {
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

@Model
final class PersistedGrammarCard {
    @Attribute(.unique) var id: UUID
    var point: String
    var meaningZH: String
    var toneNote: String
    var originalSentence: String
    var usageContext: String
    var exampleSentencesData: Data
    var sourcePointId: UUID?

    init(
        id: UUID,
        point: String,
        meaningZH: String,
        toneNote: String,
        originalSentence: String,
        usageContext: String,
        exampleSentencesData: Data,
        sourcePointId: UUID?
    ) {
        self.id = id
        self.point = point
        self.meaningZH = meaningZH
        self.toneNote = toneNote
        self.originalSentence = originalSentence
        self.usageContext = usageContext
        self.exampleSentencesData = exampleSentencesData
        self.sourcePointId = sourcePointId
    }
}

@Model
final class PersistedKnowledgeMark {
    @Attribute(.unique) var key: String
    var actionRawValue: String

    init(key: String, actionRawValue: String) {
        self.key = key
        self.actionRawValue = actionRawValue
    }
}

struct CardStorageService {
    static let shared = CardStorageService()

    private let container: ModelContainer

    private init() {
        do {
            let schema = Schema([
                PersistedVocabularyCard.self,
                PersistedGrammarCard.self,
                PersistedKnowledgeMark.self
            ])
            let config = ModelConfiguration("TodaySignalLocalStorage")
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    private var context: ModelContext {
        ModelContext(container)
    }

    func loadVocabularyCards() -> [VocabularyCard] {
        do {
            let items = try context.fetch(FetchDescriptor<PersistedVocabularyCard>(sortBy: [SortDescriptor(\.id)]))
            return items.reversed().map {
                VocabularyCard(
                    id: $0.id,
                    word: $0.word,
                    meaningZH: $0.meaningZH,
                    pronunciation: $0.pronunciation,
                    partOfSpeech: $0.partOfSpeech,
                    originalSentence: $0.originalSentence,
                    exampleSentence: $0.exampleSentence,
                    exampleTranslationZH: $0.exampleTranslationZH,
                    usageNote: $0.usageNote,
                    sourcePointId: $0.sourcePointId
                )
            }
        } catch {
            return []
        }
    }

    func loadGrammarCards() -> [GrammarCard] {
        do {
            let items = try context.fetch(FetchDescriptor<PersistedGrammarCard>(sortBy: [SortDescriptor(\.id)]))
            return items.reversed().map {
                GrammarCard(
                    id: $0.id,
                    point: $0.point,
                    meaningZH: $0.meaningZH,
                    toneNote: $0.toneNote,
                    originalSentence: $0.originalSentence,
                    exampleSentences: decodeExampleSentences(from: $0.exampleSentencesData),
                    usageContext: $0.usageContext,
                    sourcePointId: $0.sourcePointId
                )
            }
        } catch {
            return []
        }
    }

    func loadKnowledgeMarks() -> [String: KnowledgeAction] {
        do {
            let items = try context.fetch(FetchDescriptor<PersistedKnowledgeMark>())
            var output: [String: KnowledgeAction] = [:]
            for item in items {
                if let action = KnowledgeAction(rawValue: item.actionRawValue) {
                    output[item.key] = action
                }
            }
            return output
        } catch {
            return [:]
        }
    }

    func replaceAll(vocabularyCards: [VocabularyCard], grammarCards: [GrammarCard]) {
        do {
            let context = context

            let existingVocab = try context.fetch(FetchDescriptor<PersistedVocabularyCard>())
            let existingGrammar = try context.fetch(FetchDescriptor<PersistedGrammarCard>())

            for item in existingVocab { context.delete(item) }
            for item in existingGrammar { context.delete(item) }

            for card in vocabularyCards {
                context.insert(
                    PersistedVocabularyCard(
                        id: card.id,
                        word: card.word,
                        meaningZH: card.meaningZH,
                        pronunciation: card.pronunciation,
                        partOfSpeech: card.partOfSpeech,
                        originalSentence: card.originalSentence,
                        exampleSentence: card.exampleSentence,
                        exampleTranslationZH: card.exampleTranslationZH,
                        usageNote: card.usageNote,
                        sourcePointId: card.sourcePointId
                    )
                )
            }

            for card in grammarCards {
                context.insert(
                    PersistedGrammarCard(
                        id: card.id,
                        point: card.point,
                        meaningZH: card.meaningZH,
                        toneNote: card.toneNote,
                        originalSentence: card.originalSentence,
                        usageContext: card.usageContext,
                        exampleSentencesData: encodeExampleSentences(card.exampleSentences),
                        sourcePointId: card.sourcePointId
                    )
                )
            }

            try context.save()
        } catch {
            // no-op for MVP, keep in-memory state intact
        }
    }

    func saveKnowledgeMark(key: String, action: KnowledgeAction) {
        do {
            let context = context
            let matches = try context.fetch(FetchDescriptor<PersistedKnowledgeMark>(
                predicate: #Predicate { $0.key == key }
            ))

            if let existing = matches.first {
                if action == .open {
                    context.delete(existing)
                } else {
                    existing.actionRawValue = action.rawValue
                }
            } else if action == .known || action == .dismissed || action == .saved {
                context.insert(PersistedKnowledgeMark(key: key, actionRawValue: action.rawValue))
            }

            try context.save()
        } catch {
            // no-op for MVP
        }
    }

    func clearAllPersistedData() {
        do {
            let context = context

            let existingVocab = try context.fetch(FetchDescriptor<PersistedVocabularyCard>())
            let existingGrammar = try context.fetch(FetchDescriptor<PersistedGrammarCard>())
            let existingMarks = try context.fetch(FetchDescriptor<PersistedKnowledgeMark>())

            for item in existingVocab { context.delete(item) }
            for item in existingGrammar { context.delete(item) }
            for item in existingMarks { context.delete(item) }

            try context.save()
        } catch {
            // no-op for MVP
        }
    }

    private struct ExampleSentenceDTO: Codable {
        let ko: String
        let zh: String
    }

    private func encodeExampleSentences(_ input: [(ko: String, zh: String)]) -> Data {
        let dto = input.map { ExampleSentenceDTO(ko: $0.ko, zh: $0.zh) }
        return (try? JSONEncoder().encode(dto)) ?? Data()
    }

    private func decodeExampleSentences(from data: Data) -> [(ko: String, zh: String)] {
        guard let dto = try? JSONDecoder().decode([ExampleSentenceDTO].self, from: data) else {
            return []
        }
        return dto.map { ($0.ko, $0.zh) }
    }
}
