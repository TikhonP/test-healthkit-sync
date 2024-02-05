//
//  UserDefaults+.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit

let defaultDate = Date(timeIntervalSince1970: 1706572800)

extension Date {
    
    /// Get the date two weeks ago.
    static var twoWeeksAgo: Date? {
        Calendar.current.date(byAdding: .day, value: -14, to: Date())
    }
    
    static func getMedsengerLastSyncDate() async -> Date? {
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

extension UserDefaults {
    private static func getLastSyncDateUserDefaultsKey(for sampleIdentifier: String) -> String {
        "HealthKit_\(sampleIdentifier)_LastSyncDate"
    }
    
    static func getLastSyncDate(for sampleIdentifier: String, medsengerLastSyncDate: Date? = defaultDate) -> Date? {
        
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        let lastSyncDateForSample = UserDefaults.standard.object(forKey: lastSyncDateUserDefaultsKey) as? Date
        
        guard let lastSyncDateForSample else {
            return medsengerLastSyncDate
        }
        guard let twoWeeksAgo = Date.twoWeeksAgo else {
            return nil
        }
        if lastSyncDateForSample > twoWeeksAgo {
            return lastSyncDateForSample
        } else {
            return twoWeeksAgo
        }
    }
    
    static func setLastSyncDate(_ date: Date, for sampleIdentifier: String) {
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
