//
//  Date+.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import Foundation

extension Date {
    
    /// Get the date two weeks ago.
    static var twoWeeksAgo: Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        guard let currentDay = components.day else {
            return nil
        }
        components.day = currentDay - 14
        guard let twoWeeksAgo = calendar.date(from: components) else {
            return nil
        }
        return twoWeeksAgo
    }
    
    static func getLastHealthSyncDate() async -> Date? {
//        guard let twoWeeksAgo = Date.twoWeeksAgo else {
//            return nil
//        }
//        
//        guard let lastHealthSyncDateTime = try? await User.get(\.lastHealthSyncDateTime) else {
//            return twoWeeksAgo
//        }
//        
//        // Converting from UTC to current timezone
//        let targetTz = TimeZone.current
//        guard let initTz = TimeZone(abbreviation: "UTC") else {
//            return nil
//        }
//        var calendar = Calendar.current
//        calendar.timeZone = initTz
//        var components = calendar.dateComponents(in: targetTz, from: lastHealthSyncDateTime)
//        components.timeZone = initTz
//        
//        guard let medsengerLastSyncDateLocalized = calendar.date(from: components) else {
//            return twoWeeksAgo
//        }
//        
//        if medsengerLastSyncDateLocalized > twoWeeksAgo {
//            return medsengerLastSyncDateLocalized
//        } else {
//            return twoWeeksAgo
//        }
        defaultDate
    }
    
}
