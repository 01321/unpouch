//
//  Models.swift
//  unpouch
//

import Foundation

struct PouchEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let strengthMg: Int
    
    init(id: UUID = UUID(), timestamp: Date = Date(), strengthMg: Int) {
        self.id = id
        self.timestamp = timestamp
        self.strengthMg = strengthMg
    }
}

struct AppSettings: Codable {
    var dailyLimitMg: Int
    var resetHour: Int
    var resetMinute: Int
    var selectedStrengthMg: Int
    
    static let `default` = AppSettings(
        dailyLimitMg: 40,
        resetHour: 6,
        resetMinute: 0,
        selectedStrengthMg: 10
    )
}
