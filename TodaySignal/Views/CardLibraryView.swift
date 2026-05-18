import SwiftUI

struct CardLibraryView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: CardTab = .vocabulary
    @State private var expandedCardId: UUID?
    @State private var expandedGrammarCardId: UUID?

    enum CardTab: String, CaseIterable {
        case vocabulary = "生词"
        case grammar = "语法 / 词尾"
    }

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .lastTextBaseline) {
                    Text("卡片库")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("本机 · \(appState.totalCardCount) 张")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkMute)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Segmented control
                HStack(spacing: 4) {
                    ForEach(CardTab.allCases, id: \.self) { tab in
                        let isSelected = tab == selectedTab
                        let count = tab == .vocabulary ? appState.vocabularyCards.count : appState.grammarCards.count
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                            HStack(spacing: 6) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .semibold))

                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.pinkTint : .clear)
                                    .foregroundStyle(isSelected ? Color.pinkDeep : Color.inkFaint)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(isSelected ? .white : .clear)
                            .foregroundStyle(isSelected ? Color.ink : Color.inkMute)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: isSelected ? Color(hex: "3C2832").opacity(0.06) : .clear, radius: 4, y: 2)
                        }
                    }
                }
                .padding(4)
                .background(Color(hex: "F2EAEC"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 22)
                .padding(.bottom, 4)

                // Content
                if selectedTab == .vocabulary && appState.vocabularyCards.isEmpty || selectedTab == .grammar && appState.grammarCards.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if selectedTab == .vocabulary {
                                ForEach(appState.vocabularyCards) { card in
                                    VocabCardRow(
                                        card: card,
                                        isExpanded: expandedCardId == card.id,
                                        onToggle: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                expandedCardId = expandedCardId == card.id ? nil : card.id
                                            }
                                        },
                                        onDelete: {
                                            withAnimation {
                                                appState.deleteVocabCard(card.id)
                                            }
                                        }
                                    )
                                }
                            } else {
                                ForEach(appState.grammarCards) { card in
                                    GrammarCardRow(
                                        card: card,
                                        isExpanded: expandedGrammarCardId == card.id,
                                        onToggle: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                expandedGrammarCardId = expandedGrammarCardId == card.id ? nil : card.id
                                            }
                                        },
                                        onDelete: {
                                            withAnimation {
                                                appState.deleteGrammarCard(card.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 36))
                .foregroundStyle(Color.pink)
                .frame(width: 96, height: 96)
                .background(Color.pinkTint)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.bottom, 18)

            Text(selectedTab == .vocabulary ? "还没有生词卡片" : "还没有语法卡片")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 6)

            Text("上传一张聊天截图，保存今天学到的新词吧。")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkMute)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            PrimaryButton(title: "上传聊天截图", icon: "camera.fill", isFullWidth: false) {
                appState.selectedTab = .analysis
            }
            .padding(.top, 22)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Vocab Card Row

struct VocabCardRow: View {
    let card: VocabularyCard
    let isExpanded: Bool
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(card.word)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.ink)
                            Text(card.pronunciation)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundStyle(Color.inkMute)
                            TonePillView(text: card.partOfSpeech, kind: .lavender)
                        }
                        Text(card.meaningZH)
                            .font(.system(size: 14.5))
                            .foregroundStyle(Color.ink2)

                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.inkMute)
                            Text(card.originalSentence)
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.inkMute)
                                .lineLimit(1)
                        }
                        .padding(.top, 2)
                    }

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkFaint)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.vertical, 14)

                    aiExampleCallout(examples: [(ko: card.exampleSentence, zh: card.exampleTranslationZH)])

                    Text("用法笔记")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color.inkMute)
                        .tracking(0.6)
                        .padding(.top, 14)

                    Text(card.usageNote)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ink2)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isExpanded ? Color.pinkSoft : Color.line, lineWidth: 1)
        )
        .shadow(color: isExpanded ? Color.pink.opacity(0.25) : .clear, radius: 14, y: 10)
    }
}

// MARK: - Grammar Card Row

struct GrammarCardRow: View {
    let card: GrammarCard
    let isExpanded: Bool
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(card.point)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.ink)
                            TonePillView(text: "语法", kind: .coral)
                        }
                        Text(card.meaningZH)
                            .font(.system(size: 14.5))
                            .foregroundStyle(Color.ink2)

                        Text(card.toneNote)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkMute)
                            .italic()
                            .padding(.top, 2)

                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.inkMute)
                            Text(card.originalSentence)
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.inkMute)
                                .lineLimit(1)
                        }
                        .padding(.top, 4)
                    }

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkFaint)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.vertical, 14)

                    aiExampleCallout(examples: card.exampleSentences)

                    Text("适合关系 / 场景")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color.inkMute)
                        .tracking(0.6)
                        .padding(.top, 14)

                    Text(card.usageContext)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ink2)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isExpanded ? Color.pinkSoft : Color.line, lineWidth: 1)
        )
        .shadow(color: isExpanded ? Color.pink.opacity(0.25) : .clear, radius: 14, y: 10)
    }
}

#Preview {
    CardLibraryView()
        .environment(AppState())
}
