//
//  MedsengerQuantityType.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit

/// Object for configuring HealthKit quantity types
@available(macOS 13.0, *)
public struct MedsengerQuantityType: Sendable, MedsengerHealthType {
    
    public typealias DataEncoder = @Sendable (Double) -> String
    
    let hkQuantityType: HKQuantityType
    let unitString: String
    let medsengerKey: String
    let customDataEncoder: DataEncoder?
    let byIntervals: DateComponents
    let updateFrequency: HKUpdateFrequency
    
    /// Create object for retrieving types for Medsenger
    /// - Parameters:
    ///   - identifier: HK identifier.
    ///   - hkUnit: HK unit to send to medsenger.
    ///   - medsengerKey: Medsenger server type's string key.
    ///   - aggregationStrategy: Strategy for aggregation lots of hk samples.
    ///   - byIntervals: The date components that define the time interval for each statistics object in the collection.
    ///   - updateFrequency: The maximum frequency of the updates. The system wakes your app from the background at most once per time period specified.
    ///   - customDataEncoder: Callback for encoding HealthKit data to string optional, by default `String()` is used.
    public init?(
        _ identifier: HKQuantityTypeIdentifier,
        hkUnit: HKUnit,
        medsengerKey: String,
        byIntervals: DateComponents = DateComponents(minute: 5),
        updateFrequency: HKUpdateFrequency = .immediate,
        customDataEncoder: DataEncoder? = nil
    ) {
        guard let hkQuantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        self.hkQuantityType = hkQuantityType
        self.unitString = hkUnit.unitString
        self.medsengerKey = medsengerKey
        self.customDataEncoder = customDataEncoder
        self.byIntervals = byIntervals
        self.updateFrequency = updateFrequency
    }
    
    var hkUnit: HKUnit {
        HKUnit(from: unitString)
    }
    
    var sampleType: HKSampleType {
        hkQuantityType
    }
    
    func getObserverQuery(healthStore: HKHealthStore, getIsProtectedDataAvailable: @escaping () async -> Bool) -> ObserverQuery {
        QuantityObserverQuery(
            medsengerQuantityType: self,
            healthStore: healthStore,
            getIsProtectedDataAvailable: getIsProtectedDataAvailable
        )
    }
}