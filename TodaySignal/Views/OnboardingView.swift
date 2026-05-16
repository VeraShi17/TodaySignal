import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPageView(
                    index: 0,
                    title: "读懂韩语聊天里的\n小信号",
                    subtitle: "上传 idol bubble / DM / 聊天截图，帮你看懂每句话的意思、词尾和语气。",
                    illustration: { BubblesIllustration() },
                    onNext: { withAnimation { currentPage = 1 } },
                    onSkip: { hasCompletedOnboarding = true }
                )
                .tag(0)

                OnboardingPageView(
                    index: 1,
                    title: "先确认文字，\n再开始解析",
                    subtitle: "OCR 后你可以逐条修改识别出的气泡文字，避免识别错误影响解释。",
                    illustration: { EditBubbleIllustration() },
                    onNext: { withAnimation { currentPage = 2 } },
                    onSkip: { hasCompletedOnboarding = true }
                )
                .tag(1)

                OnboardingPageView(
                    index: 2,
                    title: "把不认识的表达\n变成学习卡片",
                    subtitle: "生词、词尾、语法点都可以保存成卡片，之后慢慢复习。",
                    illustration: { CardsIllustration() },
                    isLastPage: true,
                    onStart: { hasCompletedOnboarding = true },
                    onSkip: { hasCompletedOnboarding = true }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }
}

// MARK: - Single Onboarding Page

struct OnboardingPageView<Illustration: View>: View {
    let index: Int
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration
    var isLastPage: Bool = false
    var onNext: (() -> Void)?
    var onStart: (() -> Void)?
    var onSkip: (() -> Void)?

    var body: some View {
        ZStack {
            // Decorative gradient wash
            VStack {
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "FFE4EC"), .clear],
                        center: UnitPoint(x: 0.3, y: 0),
                        startRadius: 0,
                        endRadius: 300
                    )
                    RadialGradient(
                        colors: [Color.bgLavender, .clear],
                        center: UnitPoint(x: 0.8, y: 0.2),
                        startRadius: 0,
                        endRadius: 250
                    )
                }
                .frame(height: 360)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("跳过") {
                        onSkip?()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkMute)
                    .padding(.trailing, 22)
                }
                .padding(.top, 16)

                Spacer()

                // Illustration
                illustration()
                    .frame(height: 200)
                    .padding(.bottom, 36)

                // Title
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink)
                    .lineSpacing(4)
                    .padding(.bottom, 14)

                // Body text
                Text(subtitle)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink2)
                    .lineSpacing(6)
                    .frame(maxWidth: 280)

                Spacer()

                // Bottom area: dots + navigation
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i == index ? Color.pink : Color.pinkSoft)
                                .frame(width: i == index ? 22 : 6, height: 6)
                                .animation(.easeInOut(duration: 0.2), value: index)
                        }
                    }

                    if isLastPage {
                        PrimaryButton(title: "开始使用") {
                            onStart?()
                        }
                        .padding(.horizontal, 28)
                    } else {
                        HStack {
                            Text("\(index + 1) / 3")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkMute)
                            Spacer()
                            Button(action: { onNext?() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.pink)
                                    .clipShape(Circle())
                                    .shadow(color: Color.pink.opacity(0.5), radius: 12, y: 6)
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                }
                .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - Illustrations

struct BubblesIllustration: View {
    var body: some View {
        ZStack {
            // Sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundStyle(Color.lavender)
                .offset(x: -100, y: -80)
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color.coral)
                .offset(x: 120, y: -30)
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color.pink)
                .offset(x: -110, y: 60)

            // Left bubble
            Text("오늘 뭐해? ㅋㅋ")
                .font(.system(size: 16))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20)
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20)
                        .stroke(Color.line, lineWidth: 1)
                )
                .shadow(color: Color(hex: "3C2832").opacity(0.1), radius: 10, y: 6)
                .offset(x: -50, y: -40)

            // Signal blip (center sparkle circle)
            Image(systemName: "sparkle")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: [Color(hex: "FFB6C7"), Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: Color.pink.opacity(0.4), radius: 10, y: 4)

            // Right bubble
            Text("나 지금 공부 중이야")
                .font(.system(size: 16))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.pinkTint)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 6)
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 6)
                        .stroke(Color.pinkSoft, lineWidth: 1)
                )
                .shadow(color: Color.pink.opacity(0.15), radius: 10, y: 6)
                .offset(x: 40, y: 50)
        }
    }
}

struct EditBubbleIllustration: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color.lavender)
                .offset(x: -120, y: -80)

            // Dashed editing bubble
            Text("오늘 뭐해? ㅋㅋ")
                .font(.system(size: 16))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20)
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20)
                        .stroke(Color.pink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
                .offset(x: -30, y: -40)

            // Edit icon circle
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.pink)
                .clipShape(Circle())
                .shadow(color: Color.pink.opacity(0.45), radius: 8, y: 4)
                .offset(x: 100, y: -50)

            // Second bubble
            Text("난 지금 공부 중")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.pinkTint)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20)
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20)
                        .stroke(Color.pinkSoft, lineWidth: 1)
                )
                .offset(x: 20, y: 50)
        }
    }
}

struct CardsIllustration: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color.coral)
                .offset(x: -120, y: -80)
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color.lavender)
                .offset(x: 130, y: 70)

            // Card 1
            cardItem(word: "오늘", meaning: "今天", bgColor: .white, rotation: -10)
                .offset(x: -80, y: -20)

            // Card 2
            cardItem(word: "-잖아", meaning: "不是…嘛", bgColor: Color.bgLavender, rotation: 4)
                .offset(x: 0, y: -30)

            // Card 3
            cardItem(word: "응원", meaning: "应援", bgColor: Color.pinkTint, rotation: -3)
                .offset(x: 80, y: 0)
        }
    }

    private func cardItem(word: String, meaning: String, bgColor: Color, rotation: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("韩 · KO")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.pinkDeep)
                .tracking(0.6)

            Text(word)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ink)
                .padding(.top, 8)

            Text(meaning)
                .font(.system(size: 13))
                .foregroundStyle(Color.ink2)
                .padding(.top, 4)

            Spacer()

            HStack {
                Text("example")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkMute)
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkMute)
            }
        }
        .padding(14)
        .frame(width: 120, height: 150)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.line, lineWidth: 1)
        )
        .shadow(color: Color(hex: "3C2832").opacity(0.12), radius: 14, y: 10)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
