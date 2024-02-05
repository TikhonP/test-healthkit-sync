//
//  QuantityObserverQuery.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

actor QuantityObserverQuery: ObserverQuery {
    
    var annalist: Annalist = OnlyLogAnnalist(withTag: "somelog")
    
    let healthStore: HKHealthStore
    let getIsProtectedDataAvailable: () async -> Bool
    
    var query: HKObserverQuery?
    var isFetchingData = false
    
    private let medsengerQuantityType: MedsengerQuantityType
    
    init(medsengerQuantityType: MedsengerQuantityType, healthStore: HKHealthStore, getIsProtectedDataAvailable: @escaping () async -> Bool) {
        self.medsengerQuantityType = medsengerQuantityType
        self.healthStore = healthStore
        self.getIsProtectedDataAvailable = getIsProtectedDataAvailable
    }
    
    var medsengerType: MedsengerHealthType {
        medsengerQuantityType
    }
    
    var sampleIdentifier: String {
        medsengerQuantityType.hkQuantityType.identifier
    }
    
    func fetchSamples() async {
        guard lock() else { return }
        defer { unlock() }
        
        guard let startDate = UserDefaults.getLastSyncDate(for: sampleIdentifier) else {
            annalist.log(.error, "fetchSamples: failed to get start date")
            return
        }
        
        do {
            let now = Date()
            try await QuantityHealthQuery(medsengerQuantityType: medsengerQuantityType, withStart: startDate)
                .getSamples(healthStore: healthStore)
                .submit()
            UserDefaults.setLastSyncDate(now, for: sampleIdentifier)
            annalist.log(.info, "HealthKitSync fetched \(sampleIdentifier)")
        } catch {
            error.healthHandle("fetchSamples \(sampleIdentifier)", using: annalist)
        }
    }
}
