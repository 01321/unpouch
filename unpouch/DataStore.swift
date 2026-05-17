//
//  DataStore.swift
//  unpouch
//

import Foundation
import SwiftUI

class DataStore: ObservableObject {
    @Published var entries: [PouchEntry] = []
    @Published var settings: AppSettings
    
    private let entriesKey = "pouchEntries"
    private let settingsKey = "appSettings"
    
    init() {
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
        
        // Load entries
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([PouchEntry].self, from: data) {
            self.entries = decoded.filter { isToday($0.timestamp) }
        } else {
            self.entries = []
        }
        
        // Check if reset is needed
        checkAndResetIfNeeded()
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
    
    func updateSettings(dailyLimitMg: Int, resetHour: Int, resetMinute: Int) {
        settings.dailyLimitMg = dailyLimitMg
        settings.resetHour = resetHour
        settings.resetMinute = resetMinute
        saveSettings()
    }
    
    func updateSelectedStrength(_ strength: Int) {
        settings.selectedStrengthMg = strength
        saveSettings()
    }
    
    var totalPouchesToday: Int {
        return entries.count
    }
    
    var totalMgToday: Int {
        return entries.reduce(0) { $0 + $1.strengthMg }
    }
    
    var isOverLimit: Bool {
        return totalMgToday > settings.dailyLimitMg
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Get the reset time for today
        var resetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        resetComponents.hour = settings.resetHour
        resetComponents.minute = settings.resetMinute
        guard let resetTimeToday = calendar.date(from: resetComponents) else { return false }
        
        // Get the reset time for yesterday
        let resetTimeYesterday = calendar.date(byAdding: .day, value: -1, to: resetTimeToday)!
        
        // Check if date is after reset time (either today or yesterday's reset if before today's reset)
        if now >= resetTimeToday {
            return date >= resetTimeToday
        } else {
            return date >= resetTimeYesterday
        }
    }
    
    private func checkAndResetIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        var resetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        resetComponents.hour = settings.resetHour
        resetComponents.minute = settings.resetMinute
        guard let resetTimeToday = calendar.date(from: resetComponents) else { return }
        
        let resetTimeYesterday = calendar.date(byAdding: .day, value: -1, to: resetTimeToday)!
        
        // If current time is before reset time, we're in the previous day's cycle
        let effectiveResetTime = now >= resetTimeToday ? resetTimeToday : resetTimeYesterday
        
        // Filter out old entries
        let validEntries = entries.filter { $0.timestamp >= effectiveResetTime }
        
        if validEntries.count != entries.count {
            entries = validEntries
            saveEntries()
        }
    }
}
