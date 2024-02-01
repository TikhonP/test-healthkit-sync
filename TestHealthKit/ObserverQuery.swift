//
//  QuantityObserverQuery.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import HealthKit
import Foundation

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
            try await healthStore.enableBackgroundDelivery(for: medsengerType.sampleType, frequency: .immediate)
            annalist.log(.info, "Enabled background delivery for \(sampleIdentifier)")
        } catch {
            error.healthHandle("enableBackgroundDelivery failed for: \(sampleIdentifier)", using: annalist)
        }
    }
    
    func stopObservingChanges() {
        if let query {
            healthStore.stop(query)
            self.query = nil
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
        
        guard let startDate = UserDefaults.getLastHKSyncDate(for: sampleIdentifier) else {
            annalist.log(.error, "fetchSamples: failed to get start date")
            return
        }
        
        do {
            print("Executing query")
            let now = Date()
            try await QuantityHealthQuery(medsengerQuantityType: medsengerQuantityType, withStart: startDate)
                .getSamples(healthStore: healthStore)
                .submit()
            UserDefaults.setLastHKSyncDate(now, for: sampleIdentifier)
            annalist.log(.info, "HealthKitSync submitted \(sampleIdentifier)")
        } catch {
            error.healthHandle("fetchSamples \(sampleIdentifier)", using: annalist)
        }
    }
}

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
            guard let startDate = await Date.getLastHealthSyncDate() else {
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
            annalist.log(.info, "HealthKitSync submitted \(sampleIdentifier)")
        } catch {
            error.healthHandle("fetchSamples \(sampleIdentifier)", using: annalist)
        }
    }
}
