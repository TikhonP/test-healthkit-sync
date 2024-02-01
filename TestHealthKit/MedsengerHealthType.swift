//
//  MedsengerHealthType.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import HealthKit
import Foundation

protocol MedsengerHealthType {
    var sampleType: HKSampleType { get }
    func getObserverQuery(healthStore: HKHealthStore, getIsProtectedDataAvailable: @escaping () async -> Bool) -> ObserverQuery
}

extension Array<MedsengerHealthType> {
    func asSampleTypesSet() -> Set<HKSampleType> {
        Set(self.map(\.sampleType))
    }
}
