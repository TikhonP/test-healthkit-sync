//
//  Date+.swift
//
//
//  Created by Tikhon Petrishchev on 15.01.2024.
//

import Foundation

extension Date {
    
    /// Get health store last sync `Date` value from medsenger server in local timezone.
    /// But no older than two weeks ago.
    static func getMedsengerLastSyncDate() async -> Date {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        
//        guard let lastHealthSyncDateTime = defaultDate else {
//            return twoWeeksAgo
//        }
        
        if defaultDate > twoWeeksAgo {
            return defaultDate
        } else {
            return twoWeeksAgo
        }
    }
    
}
