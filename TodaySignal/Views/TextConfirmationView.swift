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

                        Text("请检查 OCR 识别结果。你可以修改、删除气泡，或标记哪一侧是对方。")
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
                                    }
                                }
                            )
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

                VStack(alignment: .leading, spacing: 14) {
                    Text("哪一侧是 IDOL / 对方？")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color.ink2)
                        .tracking(0.4)

                    // Side selector
                    HStack(spacing: 0) {
                        ForEach([BubbleSide.left, .right], id: \.self) { side in
                            let isSelected = side == appState.idolSide
                            Button(action: {
                                guard !appState.isAnalyzing else { return }
                                withAnimation(.easeInOut(duration: 0.2)) { appState.idolSide = side }
                            }) {
                                HStack(spacing: 6) {
                                    Text(side == .left ? "← 左侧" : "右侧 →")
                                        .font(.system(size: 14, weight: .semibold))
                                    if isSelected {
                                        Text("IDOL")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Color.pink)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(isSelected ? .white : .clear)
                                .foregroundStyle(isSelected ? Color.pinkDeep : Color.inkMute)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: isSelected ? Color(hex: "3C2832").opacity(0.06) : .clear, radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color(hex: "F2EAEC"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

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

                    // Action buttons
                    HStack(spacing: 10) {
                        PrimaryButton(
                            title: appState.isAnalyzing ? "解析中…" : "开始解析",
                            icon: "sparkle",
                            isDisabled: appState.isAnalyzing || appState.chatBubbles.isEmpty,
                            action: {
                                appState.clearAnalysisError()
                                onAnalyze()
                            }
                        )

                        SecondaryButton(title: "重新上传", isFullWidth: false, action: onBack)
                            .disabled(appState.isAnalyzing)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
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

    private func beginEditing(bubble: ChatBubble) {
        editingText = bubble.text
        editingBubbleId = bubble.id
    }

    @ViewBuilder
    private func editSheet(bubbleId: UUID) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("可直接修正 OCR 内容，删除多余符号后再继续解析。")
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

        appState.chatBubbles[index].text = trimmed
        editingBubbleId = nil
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
