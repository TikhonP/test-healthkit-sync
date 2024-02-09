//
//  QuantityObserverQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

/// Observe changes and fetch quantity type samples using simple async API.
@available(macOS 13.0, *)
actor QuantityObserverQuery: ObserverQuery {
    
    let healthStore: HKHealthStore
    let getIsProtectedDataAvailable: () async -> Bool
    
    var query: HKObserverQuery?
    var isFetchingData = false
    
    var annalist: Annalist = OnlyLogAnnalist(withTag: "QuantityObserverQuery")
    
    private let medsengerQuantityType: MedsengerQuantityType
    
    init(medsengerQuantityType: MedsengerQuantityType,
         healthStore: HKHealthStore,
         getIsProtectedDataAvailable: @escaping () async -> Bool) {
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
        
        // Lock fetching for excluding situation where there are two fetch request
        // in the same time but last sync date anchor was not updated and samples are duplicated.
        guard lock() else { return }
        defer { unlock() }
        
        // Bottom date anchor init in local timezone
        let startDate: Date
        
        // Check if last sync date value was stored in defaults or not
        let isFirstFetch: Bool
        
        if let storedStartDate = UserDefaults.getLastSyncDate(for: sampleIdentifier) {
            startDate = storedStartDate
            isFirstFetch = false
        } else {
            // Fallback bottom anchor point
            startDate = await Date.getMedsengerLastSyncDate()
            isFirstFetch = true
        }
        
        do {
            
            // Start time of current fetch session (in local timezone)
            let now = Date()
            
            // Fetch samples from Health Store
            let samples = try await QuantityHealthQuery(medsengerQuantityType: medsengerQuantityType, withStart: startDate)
                .getSamples(healthStore: healthStore)
            
            try await submitHandler(QueryHandleEvent(categoryName: sampleIdentifier, valuesCount: samples.count))
            
            // Save new bottom time anchor only nothing saved in defaults (isFirstFetch)
            // or if something was fetched. So if some samples will be added to store after this handler run
            // for near past it will be possible to fetch them and only after getting samples saving new date anchor.
            if !samples.isEmpty || isFirstFetch {
                try await samples.submit()
                
                // Save new anchor only after submit to be sure there was not any error
                UserDefaults.setLastSyncDate(now, for: sampleIdentifier)
                
                annalist.log(.info, "Health fetched \(sampleIdentifier)")
            }
            
        } catch {
            error.healthHandle("Fetch \(sampleIdentifier)", using: annalist)
        }
    }
    
    struct QueryHandleEvent: Encodable {
        let categoryName: String
        let valuesCount: Int
    }
    
    private func submitHandler(_ event: QueryHandleEvent) async throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try jsonEncoder.encode(event)
        var request = URLRequest(url: URL(string: "http://194.87.219.15:8080/query_handle_event/")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await URLSession.shared.upload(for: request, from: data)
    }
    
}
