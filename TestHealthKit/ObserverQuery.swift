//
//  QuantityObserverQuery.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import HealthKit

protocol ObserverQuery: Actor {
    
    var isFetchingData: Bool { get set }
    var query: HKObserverQuery? { get set }
    var medsengerType: MedsengerHealthType { get }
    var healthStore: HKHealthStore { get }
    var annalist: Annalist { get }
    var getIsProtectedDataAvailable: () async -> Bool { get }
    var sampleIdentifier: String { get }
    
    func fetchSamples() async
    func startObservingChanges() async
    func stopObservingChanges() async
    
}

extension ObserverQuery {
    
    func lock() -> Bool {
        let isFetchingData = isFetchingData
        if !isFetchingData {
            self.isFetchingData = true
        }
        return !isFetchingData
    }
    
    func unlock() {
        isFetchingData = false
    }
    
    func startObservingChanges() async {
        guard query == nil else {
            return
        }
        let query = HKObserverQuery(sampleType: medsengerType.sampleType, predicate: nil, updateHandler: observerHandler)
        self.query = query
        healthStore.execute(query)
        do {
            try await healthStore.enableBackgroundDelivery(for: medsengerType.sampleType, frequency: medsengerType.updateFrequency)
            annalist.log(.info, "Enabled background delivery for \(sampleIdentifier)")
        } catch {
            error.healthHandle("enableBackgroundDelivery failed for: \(sampleIdentifier)", using: annalist)
        }
    }
    
    func stopObservingChanges() async {
        if let query {
            healthStore.stop(query)
            self.query = nil
            do {
                try await healthStore.disableBackgroundDelivery(for: medsengerType.sampleType)
            } catch {
                error.healthHandle("disableBackgroundDelivery failed for: \(sampleIdentifier)", using: annalist)
            }
        }
    }
    
    func observerHandler(_ query: HKObserverQuery,
                         _ completionHandler: @escaping HKObserverQueryCompletionHandler,
                         _ error: Error?) {
        annalist.log(.info, "Called updateHandler for \(query.description) with object type: \(query.objectType?.identifier ?? "nil")")
        if let error {
            error.healthHandle("HealthKitSync updateHandler error", using: annalist)
            completionHandler()
            return
        }
        // TODO: uncomment
        /*
         guard "UserDefaults.isHealthKitSyncActive ?? false" else {
         healthStore.stop(query)
         annalist.log(.info, "Stop query because isHealthKitSyncActive is false")
         completionHandler()
         return
         */
        Task {
            guard await getIsProtectedDataAvailable() else {
                annalist.log(.info, "updateHandler: got updates but device is locked")
                completionHandler()
                return
            }
            await fetchSamples()
            completionHandler()
        }
    }
}
