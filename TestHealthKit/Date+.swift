//
//  Date+.swift
//
//
//  Created by Tikhon Petrishchev on 15.01.2024.
//

import Foundation

extension Date {
    
    static var twoWeeksAgo: Date? {
        Calendar.current.date(byAdding: .day, value: -14, to: Date())
    }
    
    static func getMedsengerLastSyncDate() async -> Date? {
        guard let twoWeeksAgo = Date.twoWeeksAgo else {
            return nil
        }
        
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
