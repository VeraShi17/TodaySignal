import SwiftUI

/// Vocabulary card detail view used in CardPreviewModal and CardLibraryView
struct VocabFlashcardView: View {
    let card: VocabularyCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("VOCAB · 生词")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "F4EEFC"))
                    .foregroundStyle(Color(hex: "7860B3"))
                    .clipShape(Capsule())
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkMute)
            }
            .padding(.bottom, 14)

            // Word
            Text(card.word)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.ink)

            // Pronunciation
            Text(card.pronunciation)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color.inkMute)
                .padding(.top, 4)

            // Meaning
            Text(card.meaningZH)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.ink2)
                .padding(.top, 8)

            // Tags
            HStack(spacing: 6) {
                TonePillView(text: card.partOfSpeech, kind: .gray)
            }
            .padding(.top, 12)

            Divider()
                .padding(.vertical, 18)

            // Original sentence
            Text("来自这条聊天")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.bottom, 6)

            Text(card.originalSentence)
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Example sentence
            Text("AI 例句")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.top, 14)
                .padding(.bottom, 6)

            Text(card.exampleSentence)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ink)

            Text(card.exampleTranslationZH)
                .font(.system(size: 13))
                .foregroundStyle(Color.inkMute)
                .padding(.top, 2)

            // Usage note
            Text("用法笔记")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.top, 14)
                .padding(.bottom, 4)

            Text(card.usageNote)
                .font(.system(size: 13))
                .foregroundStyle(Color.ink2)
                .lineSpacing(4)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [.white, Color(hex: "FFF8F3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.pinkSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.pink.opacity(0.3), radius: 20, y: 12)
    }
}

/// Grammar card detail view
struct GrammarFlashcardView: View {
    let card: GrammarCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("GRAMMAR · 语法")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "FFEEE6"))
                    .foregroundStyle(Color(hex: "C8633F"))
                    .clipShape(Capsule())
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkMute)
            }
            .padding(.bottom, 14)

            // Point
            Text(card.point)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.ink)

            // Meaning
            Text(card.meaningZH)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.ink2)
                .padding(.top, 8)

            // Tone note
            Text(card.toneNote)
                .font(.system(size: 13))
                .foregroundStyle(Color.coral)
                .fontWeight(.semibold)
                .padding(.top, 8)

            Divider()
                .padding(.vertical, 18)

            // Original sentence
            Text("来自这条聊天")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.bottom, 6)

            Text(card.originalSentence)
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Example sentences
            Text("例句")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.top, 14)
                .padding(.bottom, 6)

            ForEach(Array(card.exampleSentences.enumerated()), id: \.offset) { _, example in
                Text(example.ko)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.ink)
                Text(example.zh)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkMute)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
            }

            // Usage context
            Text("使用场景")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.inkMute)
                .tracking(0.6)
                .padding(.top, 10)
                .padding(.bottom, 4)

            Text(card.usageContext)
                .font(.system(size: 13))
                .foregroundStyle(Color.ink2)
                .lineSpacing(4)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [.white, Color(hex: "FFF8F3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.pinkSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.pink.opacity(0.3), radius: 20, y: 12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            VocabFlashcardView(card: MockData.vocabularyCards[0])
            GrammarFlashcardView(card: MockData.grammarCards[0])
        }
        .padding()
    }
    .background(Color.bgPage)
}
