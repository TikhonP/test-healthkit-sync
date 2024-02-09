//
//  CategoryHealthQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

/// Category health query offers async interface API for query
/// category type samples using anchored query.
@available(macOS 13.0, *)
class CategoryHealthQuery {
    
    /// Bottom date anchor for filtering already fetched samples.
    enum AnchorData {
        case startDate(Date)
        case anchor(HKQueryAnchor)
    }
    
    typealias NewAnchorHandler = (HKQueryAnchor?) -> Void
    
    private var continuation: CheckedContinuation<[HealthKitRecord], Error>?
    
    private let categoryType: HKCategoryType
    private let medsengerCategoryType: MedsengerCategoryType
    private let anchor: AnchorData
    private let newAnchorHandler: NewAnchorHandler
    
    /// Creates `CategoryHealthQuery` based on `MedsengerQuantityType` and filtering samples using anchor data.
    /// - Parameters:
    ///   - medsengerCategoryType: Sample metadata value.
    ///   - anchor: Anchor for filtering already fetched samples.
    ///   - newAnchorHandler: Emits new `HKQueryAnchor` to persist it up to next query.
    init(medsengerCategoryType: MedsengerCategoryType,
         anchor: AnchorData,
         newAnchorHandler: @escaping NewAnchorHandler) {
        self.medsengerCategoryType = medsengerCategoryType
        self.categoryType = medsengerCategoryType.hkCategoryType
        self.anchor = anchor
        self.newAnchorHandler = newAnchorHandler
    }
    
    /// Fetch samples.
    /// - Parameter healthStore: Health store for samples query executing.
    /// - Returns: `HealthKitRecord` objects ready for `JSON` encoding and sending to server.
    func getSamples(healthStore: HKHealthStore) async throws -> [HealthKitRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.executeCategoryQuery(healthStore: healthStore)
        }
    }
    
    func executeCategoryQuery(healthStore: HKHealthStore) {
        
        // Filter samples that added by other Medsenger apps
        // but sync using different methods
        let allowedSamplesPredicate = NSCompoundPredicate(
            notPredicateWithSubpredicate: HKQuery.predicateForObjects(
                withMetadataKey: medsengerParseNotAllowedMetadataKey)
        )
        
        let query: HKAnchoredObjectQuery
        switch anchor {
        case .startDate(let date):
            
            // If HK anchor does not exist query samples based on start date
            let datePredicate = HKQuery.predicateForSamples(withStart: date, end: Date())
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, allowedSamplesPredicate])
            
            query = HKAnchoredObjectQuery(
                type: medsengerCategoryType.sampleType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: resultsHandler)
            
        case .anchor(let anchor):
            
            // Anchored query
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
        
        // Emit new query anchor to persist it
        newAnchorHandler(newAnchor)
        
        let records = (newSamples as? [HKCategorySample])?
            .compactMap { HealthKitRecord(categorySample: $0, medsengerCategoryType: medsengerCategoryType) }
        
        continuation?.resume(returning: records ?? [])
    }
    
}
