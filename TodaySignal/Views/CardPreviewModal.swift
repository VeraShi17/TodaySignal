import SwiftUI

struct CardPreviewModal: View {
    var cardType: LearningCardType = .vocabulary
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Success bar
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bgMint)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 16)

                    // Card content
                    if cardType == .vocabulary {
                        VocabFlashcardView(card: MockData.vocabularyCards[0])
                    } else {
                        GrammarFlashcardView(card: MockData.grammarCards[0])
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        PrimaryButton(title: "知道了", action: onDismiss)

                        SecondaryButton(title: "查看卡片库", isFullWidth: false) {
                            onDismiss()
                        }
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
    CardPreviewModal(cardType: .vocabulary, onDismiss: {})
}
