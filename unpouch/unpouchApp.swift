//
//  unpouchApp.swift
//  unpouch
//

import SwiftUI

@main
struct unpouchApp: App {
    @StateObject private var dataStore = DataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
