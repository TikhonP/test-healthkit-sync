//
//  HealthKitSyncService.swift
//  Medsenger
//
//  Created by Tikhon Petrishchev on 01.12.2022.
//  Copyright © 2022 TelePat ltd. All rights reserved.
//

import HealthKit

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

let medsengerParseNotAllowedMetadataKey = "MEDSENGER_PARSE_NOT_ALLOWED"

/// Service provides HealthKit data synchronization with medsenger
@available(iOS 14.0, macOS 13.0, *)
public actor HealthKitSyncService: HealthKitSync {
    
    nonisolated public let isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    private let healthStore = HKHealthStore()
    private let typesToRead: [MedsengerHealthType]
    private let getIsProtectedDataAvailable: () async -> Bool
    private var observerQueries = [ObserverQuery]()
    
//    @Inject private var account: Account
    
    private let annalist: Annalist = OnlyLogAnnalist(withTag: "HealthKitSyncService")
    
    public init(typesToRead: [MedsengerHealthType], getIsProtectedDataAvailable: @escaping () async -> Bool) {
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
                                    error.healthHandle("HealthKitSync requestAuthorization error",
                                                             using: self.annalist)
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
            if let query = await self.observerQueries
                .asyncFirst(where: { await $0.sampleIdentifier == medsengerType.sampleType.identifier }) {
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
    
    public func stopObservingChanges() async {
//        UserDefaults.isHealthKitSyncActive = false
        while !observerQueries.isEmpty {
            await observerQueries.removeFirst().stopObservingChanges()
        }
    }
    
    public func fetchSamples() async {
//        guard UserDefaults.isHealthKitSyncActive ?? false,
//              await requestAuthorization() else {
//            return
//        }
        
//        try? await account.updateProfile()
        
        if observerQueries.isEmpty {
            await startObservingChanges()
            return
        }
        
        await observerQueries.concurrentForEach { observerQuery in
            await observerQuery.fetchSamples()
        }
    }
    
}
