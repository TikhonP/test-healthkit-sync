//
//  MedsengerHealthType.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

/// Abstract Medsenger record type.
@available(macOS 13.0, *)
public protocol MedsengerHealthType {
    
    var sampleType: HKSampleType { get }
    var updateFrequency: HKUpdateFrequency { get }
    
    
    /// Get observer query for specific record type.
    /// - Parameters:
    ///   - healthStore: Health store object initiated in Health Sync service.
    ///   - getIsProtectedDataAvailable: Is phone under encryption callback.
    /// - Returns: Observer query object for specific record type.
    func getObserverQuery(healthStore: HKHealthStore,
                          getIsProtectedDataAvailable: @escaping () async -> Bool) -> ObserverQuery
    
}

@available(macOS 13.0, *)
extension Array<MedsengerHealthType> {
    func asSampleTypesSet() -> Set<HKSampleType> {
        Set(self.map(\.sampleType))
    }
}
