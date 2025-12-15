//
//  StatsService.swift
//  Pomos
//
//  Created by Assistant on 2025-12-15.
//

import Foundation

struct DailyStats: Codable {
    var date: Date
    var finished: Int
    
    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case finished = "Finished"
    }
}

actor StatsService {
    static let shared = StatsService()
    
    private let fileURL: URL
    
    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pomosDir = appSupport.appendingPathComponent("Pomos")
        
        if !fileManager.fileExists(atPath: pomosDir.path) {
            try? fileManager.createDirectory(at: pomosDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        fileURL = pomosDir.appendingPathComponent("pomos.plist")
    }
    
    func readStats() -> DailyStats {
        guard let data = try? Data(contentsOf: fileURL),
              let stats = try? PropertyListDecoder().decode(DailyStats.self, from: data) else {
            return DailyStats(date: Date(), finished: 0)
        }
        
        // Check if date is today, otherwise reset
        if !Calendar.current.isDateInToday(stats.date) {
            return DailyStats(date: Date(), finished: 0)
        }
        
        return stats
    }
    
    func saveStats(_ stats: DailyStats) {
        let statsToSave = DailyStats(date: Date(), finished: stats.finished) // Always update date to now when saving? Or keep original date? Original concept: "Date" seems to be "Date of this record".
        // Actually, Controller.m did:
        // if date is not today, reset.
        // So when saving, we basically save (Today, count).
        
        if let data = try? PropertyListEncoder().encode(statsToSave) {
            try? data.write(to: fileURL)
        }
    }
}

