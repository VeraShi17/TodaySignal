//
//  ContentView.swift
//  TodaySignal
//
//  Created by Jiarui Shi on 2026/5/16.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
                .environment(appState)
        } else {
            OnboardingView(hasCompletedOnboarding: $appState.hasCompletedOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
