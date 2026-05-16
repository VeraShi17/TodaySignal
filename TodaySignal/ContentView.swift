//
//  ContentView.swift
//  TodaySignal
//
//  Created by Jiarui Shi on 2026/5/16.
//

import SwiftUI

struct ContentView: View {
    @State private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
