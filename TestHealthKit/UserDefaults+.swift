//
//  UserDefaults+getLastHKSyncDate.swift
//
//
//  Created by Tikhon Petrishchev on 03.12.2023.
//

import HealthKit

let defaultDate = Date(timeIntervalSince1970: 1707515796)

@available(macOS 13.0, *)
extension UserDefaults {
    
    private static func getLastSyncDateKey(for sampleIdentifier: String) -> String {
        "HealthKit_\(sampleIdentifier)_LastSyncDate"
    }
    
    /// Get last sync date in local timezone from defaults for specific sample type.
    static func getLastSyncDate(for sampleIdentifier: String) -> Date? {
        let key = getLastSyncDateKey(for: sampleIdentifier)
        let date = UserDefaults.standard.object(forKey: key) as? Date
        return date?.toLocalTime()
    }
    
    /// Save last sync date into defaults store for specific identifier.
    /// - Parameters:
    ///   - date: `Date` value in local timezone.
    ///   - sampleIdentifier: Sample identifier key.
    static func setLastSyncDate(_ date: Date, for sampleIdentifier: String) {
        let lastSyncDateUserDefaultsKey = getLastSyncDateKey(for: sampleIdentifier)
        UserDefaults.standard.set(date.toGlobalTime(), forKey: lastSyncDateUserDefaultsKey)
    }
    
    static func getQueryAnchor(for sampleIdentifier: String) -> HKQueryAnchor? {
        let lastSyncDateUserDefaultsKey = getLastSyncDateKey(for: sampleIdentifier)
        guard let data = UserDefaults.standard.object(forKey: lastSyncDateUserDefaultsKey) as? Data,
              let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data) else {
            return nil
        }
        return anchor
    }
    
    static func setQueryAnchor(for sampleIdentifier: String, anchor: HKQueryAnchor) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        let lastSyncDateUserDefaultsKey = getLastSyncDateKey(for: sampleIdentifier)
        UserDefaults.standard.set(data, forKey: lastSyncDateUserDefaultsKey)
    }
}
