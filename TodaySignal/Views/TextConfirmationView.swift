import SwiftUI

struct TextConfirmationView: View {
    @Environment(AppState.self) private var appState
    var onAnalyze: () -> Void
    var onBack: () -> Void

    @State private var editingBubbleId: UUID?
    @State private var editingText = ""

    @State private var showInsertSheet = false
    @State private var newBubbleText = ""
    @State private var newBubbleSide: BubbleSide = .left

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Color.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Info banner
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.pinkDeep)
                            .padding(.top, 1)

                        Text("请确认 OCR 文字。点击 IDOL 气泡可勾选你想回复的消息。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: "7A4A55"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.bgSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 16)

                    // Chat bubbles
                    VStack(spacing: 10) {
                        ForEach(appState.chatBubbles) { bubble in
                            bubbleRow(bubble: bubble)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Fallback hint
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
                    .padding(.top, 18)

                    Spacer().frame(height: 240)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
            }

            // Bottom panel
            VStack(spacing: 0) {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    // Side selector row
                    HStack {
                        Text("IDOL / 对方在")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(Color.ink2)
                            .tracking(0.4)

                        Spacer()

                        sideSelectorPill
                    }

                    if appState.chatBubbles.count > 12 {
                        Text("这张截图内容有点多，解析可能会变慢。建议裁剪成 10 条以内或分批上传。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: "B36A3D"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: "FFF4EA"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if appState.hasMySideBubbles() {
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.bgMint)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .toggleStyle(.switch)
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

                    if appState.selectedReplyBubbleIDs.isEmpty {
                        Text("点击 IDOL 气泡可勾选 · 生成回复建议前需先选择")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.inkMute)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("✓ 已选 \(appState.selectedReplyBubbleIDs.count) 条 IDOL 消息")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.pinkDeep)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        PrimaryButton(
                            title: appState.isAnalyzing ? "解析中…" : "学习解析",
                            icon: "sparkle",
                            isDisabled: appState.isAnalyzing || appState.chatBubbles.isEmpty,
                            action: {
                                appState.clearAnalysisError()
                                onAnalyze()
                            }
                        )
                        .frame(maxWidth: .infinity)

                        Button {
                            guard !appState.isAnalyzing else { return }
                            if appState.prepareReplyContextFromSelection() {
                                appState.navigationPath.append(AnalysisRoute.replySuggestion)
                            } else {
                                appState.analysisErrorMessage = "请先选择想回复的消息。"
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("生成回复建议")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(appState.selectedReplyBubbleIDs.isEmpty ? Color(hex: "E5DFEE") : Color(hex: "7860B3"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: appState.selectedReplyBubbleIDs.isEmpty ? .clear : Color(hex: "7860B3").opacity(0.45), radius: 8, y: 4)
                        }
                        .disabled(appState.isAnalyzing)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 30)
                .background(
                    Color.bgPage.opacity(0.97)
                        .background(.ultraThinMaterial)
                )
            }
        }
        .navigationTitle("确认聊天内容")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("编辑")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pink)
            }
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
    }

    @ViewBuilder
    private func bubbleRow(bubble: ChatBubble) -> some View {
        let isSelectable = bubble.type == .text && bubble.side == appState.idolSide
        let isSelected = appState.selectedReplyBubbleIDs.contains(bubble.id)

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
                showEditControls: !appState.isAnalyzing,
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
