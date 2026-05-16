import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .analysis
    @State private var navigationPath = NavigationPath()

    enum Tab: String {
        case analysis = "解析"
        case library = "卡片库"
        case settings = "设置"
    }

    enum AnalysisRoute: Hashable {
        case textConfirmation
        case analysisResult
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationPath) {
                HomeView(
                    onUploadScreenshot: {
                        navigationPath.append(AnalysisRoute.textConfirmation)
                    },
                    onPasteText: {
                        navigationPath.append(AnalysisRoute.textConfirmation)
                    }
                )
                .navigationBarHidden(true)
                .navigationDestination(for: AnalysisRoute.self) { route in
                    switch route {
                    case .textConfirmation:
                        TextConfirmationView(
                            onAnalyze: {
                                navigationPath.append(AnalysisRoute.analysisResult)
                            },
                            onBack: {
                                navigationPath.removeLast()
                            }
                        )
                    case .analysisResult:
                        AnalysisResultView(
                            onDone: {
                                navigationPath = NavigationPath()
                                selectedTab = .library
                            }
                        )
                    }
                }
            }
            .tabItem {
                Label("解析", systemImage: "sparkle")
            }
            .tag(Tab.analysis)

            CardLibraryView()
                .tabItem {
                    Label("卡片库", systemImage: "book.fill")
                }
                .tag(Tab.library)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color.pink)
    }
}

#Preview {
    MainTabView()
}
