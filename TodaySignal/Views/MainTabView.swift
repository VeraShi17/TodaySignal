import SwiftUI
import PhotosUI
import UIKit

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isProcessingOCR = false
    @State private var ocrErrorMessage: String?
    @State private var showOCRErrorAlert = false
    @State private var showPasteTextSheet = false
    @State private var pastedTextInput = ""
    @State private var pasteTextErrorMessage: String?

    private let ocrService = OCRService()

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            NavigationStack(path: $appState.navigationPath) {
                HomeView(
                    onUploadScreenshot: {
                        isPhotoPickerPresented = true
                    },
                    onPasteText: {
                        ocrErrorMessage = nil
                        pasteTextErrorMessage = nil
                        pastedTextInput = ""
                        showPasteTextSheet = true
                    },
                    onQuickReply: {
                        appState.prepareReplyContextFromHomeEntry()
                        appState.navigationPath.append(AnalysisRoute.replySuggestion)
                    }
                )
                .navigationBarHidden(true)
                .photosPicker(
                    isPresented: $isPhotoPickerPresented,
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                )
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }

                    Task {
                        await processPickedImage(item: newItem)
                    }
                }
                .sheet(isPresented: $showPasteTextSheet) {
                    pasteTextSheet
                        .presentationDetents([.large])
                }
                .alert("识别失败", isPresented: $showOCRErrorAlert) {
                    Button("我知道了", role: .cancel) {
                        ocrErrorMessage = nil
                    }
                } message: {
                    Text(ocrErrorMessage ?? "未识别到文字内容，请重新上传更清晰的截图。")
                }
                .overlay {
                    if isProcessingOCR {
                        ZStack {
                            Color.black.opacity(0.2).ignoresSafeArea()

                            VStack(spacing: 12) {
                                ProgressView()
                                Text("正在识别截图文字…")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.ink)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .navigationDestination(for: AnalysisRoute.self) { route in
                    switch route {
                    case .textConfirmation:
                        TextConfirmationView(
                            onAnalyze: {
                                appState.clearAnalysisError()
                                appState.navigationPath.append(AnalysisRoute.analysisLoading)
                            },
                            onBack: {
                                appState.navigationPath.removeLast()
                            }
                        )
                    case .analysisLoading:
                        AnalysisLoadingView(
                            onFinished: { succeeded in
                                if succeeded {
                                    appState.navigationPath.removeLast()
                                    appState.navigationPath.append(AnalysisRoute.analysisResult)
                                } else {
                                    appState.navigationPath.removeLast()
                                }
                            }
                        )
                    case .analysisResult:
                        AnalysisResultView(
                            onDone: {
                                appState.navigateToLibrary()
                            }
                        )
                    case .replySuggestion:
                        ReplySuggestionView()
                    }
                }
            }
            .tabItem {
                Label("解析", systemImage: "sparkle")
            }
            .tag(AppState.MainTab.analysis)

            CardLibraryView()
                .tabItem {
                    Label("卡片库", systemImage: "book.fill")
                }
                .tag(AppState.MainTab.library)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(AppState.MainTab.settings)
        }
        .tint(Color.pink)
    }

    @ViewBuilder
    private var pasteTextSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("可直接粘贴韩语聊天文本，按行自动拆分。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.inkMute)

                Text("可选格式：`L:` / `R:` 前缀指定左右侧，例如 `L:오늘 뭐해?`。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkFaint)

                TextEditor(text: $pastedTextInput)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 220)
                    .background(Color.bgElev)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.line, lineWidth: 1)
                    )

                if let pasteTextErrorMessage {
                    Text(pasteTextErrorMessage)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "B3474A"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(hex: "FCEDEE"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()
            }
            .padding(18)
            .navigationTitle("粘贴韩语文本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showPasteTextSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("继续") {
                        continueWithPastedText()
                    }
                }
            }
        }
    }

    private func continueWithPastedText() {
        let bubbles = bubblesFromPastedText(pastedTextInput)
        guard !bubbles.isEmpty else {
            pasteTextErrorMessage = "没有检测到可用文本，请至少输入一行韩语内容。"
            return
        }

        pasteTextErrorMessage = nil
        ocrErrorMessage = nil
        appState.chatBubbles = bubbles
        appState.idolSide = .left
        showPasteTextSheet = false
        appState.navigationPath.append(AnalysisRoute.textConfirmation)
    }

    private func bubblesFromPastedText(_ rawText: String) -> [ChatBubble] {
        let lines = rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.compactMap { line in
            if let content = line.removingPrefix("L:") ?? line.removingPrefix("l:") ?? line.removingPrefix("左:") {
                return ChatBubble(side: .left, speakerRole: .idol, text: content.trimmingCharacters(in: .whitespaces))
            }

            if let content = line.removingPrefix("R:") ?? line.removingPrefix("r:") ?? line.removingPrefix("右:") {
                return ChatBubble(side: .right, speakerRole: .user, text: content.trimmingCharacters(in: .whitespaces))
            }

            return ChatBubble(side: .left, speakerRole: .idol, text: line)
        }
    }

    @MainActor
    private func processPickedImage(item: PhotosPickerItem) async {
        guard !isProcessingOCR else { return }

        isProcessingOCR = true
        defer {
            isProcessingOCR = false
            selectedPhotoItem = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }

            let bubbles = try await ocrService.recognizeChatBubbles(from: image)

            ocrErrorMessage = nil
            appState.chatBubbles = bubbles
            appState.idolSide = .left
            appState.navigationPath.append(AnalysisRoute.textConfirmation)
        } catch {
            if let ocrError = error as? OCRService.OCRServiceError {
                ocrErrorMessage = ocrError.errorDescription
            } else {
                ocrErrorMessage = "OCR 识别失败，请重新上传更清晰的截图。"
            }
            showOCRErrorAlert = true
        }
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
