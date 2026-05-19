import SwiftUI

@main
struct unpouchApp: App {
    @StateObject private var dataStore = DataStore()
    
    init() {
        // Uncomment the line below to generate test data for charts
        // Call it once, then comment it out again to avoid regenerating on every launch
        // DataStore().generateTestData()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
