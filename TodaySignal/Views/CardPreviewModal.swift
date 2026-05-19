import SwiftUI

struct CardPreviewModal: View {
    var vocabCard: VocabularyCard?
    var grammarCard: GrammarCard?
    var isLoadingExamples: Bool = false
    var isRetryingExamples: Bool = false
    var exampleErrorMessage: String?
    var onRetryExamples: (() -> Void)?
    var onDismiss: () -> Void
    var onGoToLibrary: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        if isLoadingExamples {
                            ProgressView()
                                .controlSize(.small)
                            Text("卡片已保存，正在生成例句…")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "3F6FB8"))
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.mint)
                                .clipShape(Circle())

                            Text("已保存到卡片库")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "3F8F66"))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isLoadingExamples ? Color.bgLavender : Color.bgMint)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 16)

                    // Card content — show the actual generated card
                    if let vocabCard {
                        VocabFlashcardView(card: vocabCard)
                    } else if let grammarCard {
                        GrammarFlashcardView(card: grammarCard)
                    }

                    if !isLoadingExamples, let onRetryExamples {
                        VStack(alignment: .leading, spacing: 8) {
                            if let exampleErrorMessage, !exampleErrorMessage.isEmpty {
                                Text(exampleErrorMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "B34A5E"))
                            }
                            Button {
                                onRetryExamples()
                            } label: {
                                HStack(spacing: 6) {
                                    if isRetryingExamples {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    Text(isRetryingExamples ? "正在重试例句…" : "重试生成例句")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: "7860B3"))
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.lavenderSoft, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(isRetryingExamples)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        PrimaryButton(title: "知道了", action: onDismiss)

                        SecondaryButton(title: "查看卡片库", isFullWidth: false, action: onGoToLibrary)
                    }
                    .padding(.top, 18)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
            }
        }
    }
}

#Preview {
    CardPreviewModal(
        vocabCard: MockData.vocabularyCards[0],
        isLoadingExamples: true,
        isRetryingExamples: false,
        exampleErrorMessage: nil,
        onRetryExamples: {},
        onDismiss: {},
        onGoToLibrary: {}
    )
}
