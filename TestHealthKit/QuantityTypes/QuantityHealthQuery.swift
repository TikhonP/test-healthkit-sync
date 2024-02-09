//
//  QuantityHealthQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

/// Quantity health query offers async interface API for query
/// quantity type samples statistic calculated on all health store samples
/// by intervals provided in ``HealthKitRecord``.
@available(macOS 13.0, *)
class QuantityHealthQuery {
    
    private var continuation: CheckedContinuation<[HealthKitRecord], Error>?
    
    private let quantityType: HKQuantityType
    private let medsengerQuantityType: MedsengerQuantityType
    private let startDate: Date
    
    /// Creates a `QuantityHealthQuery` based on `MedsengerQuantityType` and filtering samples which start date newer that provided date value.
    /// - Parameters:
    ///   - medsengerQuantityType: Sample metadata value.
    ///   - withStart: Lower time limit for samples date.
    init(medsengerQuantityType: MedsengerQuantityType, withStart: Date) {
        self.medsengerQuantityType = medsengerQuantityType
        self.quantityType = medsengerQuantityType.hkQuantityType
        self.startDate = withStart
    }
    
    /// Fetch samples.
    /// - Parameter healthStore: Health store for samples query executing.
    /// - Returns: `HealthKitRecord` objects ready for `JSON` encoding and sending to server.
    func getSamples(healthStore: HKHealthStore) async throws -> [HealthKitRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.executeStatisticsCollectionQuery(healthStore: healthStore)
        }
    }
    
    private func executeStatisticsCollectionQuery(healthStore: HKHealthStore) {
        let now = Date()
        let calendar = Calendar.current
        
        let components = DateComponents(calendar: calendar,
                                        timeZone: calendar.timeZone,
                                        hour: 3,
                                        minute: 0,
                                        second: 0)
        
        guard let anchorDate = calendar.nextDate(after: now,
                                                 matching: components,
                                                 matchingPolicy: .nextTime,
                                                 repeatedTimePolicy: .first,
                                                 direction: .backward) else {
            continuation?.resume(throwing: QuantityHealthQueryError.unableToCreateAnchorDate)
            return
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        
        // Filter samples that added by other Medsenger apps 
        // but sync using different methods
        let allowedSamplesPredicate = NSCompoundPredicate(
            notPredicateWithSubpredicate: HKQuery.predicateForObjects(
                withMetadataKey: medsengerParseNotAllowedMetadataKey)
        )
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, allowedSamplesPredicate])
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: quantityType.aggregationStyle.asStatisticsOptions(),
            anchorDate: anchorDate,
            intervalComponents: medsengerQuantityType.byIntervals
        )
        query.initialResultsHandler = statisticsHandler
        healthStore.execute(query)
    }
    
    private func statisticsHandler(_ query: HKStatisticsCollectionQuery,
                                   _ results: HKStatisticsCollection?,
                                   _ error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            return
        }
        guard let statsCollection = results else {
            continuation?.resume(throwing: QuantityHealthQueryError.resultsIsNil)
            return
        }
        
        let resultData = statsCollection
            .statistics()
            .compactMap { $0.asHealthKitRecord(medsengerQuantityType: medsengerQuantityType) }
        
        continuation?.resume(returning: resultData)
    }
}

@available(macOS 13.0, *)
private extension HKStatistics {
    func asHealthKitRecord(medsengerQuantityType: MedsengerQuantityType) -> HealthKitRecord? {
        switch self.quantityType.aggregationStyle {
        case .cumulative:
            if let quantity = self.sumQuantity() {
                return HealthKitRecord(
                    quantity: quantity,
                    date: self.startDate,
                    medsengerQuantityType: medsengerQuantityType
                )
            }
        case .discreteArithmetic, .discrete, .discreteTemporallyWeighted, .discreteEquivalentContinuousLevel:
            if let quantity = self.averageQuantity() {
                return HealthKitRecord(
                    quantity: quantity,
                    date: self.startDate,
                    medsengerQuantityType: medsengerQuantityType
                )
            }
        default:
            return nil
        }
        return nil
    }
}

@available(macOS 13.0, *)
private extension HKQuantityAggregationStyle {
    func asStatisticsOptions() -> HKStatisticsOptions {
        switch self {
        case .cumulative:
            return .cumulativeSum
        case .discreteArithmetic, .discrete, .discreteTemporallyWeighted, .discreteEquivalentContinuousLevel:
            return .discreteAverage
        default:
            return []
        }
    }
}

private enum QuantityHealthQueryError: String, LocalizedError {
    case resultsIsNil = "Collection statistic query got nil results collection."
    case unableToCreateAnchorDate = "Failed to create anchor date using calendar.nextDate."
    
    var errorDescription: String? { rawValue }
}
