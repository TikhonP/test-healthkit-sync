//
//  CategoryHealthQuery.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import HealthKit
import Foundation

enum AnchorData {
    case startDate(Date)
    case anchor(HKQueryAnchor)
}

typealias NewAnchorHandler = (HKQueryAnchor?) -> Void

class CategoryHealthQuery {
    
    private var continuation: CheckedContinuation<[HealthKitRecord], Error>?
    
    private let categoryType: HKCategoryType
    private let medsengerCategoryType: MedsengerCategoryType
    private let anchor: AnchorData
    private let newAnchorHandler: NewAnchorHandler
    
    init(medsengerCategoryType: MedsengerCategoryType, anchor: AnchorData, newAnchorHandler: @escaping NewAnchorHandler) {
        self.medsengerCategoryType = medsengerCategoryType
        self.categoryType = medsengerCategoryType.hkCategoryType
        self.anchor = anchor
        self.newAnchorHandler = newAnchorHandler
    }
    
    func getSamples(healthStore: HKHealthStore) async throws -> [HealthKitRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.executeCategoryQuery(healthStore: healthStore)
        }
    }
    
    func executeCategoryQuery(healthStore: HKHealthStore) {
        let query: HKAnchoredObjectQuery
        switch anchor {
        case .startDate(let date):
            query = HKAnchoredObjectQuery(
                type: medsengerCategoryType.sampleType,
                predicate: HKQuery.predicateForSamples(withStart: date, end: Date()),
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: resultsHandler)
        case .anchor(let anchor):
            query = HKAnchoredObjectQuery(
                type: medsengerCategoryType.sampleType,
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit,
                resultsHandler: resultsHandler)
        }
        healthStore.execute(query)
    }
    
    func resultsHandler(_ query: HKAnchoredObjectQuery, _ newSamples: [HKSample]?, _ deletedObjects: [HKDeletedObject]?, _ newAnchor: HKQueryAnchor?, _ error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            return
        }
        newAnchorHandler(newAnchor)
        let records = (newSamples as? [HKCategorySample])?
            .compactMap { HealthKitRecord(categorySample: $0, medsengerCategoryType: medsengerCategoryType) }
        continuation?.resume(returning: records ?? [])
    }
    
}