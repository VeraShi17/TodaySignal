import SwiftUI

struct AnalysisLoadingView: View {
    @Environment(AppState.self) private var appState
    var onFinished: (Bool) -> Void

    @State private var hasStarted = false
    @State private var phaseIndex = 0
    @State private var glow = false
    @State private var progress: CGFloat = 0.12
    @State private var floatPhase = false

    private let phases = [
        "正在清洗 OCR 文本…",
        "正在识别生词与语法…",
        "正在生成学习解释…"
    ]

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()

            backgroundAtmosphere

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.pinkTint.opacity(0.9), Color.bgLavender.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)
                        .scaleEffect(glow ? 1.03 : 0.96)
                        .shadow(color: Color.pink.opacity(glow ? 0.38 : 0.18), radius: glow ? 18 : 8)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.pinkDeep)
                        .rotationEffect(.degrees(glow ? 4 : -4))
                }
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: glow)

                VStack(spacing: 8) {
                    Text("正在解析中")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.ink)

                    Text("把聊天里的表达拆成可学习的词汇和语法")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Color.inkMute)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(phases[phaseIndex])
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Color(hex: "7A4A55"))
                            .id("phase-\(phaseIndex)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                        Spacer()

                        Text(remainingTimeText)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.inkMute)
                            .monospacedDigit()
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: phaseIndex)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.pinkTint.opacity(0.7))
                            .frame(height: 8)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pink, Color.pinkDeep],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.8), value: progress)
                        }
                    }
                    .frame(height: 8)

                    Text("请保持当前页面，完成后会自动进入解析结果")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.inkMute)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.line, lineWidth: 1)
                )
            }
            .padding(.horizontal, 28)
        }
        .navigationTitle("解析中")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            glow = true
            floatPhase = true
        }
        .task {
            guard !hasStarted else { return }
            hasStarted = true

            async let phaseAnimation: Void = animatePhases()
            let success = await appState.startAnalysis()
            _ = await phaseAnimation
            onFinished(success)
        }
    }

    @ViewBuilder
    private var backgroundAtmosphere: some View {
        ZStack {
            Circle()
                .fill(Color.pinkTint.opacity(0.35))
                .frame(width: 180, height: 180)
                .offset(x: -130, y: floatPhase ? -310 : -280)
                .blur(radius: 16)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: floatPhase)

            RoundedRectangle(cornerRadius: 36)
                .fill(Color.bgLavender.opacity(0.45))
                .frame(width: 220, height: 120)
                .rotationEffect(.degrees(-12))
                .offset(x: 130, y: floatPhase ? -170 : -145)
                .blur(radius: 14)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: floatPhase)

            Circle()
                .fill(Color.pinkSoft.opacity(0.3))
                .frame(width: 140, height: 140)
                .offset(x: 120, y: floatPhase ? 280 : 250)
                .blur(radius: 14)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: floatPhase)
        }
        .allowsHitTesting(false)
    }

    private var remainingTimeText: String {
        switch phaseIndex {
        case 0: return "预计剩余 15s"
        case 1: return "预计剩余 10s"
        default: return "预计剩余 5s"
        }
    }

    @MainActor
    private func animatePhases() async {
        progress = 0.2

        for index in phases.indices {
            phaseIndex = index
            let targetProgress = min(0.85, 0.2 + CGFloat(index) * 0.25)
            progress = targetProgress
            try? await Task.sleep(nanoseconds: 900_000_000)
        }

        progress = 0.94
    }
}

#Preview {
    NavigationStack {
        AnalysisLoadingView(onFinished: { _ in })
            .environment(AppState())
    }
}
