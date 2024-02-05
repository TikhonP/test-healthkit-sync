//
//  HealthKitService.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit
import Foundation

let medsengerParseNotAllowedMetadataKey = "MEDSENGER_PARSE_NOT_ALLOWED"

public protocol HealthKitSync: Actor {
    
    /// Available or not HealthKit service on current device
    nonisolated var isHealthDataAvailable: Bool { get }
    
    /// Requests permission to save and read the specified data types.
    /// - Returns: Success granted or not.
    func requestAuthorization() async -> Bool
    
    /// One time sync HealthKit records with Medsenger
    func fetchSamples() async
    
    /// Start background fetch HealthKit records with Medsenger
    func startObservingChanges() async
    
    /// Stop background fetch HealthKit records with Medsenger
    func stopObservingChanges() async
    
}

public actor HealthKitSyncService: HealthKitSync {
    
    nonisolated public let isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    private let healthStore = HKHealthStore()
    private let typesToRead: [MedsengerHealthType]
    private let getIsProtectedDataAvailable: () async -> Bool
    private let annalist: Annalist = OnlyLogAnnalist(withTag: "HealthKitSyncService")
    private var observerQueries = [ObserverQuery]()
    
    init(typesToRead: [MedsengerHealthType], getIsProtectedDataAvailable: @escaping () async -> Bool) {
        self.typesToRead = typesToRead
        self.getIsProtectedDataAvailable = getIsProtectedDataAvailable
    }
    
    public func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else {
            return false
        }
        if #available(iOS 15.0, *) {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: typesToRead.asSampleTypesSet())
                return true
            } catch {
                error.healthHandle("HealthKitSync requestAuthorization error", using: annalist)
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                healthStore.requestAuthorization(
                    toShare: [], read: typesToRead.asSampleTypesSet()) { [weak self] success, error in
                        if let error {
                            if let self {
                                Task {
                                    error.healthHandle("HealthKitSync requestAuthorization error", using: self.annalist)
                                }
                            }
                            continuation.resume(returning: false)
                            return
                        }
                        continuation.resume(returning: success)
                    }
            }
        }
    }
    
    public func startObservingChanges() async {
        await typesToRead.concurrentForEach { medsengerType in
            if let query = await self.observerQueries.asyncFirst(where: { await $0.sampleIdentifier == medsengerType.sampleType.identifier }) {
                await query.startObservingChanges()
            } else {
                let query = medsengerType.getObserverQuery(
                    healthStore: self.healthStore,
                    getIsProtectedDataAvailable: self.getIsProtectedDataAvailable
                )
                self.observerQueries.append(query)
                await query.startObservingChanges()
            }
        }
    }
    
    public func fetchSamples() async {
        //        guard UserDefaults.isHealthKitSyncActive ?? false,
        //              await authorizeHealthKit() else {
        //            return
        //        }
        
        // try? await account.updateProfile()
        
        if observerQueries.isEmpty {
            await startObservingChanges()
        }
        
        await observerQueries.concurrentForEach { observerQuery in
            await observerQuery.fetchSamples()
        }
    }
    
    public func stopObservingChanges() async {
        // UserDefaults.isHealthKitSyncActive = false
        while !observerQueries.isEmpty {
            await observerQueries.removeFirst().stopObservingChanges()
        }
    }
    
}
