//
//  Models.swift
//  NicotineTracker
//
//  Created by Assistant on 2024.
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
    var resetHour: Int // 0-23
    var dailyLimitMg: Int
    
    static let `default` = AppSettings(resetHour: 6, dailyLimitMg: 100)
}
