import SwiftUI

struct KnowledgePointView: View {
    let point: KnowledgePoint
    var onKnow: (() -> Void)?
    var onSkip: (() -> Void)?
    var isGenerating: Bool = false
    var onSave: (() -> Void)?
    var onUndo: (() -> Void)?

    private var isVocab: Bool { point.type == .vocabulary }
    private var accentBg: Color { isVocab ? Color(hex: "F4EEFC") : Color(hex: "FFEEE6") }
    private var accentFg: Color { isVocab ? Color(hex: "7860B3") : Color(hex: "C8633F") }
    private var labelText: String { isVocab ? "生词" : "语法 / 词尾" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label row
            HStack(spacing: 8) {
                Text(labelText)
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentBg)
                    .foregroundStyle(accentFg)
                    .clipShape(Capsule())

                if point.action == .known {
                    TonePillView(text: "✓ 已标记认识", kind: .mint)
                } else if point.action == .saved {
                    TonePillView(text: "★ 已生成卡片", kind: .pink)
                } else if point.action == .dismissed {
                    TonePillView(text: "不认识", kind: .cream)
                }
            }

            // Term and meaning
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(point.term)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.ink)

                if let pronunciation = point.pronunciation {
                    Text(pronunciation)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.inkMute)
                }
            }

            Text(point.meaningZH)
                .font(.system(size: 15))
                .foregroundStyle(Color.ink2)

            // Part of speech or tone note
            if let partOfSpeech = point.partOfSpeech {
                TonePillView(text: partOfSpeech, kind: .gray)
            }

            if let toneNote = point.toneNote {
                Text(toneNote)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.inkMute)
                    .lineSpacing(3)
            }

            // Usage note
            Text(point.usageNote)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.inkMute)
                .lineSpacing(3)

            // Action row
            actionRow
        }
        .padding(16)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(point.action == .saved ? Color.pinkSoft : Color.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(1.0)
    }

    @ViewBuilder
    private var actionRow: some View {
        switch point.action {
        case .known:
            HStack {
                Label("已认识", systemImage: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.mint)
                Spacer()
                Button(action: { onUndo?() }) {
                    Text("撤销")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMute)
                }
            }
        case .saved:
            HStack {
                Label("已保存到卡片库", systemImage: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.pinkDeep)
                Spacer()
                Button(action: {}) {
                    Text("查看")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMute)
                }
            }
        case .dismissed:
            HStack {
                Label("已标记不认识", systemImage: "eye")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkMute)
                Spacer()
                Button(action: { onUndo?() }) {
                    Text("撤销")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMute)
                }
                Button(action: { onSave?() }) {
                    Text(isGenerating ? "生成中…" : "生成卡片")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Color.pinkTint)
                        .foregroundStyle(Color.pinkDeep)
                        .clipShape(Capsule())
                }
                .disabled(isGenerating)
            }
        case .open:
            // Three mutually exclusive actions:
            // 1. 认识 — user knows this, no card
            // 2. 不认识 — user doesn't know, but no card (just mark)
            // 3. 生成卡片 — user doesn't know, generate card (implies 不认识)
            HStack(spacing: 8) {
                Button(action: { onKnow?() }) {
                    Label("认识", systemImage: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color(hex: "F4ECEF"))
                        .foregroundStyle(Color.ink2)
                        .clipShape(Capsule())
                }

                Button(action: { onSkip?() }) {
                    Text("不认识")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(Color(hex: "F4ECEF"))
                        .foregroundStyle(Color.inkMute)
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: { onSave?() }) {
                    Label(isGenerating ? "生成中…" : "生成卡片", systemImage: isGenerating ? "hourglass" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(isGenerating ? Color(hex: "E5DFEE") : Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.pink.opacity(0.45), radius: 6, y: 4)
                }
                .disabled(isGenerating)
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            KnowledgePointView(
                point: KnowledgePoint(type: .vocabulary, term: "오늘", meaningZH: "今天", pronunciation: "[오늘]", partOfSpeech: "名词 / 副词", usageNote: "聊天中常用于开启话题")
            )
            KnowledgePointView(
                point: KnowledgePoint(type: .grammar, term: "-해?", meaningZH: "做……吗？", toneNote: "平语疑问，语气自然亲近", usageNote: "适合朋友、熟人使用", action: .known)
            )
            KnowledgePointView(
                point: KnowledgePoint(type: .vocabulary, term: "귀엽다", meaningZH: "可爱", pronunciation: "[귀엽따]", partOfSpeech: "形容词", usageNote: "韩语中常用来形容可爱的事物", action: .dismissed)
            )
            KnowledgePointView(
                point: KnowledgePoint(type: .vocabulary, term: "번역", meaningZH: "翻译", pronunciation: "[버녁]", partOfSpeech: "名词", usageNote: "常用于表示翻译文本或语言内容", action: .saved)
            )
        }
        .padding()
    }
    .background(Color.bgPage)
}
