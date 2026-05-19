import SwiftUI

enum ConfirmMode {
    case ocr
    case reply
}

struct TextConfirmationView: View {
    @Environment(AppState.self) private var appState
    var onAnalyze: () -> Void
    var onBack: () -> Void

    @State private var mode: ConfirmMode = .ocr

    @State private var editingBubbleId: UUID?
    @State private var editingText = ""

    @State private var showInsertSheet = false
    @State private var newBubbleText = ""
    @State private var newBubbleSide: BubbleSide = .left

    @State private var showBubbleLimitAlert = false
    @State private var showExitConfirmation = false

    private let bubbleLimit = 12

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topHint
                        .padding(.bottom, 16)

                    VStack(spacing: 10) {
                        ForEach(appState.chatBubbles) { bubble in
                            bubbleRow(bubble: bubble)
                        }
                    }
                    .padding(.horizontal, 16)

                    if mode == .ocr {
                        bubbleEditHint
                            .padding(.top, 18)
                    }

                    Spacer().frame(height: 300)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
            }

            bottomPanel
        }
        .navigationTitle(mode == .reply ? "选择要回复的消息" : "确认聊天内容")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if mode == .reply {
                    Button("取消") { exitReplyMode() }
                        .foregroundStyle(Color(hex: "7860B3"))
                } else {
                    Button(action: { showExitConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                        }
                        .foregroundStyle(Color.pink)
                    }
                }
            }
        }
        .alert("退出当前页面？", isPresented: $showExitConfirmation) {
            Button("继续编辑", role: .cancel) {}
            Button("退出", role: .destructive) { onBack() }
        } message: {
            Text("当前 OCR 内容不会被保存，退出后需要重新上传截图。")
        }
        .sheet(isPresented: Binding(
            get: { editingBubbleId != nil },
            set: { isPresented in
                if !isPresented {
                    editingBubbleId = nil
                }
            }
        )) {
            if let bubbleId = editingBubbleId {
                editSheet(bubbleId: bubbleId)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showInsertSheet) {
            insertSheet
                .presentationDetents([.medium])
        }
        .alert("内容超出本次解析额度", isPresented: $showBubbleLimitAlert) {
            Button("我知道了", role: .cancel) { }
        } message: {
            Text("当前共有 \(appState.chatBubbles.count) 条气泡，单次最多支持 \(bubbleLimit) 条。请删除或合并多余的气泡后再开始解析。")
        }
    }

    // MARK: - Top hint

    @ViewBuilder
    private var topHint: some View {
        if mode == .reply {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "7860B3"))
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text("选择你想回复的 IDOL 消息")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "5E4C8A"))
                    Text("可选 1 条或多条，AI 会结合上下文生成回复建议。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "7C6BA0"))
                        .lineSpacing(4)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.bgLavender)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pinkDeep)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text("确认 OCR 文字是否正确")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "7A4A55"))
                    Text("学习解析会分析所有对方气泡 · 点击下方按钮编辑或删除单条。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "9A6F7A"))
                        .lineSpacing(4)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.bgSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Bubble row

    @ViewBuilder
    private func bubbleRow(bubble: ChatBubble) -> some View {
        let isIdol = bubble.side == appState.idolSide
        let isSelectable = mode == .reply && bubble.type == .text && isIdol
        let isSelected = appState.selectedReplyBubbleIDs.contains(bubble.id)
        let isContextOnly = mode == .reply && !isIdol

        HStack(alignment: .top, spacing: 8) {
            if isSelectable && appState.idolSide == .left {
                selectionCheckbox(selected: isSelected) {
                    toggleSelection(bubble.id)
                }
                .padding(.top, 18)
            }

            ChatBubbleView(
                bubble: bubble,
                idolSide: appState.idolSide,
                showEditControls: mode == .ocr && !appState.isAnalyzing,
                onEdit: {
                    guard !appState.isAnalyzing else { return }
                    beginEditing(bubble: bubble)
                },
                onDelete: {
                    guard !appState.isAnalyzing else { return }
                    withAnimation {
                        appState.chatBubbles.removeAll { $0.id == bubble.id }
                        appState.selectedReplyBubbleIDs.remove(bubble.id)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard isSelectable else { return }
                toggleSelection(bubble.id)
            }
            .opacity(isContextOnly ? 0.55 : 1)

            if isSelectable && appState.idolSide == .right {
                selectionCheckbox(selected: isSelected) {
                    toggleSelection(bubble.id)
                }
                .padding(.top, 18)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, isSelected ? 6 : 0)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.pinkTint.opacity(0.32) : .clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func toggleSelection(_ bubbleID: UUID) {
        guard !appState.isAnalyzing else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            appState.toggleReplyBubbleSelection(bubbleID)
        }
    }

    @ViewBuilder
    private func selectionCheckbox(selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(selected ? Color.pink : .white)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(selected ? Color.pink : Color.line2, lineWidth: 1.5)
                    )
                    .shadow(color: selected ? Color.pink.opacity(0.4) : .clear, radius: 4, y: 1)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(appState.isAnalyzing)
    }

    // MARK: - Bubble edit hint (Mode A only)

    private var bubbleEditHint: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("气泡识别不太准确？")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.inkMute)
                Text("你可以逐条编辑后再继续")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.pinkDeep)
            }

            Button {
                guard !appState.isAnalyzing else { return }
                newBubbleSide = appState.idolSide
                newBubbleText = ""
                showInsertSheet = true
            } label: {
                Label("手动插入一条消息", systemImage: "plus.bubble")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.pinkDeep)
            }
            .disabled(appState.isAnalyzing)

            Text("当前版本中气泡顺序不参与 AI 解析；手动插入默认追加到底部。")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line2, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Bottom panel

    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            Divider()
            if mode == .reply {
                replyModeBottomBar
            } else {
                ocrModeBottomBar
            }
        }
    }

    // MARK: - Mode A bottom bar

    private var ocrModeBottomBar: some View {
        @Bindable var appState = appState
        return VStack(alignment: .leading, spacing: 12) {
            // Side selector row
            HStack {
                Text("IDOL / 对方在")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color.ink2)
                    .tracking(0.4)

                Spacer()

                sideSelectorPill
            }

            // Learn analysis settings group
            if appState.hasMySideBubbles() {
                VStack(alignment: .leading, spacing: 8) {
                    Text("学习解析设置")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.inkMute)

                    Toggle(isOn: $appState.checkMyReplyEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("同时检查我的回复")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(Color.ink2)
                            Text("检查你已发出的韩语是否自然")
                                .font(.system(size: 11.5))
                                .foregroundStyle(Color.inkMute)
                        }
                    }
                    .toggleStyle(.switch)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.bgElev)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.line, lineWidth: 1)
                )
            }

            if appState.isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在解析聊天内容…")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(Color.ink2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.bgSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage = appState.analysisErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(hex: "D96A1D"))
                        .padding(.top, 1)
                    Text(errorMessage)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.ink2)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "FFF4EA"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Primary CTA: 学习解析
            PrimaryButton(
                title: appState.isAnalyzing ? "解析中…" : "学习解析",
                icon: "sparkle",
                isDisabled: appState.isAnalyzing || appState.chatBubbles.isEmpty,
                action: {
                    appState.clearAnalysisError()
                    if appState.chatBubbles.count > bubbleLimit {
                        showBubbleLimitAlert = true
                        return
                    }
                    onAnalyze()
                }
            )

            // Secondary intent: 想回复对方？ + 生成回复建议 outline
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("想回复对方？")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("选择消息 · AI 生成韩语回复")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkMute)
                }

                Spacer()

                Button {
                    guard !appState.isAnalyzing else { return }
                    enterReplyMode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 13, weight: .semibold))
                        Text("生成回复建议")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "7860B3"))
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.lavenderSoft, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.isAnalyzing)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 26)
        .background(
            Color.bgPage.opacity(0.97)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Mode B bottom bar

    private var replyModeBottomBar: some View {
        let hasSelection = !appState.selectedReplyBubbleIDs.isEmpty

        return VStack(spacing: 12) {
            Group {
                if hasSelection {
                    Text("✓ 已选 \(appState.selectedReplyBubbleIDs.count) 条 IDOL 消息")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "7860B3"))
                } else {
                    Text("点击 IDOL 气泡选择 · 至少选 1 条")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkMute)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: 18)

            HStack(spacing: 10) {
                Button {
                    exitReplyMode()
                } label: {
                    Text("取消")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink2)
                        .frame(width: 110)
                        .frame(height: 46)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.line2, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    confirmReplySelection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("确认生成回复")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(hasSelection ? Color(hex: "7860B3") : Color(hex: "E5DFEE"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: hasSelection ? Color(hex: "7860B3").opacity(0.45) : .clear, radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!hasSelection)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 26)
        .background(
            Color(hex: "F8F5FF").opacity(0.97)
                .background(.ultraThinMaterial)
        )
    }

    private var sideSelectorPill: some View {
        HStack(spacing: 2) {
            ForEach([BubbleSide.left, .right], id: \.self) { side in
                let isSelected = side == appState.idolSide
                Button {
                    guard !appState.isAnalyzing else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { appState.idolSide = side }
                } label: {
                    Text(side == .left ? "左侧" : "右侧")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.pinkDeep : Color.inkMute)
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(isSelected ? Color.white : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shadow(color: isSelected ? Color(hex: "3C2832").opacity(0.08) : .clear, radius: 4, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(hex: "F2EAEC"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Mode transitions

    private func enterReplyMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            mode = .reply
        }
    }

    private func exitReplyMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            mode = .ocr
            appState.selectedReplyBubbleIDs.removeAll()
        }
    }

    private func confirmReplySelection() {
        guard !appState.selectedReplyBubbleIDs.isEmpty else { return }
        if appState.prepareReplyContextFromSelection() {
            appState.navigationPath.append(AnalysisRoute.replySuggestion)
        }
    }

    // MARK: - Bubble editing sheet

    private func beginEditing(bubble: ChatBubble) {
        editingText = bubble.text
        editingBubbleId = bubble.id
    }

    @ViewBuilder
    private func editSheet(bubbleId: UUID) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("可直接修正 OCR 内容。若要拆分成多个气泡，请在段落之间留空行（连按两次回车）。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.inkMute)

                TextEditor(text: $editingText)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 150)
                    .background(Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.line, lineWidth: 1)
                    )

                Spacer()
            }
            .padding(18)
            .navigationTitle("编辑文本块")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { editingBubbleId = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEditedText(for: bubbleId)
                    }
                    .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveEditedText(for bubbleId: UUID) {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = appState.chatBubbles.firstIndex(where: { $0.id == bubbleId }) else {
            editingBubbleId = nil
            return
        }

        let parts = splitBubbleTextIntoSegments(trimmed)
        if parts.count <= 1 {
            appState.chatBubbles[index].text = trimmed
            editingBubbleId = nil
            return
        }

        let source = appState.chatBubbles[index]
        appState.chatBubbles.remove(at: index)

        let newBubbles = parts.map { part in
            ChatBubble(
                side: source.side,
                speakerRole: source.speakerRole,
                type: source.type,
                text: part,
                isEditable: source.isEditable
            )
        }

        appState.chatBubbles.insert(contentsOf: newBubbles, at: index)
        editingBubbleId = nil
    }

    private func splitBubbleTextIntoSegments(_ text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .reduce(into: [[String]]()) { groups, line in
                let normalized = line.trimmingCharacters(in: .whitespaces)
                if normalized.isEmpty {
                    if !groups.isEmpty, !groups[groups.count - 1].isEmpty {
                        groups.append([])
                    }
                } else {
                    if groups.isEmpty {
                        groups.append([normalized])
                    } else {
                        groups[groups.count - 1].append(normalized)
                    }
                }
            }
            .compactMap { group -> String? in
                let merged = group.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                return merged.isEmpty ? nil : merged
            }
    }

    @ViewBuilder
    private var insertSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("如果 OCR 漏掉了某条消息，可以在这里手动补充。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.inkMute)

                Picker("消息侧边", selection: $newBubbleSide) {
                    Text("左侧").tag(BubbleSide.left)
                    Text("右侧").tag(BubbleSide.right)
                }
                .pickerStyle(.segmented)

                TextEditor(text: $newBubbleText)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 140)
                    .background(Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.line, lineWidth: 1)
                    )

                Spacer()
            }
            .padding(18)
            .navigationTitle("插入消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showInsertSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        insertNewBubble()
                    }
                    .disabled(newBubbleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func insertNewBubble() {
        let trimmed = newBubbleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let role: SpeakerRole = newBubbleSide == appState.idolSide ? .idol : .user
        let newBubble = ChatBubble(side: newBubbleSide, speakerRole: role, text: trimmed)
        appState.chatBubbles.append(newBubble)

        newBubbleText = ""
        showInsertSheet = false
    }
}

#Preview {
    NavigationStack {
        TextConfirmationView(onAnalyze: {}, onBack: {})
            .environment(AppState())
    }
}
