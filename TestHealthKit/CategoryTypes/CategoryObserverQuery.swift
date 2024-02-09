//
//  CategoryObserverQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

/// Observe changes and fetch category type samples using simple async API.
@available(macOS 13.0, *)
actor CategoryObserverQuery: ObserverQuery {
    
    let healthStore: HKHealthStore
    let getIsProtectedDataAvailable: () async -> Bool
    
    var query: HKObserverQuery?
    var isFetchingData = false
    
    var annalist: Annalist = OnlyLogAnnalist(withTag: "CategoryObserverQuery")
    
    private let medsengerCategoryType: MedsengerCategoryType
    
    init(medsengerCategoryType: MedsengerCategoryType,
         healthStore: HKHealthStore,
         getIsProtectedDataAvailable: @escaping () async -> Bool) {
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
        
        // Lock fetching for excluding situation where there are two fetch request
        // in the same time but last sync date anchor was not updated and samples are duplicated.
        guard lock() else { return }
        defer { unlock() }
        
        let anchorData: CategoryHealthQuery.AnchorData
        if let anchor = UserDefaults.getQueryAnchor(for: sampleIdentifier) {
            anchorData = .anchor(anchor)
        } else {
            anchorData = .startDate(
                await Date.getMedsengerLastSyncDate()
            )
        }
        
        do {
            var newAnchor: HKQueryAnchor?
            try await CategoryHealthQuery(medsengerCategoryType: medsengerCategoryType,
                                          anchor: anchorData) { newAnchor = $0 }
                .getSamples(healthStore: healthStore)
                .submit()
            
            // Saving anchor only after submit to be sure there was no errors
            if let newAnchor {
                try UserDefaults.setQueryAnchor(for: sampleIdentifier, anchor: newAnchor)
            }
            
            annalist.log(.info, "Health fetched \(sampleIdentifier)")
        } catch {
            error.healthHandle("Fetch \(sampleIdentifier)", using: annalist)
        }
    }
}
