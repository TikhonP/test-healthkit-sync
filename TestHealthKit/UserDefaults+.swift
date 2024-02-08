//
//  UserDefaults+getLastHKSyncDate.swift
//
//
//  Created by Tikhon Petrishchev on 03.12.2023.
//

import HealthKit

let defaultDate = Date(timeIntervalSince1970: 1707401266)

@available(macOS 13.0, *)
extension UserDefaults {
    private static func getLastSyncDateUserDefaultsKey(for sampleIdentifier: String) -> String {
        "HealthKit_\(sampleIdentifier)_LastSyncDate"
    }
    
    static func getLastSyncDate(for sampleIdentifier: String) async -> Date? {
        
        let lastSyncDateUserDefaultsKey = getLastSyncDateUserDefaultsKey(for: sampleIdentifier)
        let lastSyncDateForSample = UserDefaults.standard.object(forKey: lastSyncDateUserDefaultsKey) as? Date
        
        guard let lastSyncDateForSample else {
            return await Date.getMedsengerLastSyncDate()
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
