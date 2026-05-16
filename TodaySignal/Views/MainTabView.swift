import SwiftUI
import PhotosUI
import UIKit

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isProcessingOCR = false
    @State private var ocrErrorMessage: String?

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
                        appState.chatBubbles = MockData.chatBubbles
                        appState.navigationPath.append(AnalysisRoute.textConfirmation)
                    },
                    ocrErrorMessage: ocrErrorMessage
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
                ocrErrorMessage = "OCR 识别失败，请重新上传截图或改为粘贴文本。"
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
