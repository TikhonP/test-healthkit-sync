//
//  CategoryObserverQuery.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

actor CategoryObserverQuery: ObserverQuery {
    
    var annalist: Annalist = OnlyLogAnnalist(withTag: "somelog")
    
    let healthStore: HKHealthStore
    let getIsProtectedDataAvailable: () async -> Bool
    
    var query: HKObserverQuery?
    var isFetchingData = false
    
    private let medsengerCategoryType: MedsengerCategoryType
    
    init(medsengerCategoryType: MedsengerCategoryType, healthStore: HKHealthStore, getIsProtectedDataAvailable: @escaping () async -> Bool) {
        self.medsengerCategoryType = medsengerCategoryType
        self.healthStore = healthStore
        self.getIsProtectedDataAvailable = getIsProtectedDataAvailable
    }
    
    var medsengerType: MedsengerHealthType {
        medsengerCategoryType
    }
    
    var sampleIdentifier: String {
        medsengerCategoryType.hkCategoryType.identifier
    }
    
    func fetchSamples() async {
        guard lock() else { return }
        defer { unlock() }
        
        let anchorData: AnchorData
        if let anchor = UserDefaults.getQueryAnchor(for: sampleIdentifier) {
            anchorData = .anchor(anchor)
        } else {
            guard let startDate = await Date.getMedsengerLastSyncDate() else {
                return
            }
            anchorData = .startDate(startDate)
        }
        
        do {
            var newAnchor: HKQueryAnchor?
            try await CategoryHealthQuery(medsengerCategoryType: medsengerCategoryType, anchor: anchorData) { newAnchor = $0 }
                .getSamples(healthStore: healthStore)
                .submit()
            if let newAnchor {
                try UserDefaults.setQueryAnchor(for: sampleIdentifier, anchor: newAnchor)
            }
            annalist.log(.info, "HealthKitSync fetched \(sampleIdentifier)")
        } catch {
            error.healthHandle("fetchSamples \(sampleIdentifier)", using: annalist)
        }
    }
}
