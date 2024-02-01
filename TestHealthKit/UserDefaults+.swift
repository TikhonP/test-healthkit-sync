//
//  UserDefaults+.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit
import Foundation

let defaultDate = Date(timeIntervalSince1970: 1706572800)

extension UserDefaults {
    private static func getLastSyncDateUserDefaultsKey(for sampleIdentifier: String) -> String {
        "healthkit_\(sampleIdentifier)_LastSyncDate"
    }
    
    static func getLastHKSyncDate(for sampleIdentifier: String, fromDate: Date = defaultDate) -> Date? {
        
        // Get the date two weeks ago.
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        guard let currentDay = components.day else {
            return nil
        }
        components.day = currentDay - 14
        guard let twoWeeksAgo = calendar.date(from: components) else {
            return nil
        }
        
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        
        guard let lastSyncDateForSample = UserDefaults.standard.object(
            forKey: lastSyncDateUserDefaultsKey) as? Date else {
            
            let lastHealthSyncDateTime = fromDate
            
            // Converting from UTC to current timezone
            let targetTz = TimeZone.current
            guard let initTz = TimeZone(abbreviation: "UTC") else {
                return nil
            }
            var calendar = Calendar.current
            calendar.timeZone = initTz
            var components = calendar.dateComponents(in: targetTz, from: lastHealthSyncDateTime)
            components.timeZone = initTz
            
            guard let medsengerLastSyncDateLocalized = calendar.date(from: components) else {
                return twoWeeksAgo
            }
            
            if medsengerLastSyncDateLocalized > twoWeeksAgo {
                setLastHKSyncDate(medsengerLastSyncDateLocalized, for: sampleIdentifier)
                return medsengerLastSyncDateLocalized
            } else {
                return twoWeeksAgo
            }
        }
        if lastSyncDateForSample > twoWeeksAgo {
            return lastSyncDateForSample
        } else {
            return twoWeeksAgo
        }
    }
    
    static func setLastHKSyncDate(_ date: Date, for sampleIdentifier: String) {
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        UserDefaults.standard.set(date, forKey: lastSyncDateUserDefaultsKey)
    }
    
    static func getQueryAnchor(for sampleIdentifier: String) -> HKQueryAnchor? {
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        guard let data = UserDefaults.standard.object(forKey: lastSyncDateUserDefaultsKey) as? Data,
              let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data) else {
            return nil
        }
        return anchor
    }
    
    static func setQueryAnchor(for sampleIdentifier: String, anchor: HKQueryAnchor) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        UserDefaults.standard.set(data, forKey: lastSyncDateUserDefaultsKey)
    }
}
