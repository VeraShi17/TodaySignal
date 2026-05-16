import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            NavigationStack(path: $appState.navigationPath) {
                HomeView(
                    onUploadScreenshot: {
                        appState.navigationPath.append(AnalysisRoute.textConfirmation)
                    },
                    onPasteText: {
                        appState.navigationPath.append(AnalysisRoute.textConfirmation)
                    }
                )
                .navigationBarHidden(true)
                .navigationDestination(for: AnalysisRoute.self) { route in
                    switch route {
                    case .textConfirmation:
                        TextConfirmationView(
                            onAnalyze: {
                                appState.startAnalysis()
                            },
                            onBack: {
                                appState.navigationPath.removeLast()
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
}

#Preview {
    MainTabView()
        .environment(AppState())
}
