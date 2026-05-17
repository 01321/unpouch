//
//  DataStore.swift
//  NicotineTracker
//
//  Created by Assistant on 2024.
//

import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var entries: [PouchEntry] = []
    @Published var settings: AppSettings = .default
    
    private let entriesKey = "pouchEntries"
    private let settingsKey = "appSettings"
    
    init() {
        loadEntries()
        loadSettings()
        resetIfNeeded()
    }
    
    func addEntry(strengthMg: Int) {
        let entry = PouchEntry(strengthMg: strengthMg)
        entries.append(entry)
        saveEntries()
    }
    
    func removeLastEntry() {
        guard !entries.isEmpty else { return }
        entries.removeLast()
        saveEntries()
    }
    
    func updateSettings(resetHour: Int, dailyLimitMg: Int) {
        settings.resetHour = resetHour
        settings.dailyLimitMg = dailyLimitMg
        saveSettings()
    }
    
    var todayTotalCount: Int {
        let startOfDay = getStartOfToday()
        return entries.filter { $0.timestamp >= startOfDay }.count
    }
    
    var todayTotalMg: Int {
        let startOfDay = getStartOfToday()
        return entries
            .filter { $0.timestamp >= startOfDay }
            .reduce(0) { $0 + $1.strengthMg }
    }
    
    var isOverLimit: Bool {
        todayTotalMg > settings.dailyLimitMg
    }
    
    // MARK: - Private Helpers
    
    private func getStartOfToday() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = settings.resetHour
        components.minute = 0
        components.second = 0
        
        guard var startOfDay = calendar.date(from: components) else {
            return calendar.startOfDay(for: Date())
        }
        
        // If current time is before reset hour, the "today" started yesterday at resetHour
        let now = Date()
        if now < startOfDay {
            startOfDay = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        }
        
        return startOfDay
    }
    
    private func resetIfNeeded() {
        // Entries are filtered dynamically based on reset hour, 
        // so no explicit reset needed unless we want to purge old data periodically
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([PouchEntry].self, from: data) {
            entries = decoded
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }
}
