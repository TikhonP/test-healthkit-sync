//
//  MedsengerCategoryType.swift
//
//
//  Created by Tikhon Petrishchev on 15.01.2024.
//

import HealthKit

public typealias DataEncoder = @Sendable (Int) -> String?

/// Object for configuring HealthKit category types
@available(macOS 13.0, *)
public struct MedsengerCategoryType: Sendable, MedsengerHealthType {
    
    let hkCategoryType: HKCategoryType
    let medsengerKey: String
    let dataEncoder: DataEncoder
    public let updateFrequency: HKUpdateFrequency
    
    public init?(_ identifier: HKCategoryTypeIdentifier, medsengerKey: String,
                 updateFrequency: HKUpdateFrequency = .immediate, dataEncoder: @escaping DataEncoder) {
        guard let categoryType = HKObjectType.categoryType(forIdentifier: identifier) else {
            return nil
        }
        self.hkCategoryType = categoryType
        self.medsengerKey = medsengerKey
        self.dataEncoder = dataEncoder
        self.updateFrequency = updateFrequency
    }
    
    public var sampleType: HKSampleType {
        hkCategoryType
    }
    
    public func getObserverQuery(healthStore: HKHealthStore,
                                 getIsProtectedDataAvailable: @escaping () async -> Bool) -> ObserverQuery {
        CategoryObserverQuery(
            medsengerCategoryType: self,
            healthStore: healthStore,
            getIsProtectedDataAvailable: getIsProtectedDataAvailable
        )
    }
}
