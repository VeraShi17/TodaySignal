import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    #if DEBUG
    @State private var showClearConfirm = false
    @State private var debugTelemetrySnapshot: [(counter: DebugTelemetry.Counter, value: Int)] = []
    #endif

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text("设置")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .padding(.bottom, 16)

                    // Privacy hero card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.lavender)
                                .frame(width: 32, height: 32)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text("你的聊天，留在你手里")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.ink)
                        }

                        Text("原始截图不会长期保存；卡片只存在本机；不保存完整解析历史。")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.ink2)
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [Color.bgLavender, Color.bgSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Privacy & Data section
                    sectionTitle("隐私与数据")

                    VStack(spacing: 0) {
                        settingsRow(
                            icon: "lock.fill",
                            iconBg: Color.bgLavender,
                            iconColor: Color(hex: "7860B3"),
                            title: "原始截图处理",
                            subtitle: "OCR 后立即丢弃，不留存"
                        )
                        settingsRow(
                            icon: "bookmark.fill",
                            iconBg: Color.pinkTint,
                            iconColor: Color.pinkDeep,
                            title: "卡片存储位置",
                            subtitle: "本机数据库"
                        )
                        settingsRow(
                            icon: "sparkle",
                            iconBg: Color(hex: "FFEFE7"),
                            iconColor: Color(hex: "C8633F"),
                            title: "AI 解析说明",
                            subtitle: "确认后的文本会发送至模型"
                        )
                        settingsRow(
                            icon: "trash.fill",
                            iconBg: Color(hex: "F1ECEE"),
                            iconColor: Color(hex: "776975"),
                            title: "清除所有卡片",
                            trailing: AnyView(
                                Text("清除")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.pinkDeep)
                            ),
                            isLast: true
                        )
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    #if DEBUG
                    sectionTitle("开发调试")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("用于测试持久化：清空本机卡片、知识点标记、onboarding 状态。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.inkMute)
                            .lineSpacing(3)

                        Button {
                            showClearConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.circle.fill")
                                Text("一键清空本地数据（Debug）")
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 13.5))
                            .foregroundStyle(Color(hex: "B3474A"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: "FCEDEE"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if let clearedAt = appState.lastDebugClearAt {
                            Text("最近清空：\(clearedAt.formatted(date: .omitted, time: .standard))")
                                .font(.system(size: 11.5))
                                .foregroundStyle(Color.inkFaint)
                        }

                        Divider().padding(.vertical, 4)

                        Text("AI 降级计数")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color.ink)

                        Text(feedbackHitRateSummary)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color(hex: "3F6FB8"))

                        Text(replySuggestionHitRateSummary)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color(hex: "3F6FB8"))

                        Text(replyCheckHitRateSummary)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color(hex: "3F6FB8"))

                        ForEach(debugTelemetrySnapshot, id: \.counter.rawValue) { item in
                            HStack {
                                Text(telemetryLabel(for: item.counter))
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Color.inkMute)
                                Spacer()
                                Text("\(item.value)")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundStyle(Color.ink)
                            }
                        }

                        HStack(spacing: 10) {
                            Button("刷新计数") {
                                reloadDebugTelemetry()
                            }
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color(hex: "3F6FB8"))

                            Button("重置计数") {
                                DebugTelemetry.resetAll()
                                reloadDebugTelemetry()
                            }
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color(hex: "B3474A"))
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    #endif

                    // About section
                    sectionTitle("关于")

                    VStack(spacing: 0) {
                        settingsRow(
                            icon: "info.circle.fill",
                            iconBg: Color(hex: "E2F4EA"),
                            iconColor: Color(hex: "3F8F66"),
                            title: "오늘의 시그널 · Today's Signal",
                            subtitle: "韩语聊天截图学习助手"
                        )
                        settingsRow(
                            icon: "heart.fill",
                            iconBg: Color.pinkTint,
                            iconColor: Color.pinkDeep,
                            title: "版本",
                            trailing: AnyView(
                                Text("1.0.0 (MVP)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.inkMute)
                            )
                        )
                        settingsRow(
                            icon: "bubble.left.fill",
                            iconBg: Color.bgLavender,
                            iconColor: Color(hex: "7860B3"),
                            title: "反馈与建议",
                            isLast: true
                        )
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Footer
                    Text("Made for K-pop fans learning 한국어 ♡")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)

                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }
        }
        #if DEBUG
        .onAppear {
            reloadDebugTelemetry()
        }
        .confirmationDialog(
            "确认清空本地数据？",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("清空", role: .destructive) {
                appState.clearAllLocalDataForDebug()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除卡片、知识点标记，并重置 onboarding。")
        }
        #endif
    }

    #if DEBUG
    private func reloadDebugTelemetry() {
        let order: [DebugTelemetry.Counter] = [
            .feedbackRequestTotal,
            .feedbackFallbackTotal,
            .feedbackEmptyAnswer,
            .feedbackAnswerTooLong,
            .feedbackTooGeneric,
            .replySuggestionRequestTotal,
            .replySuggestionFallbackTotal,
            .cardExampleRequestTotal,
            .cardExampleFallbackTotal,
            .replyItemCountMismatch,
            .replyEmptyField,
            .replyTooLong,
            .replyMissingHangul,
            .replyDuplicateReply,
            .replyCheckItemCountMismatch,
            .replyCheckEmptyFeedback,
            .replyCheckNaturalHasSuggestion,
            .replyCheckNeedsSuggestionMissing,
            .replyCheckSuggestionMissingHangul,
            .replyCheckSuggestionTooLong,
            .replyCheckRequestTotal,
            .replyCheckFallbackTotal
        ]

        let values = Dictionary(uniqueKeysWithValues: DebugTelemetry.snapshot().map { ($0.counter, $0.value) })
        debugTelemetrySnapshot = order.map { ($0, values[$0] ?? 0) }
    }

    private var feedbackHitRateSummary: String {
        hitRateSummary(
            title: "追问",
            totalCounter: .feedbackRequestTotal,
            fallbackCounter: .feedbackFallbackTotal
        )
    }

    private var replySuggestionHitRateSummary: String {
        hitRateSummary(
            title: "回复建议",
            totalCounter: .replySuggestionRequestTotal,
            fallbackCounter: .replySuggestionFallbackTotal
        )
    }

    private var replyCheckHitRateSummary: String {
        hitRateSummary(
            title: "回复检查",
            totalCounter: .replyCheckRequestTotal,
            fallbackCounter: .replyCheckFallbackTotal
        )
    }

    private func hitRateSummary(title: String, totalCounter: DebugTelemetry.Counter, fallbackCounter: DebugTelemetry.Counter) -> String {
        let total = debugTelemetrySnapshot.first(where: { $0.counter == totalCounter })?.value ?? 0
        let fallback = debugTelemetrySnapshot.first(where: { $0.counter == fallbackCounter })?.value ?? 0

        guard total > 0 else {
            return "\(title)：暂无请求记录"
        }

        let pass = max(total - fallback, 0)
        let rate = Int((Double(pass) / Double(total) * 100).rounded())
        return "\(title)命中率：\(rate)%（通过 \(pass) / 总计 \(total)，fallback \(fallback)）"
    }

    private func telemetryLabel(for counter: DebugTelemetry.Counter) -> String {
        switch counter {
        case .feedbackRequestTotal:
            return "追问：总请求数"
        case .feedbackFallbackTotal:
            return "追问：fallback 次数"
        case .feedbackEmptyAnswer:
            return "追问：空回答降级"
        case .feedbackAnswerTooLong:
            return "追问：回答过长截断"
        case .feedbackTooGeneric:
            return "追问：回答过泛降级"
        case .replySuggestionRequestTotal:
            return "回复建议：总请求数"
        case .replySuggestionFallbackTotal:
            return "回复建议：fallback 次数"
        case .cardExampleRequestTotal:
            return "卡片例句：总请求数"
        case .cardExampleFallbackTotal:
            return "卡片例句：fallback 次数"
        case .replyItemCountMismatch:
            return "回复建议：条数不匹配"
        case .replyEmptyField:
            return "回复建议：字段为空"
        case .replyTooLong:
            return "回复建议：字段过长"
        case .replyMissingHangul:
            return "回复建议：韩文缺失"
        case .replyDuplicateReply:
            return "回复建议：候选重复"
        case .replyCheckItemCountMismatch:
            return "回复检查：条数不匹配"
        case .replyCheckEmptyFeedback:
            return "回复检查：反馈为空"
        case .replyCheckNaturalHasSuggestion:
            return "回复检查：natural 含建议"
        case .replyCheckNeedsSuggestionMissing:
            return "回复检查：需改进但缺建议"
        case .replyCheckSuggestionMissingHangul:
            return "回复检查：建议韩文缺失"
        case .replyCheckSuggestionTooLong:
            return "回复检查：建议字段过长"
        case .replyCheckRequestTotal:
            return "回复检查：总请求数"
        case .replyCheckFallbackTotal:
            return "回复检查：fallback 次数"
        }
    }
    #endif

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11.5, weight: .bold))
            .foregroundStyle(Color.inkMute)
            .tracking(0.8)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func settingsRow(
        icon: String,
        iconBg: Color,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        trailing: AnyView? = nil,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundStyle(Color.ink)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkMute)
                    }
                }

                Spacer()

                if let trailing = trailing {
                    trailing
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkFaint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !isLast {
                Divider()
                    .padding(.leading, 60)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
