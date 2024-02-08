//
//  CategoryHealthQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

@available(macOS 13.0, *)
enum AnchorData {
    case startDate(Date)
    case anchor(HKQueryAnchor)
}

@available(macOS 13.0, *)
typealias NewAnchorHandler = (HKQueryAnchor?) -> Void

@available(macOS 13.0, *)
class CategoryHealthQuery {
    
    private var continuation: CheckedContinuation<[HealthKitRecord], Error>?
    
    private let categoryType: HKCategoryType
    private let medsengerCategoryType: MedsengerCategoryType
    private let anchor: AnchorData
    private let newAnchorHandler: NewAnchorHandler
    
    init(medsengerCategoryType: MedsengerCategoryType,
         anchor: AnchorData,
         newAnchorHandler: @escaping NewAnchorHandler) {
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
        
        let allowedSamplesPredicate = NSCompoundPredicate(
            notPredicateWithSubpredicate: HKQuery.predicateForObjects(
                withMetadataKey: medsengerParseNotAllowedMetadataKey)
        )
        
        let query: HKAnchoredObjectQuery
        switch anchor {
        case .startDate(let date):
            let datePredicate = HKQuery.predicateForSamples(withStart: date, end: Date())
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, allowedSamplesPredicate])
            query = HKAnchoredObjectQuery(
                type: medsengerCategoryType.sampleType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: resultsHandler)
        case .anchor(let anchor):
            query = HKAnchoredObjectQuery(
                type: medsengerCategoryType.sampleType,
                predicate: allowedSamplesPredicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit,
                resultsHandler: resultsHandler)
        }
        healthStore.execute(query)
    }
    
    func resultsHandler(_ query: HKAnchoredObjectQuery, _ newSamples: [HKSample]?,
                        _ deletedObjects: [HKDeletedObject]?, _ newAnchor: HKQueryAnchor?,
                        _ error: Error?) {
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
