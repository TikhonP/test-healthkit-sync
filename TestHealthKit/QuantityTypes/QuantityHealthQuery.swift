//
//  QuantityHealthQuery.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

@available(macOS 13.0, *)
class QuantityHealthQuery {
    
    private var continuation: CheckedContinuation<[HealthKitRecord], Error>?
    
    private let quantityType: HKQuantityType
    private let medsengerQuantityType: MedsengerQuantityType
    private let startDate: Date
    
    init(medsengerQuantityType: MedsengerQuantityType, withStart: Date) {
        self.medsengerQuantityType = medsengerQuantityType
        self.quantityType = medsengerQuantityType.hkQuantityType
        self.startDate = withStart
    }
    
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
extension HKStatistics {
    func asHealthKitRecord(medsengerQuantityType: MedsengerQuantityType) -> HealthKitRecord? {
        switch self.quantityType.aggregationStyle {
        case .cumulative:
            if let quantity = self.sumQuantity() {
                return HealthKitRecord(
                    quantity: quantity,
                    date: self.startDate,
                    medsengerQuantityType: medsengerQuantityType,
                    sources: self.sources
                )
            }
        case .discreteArithmetic, .discrete, .discreteTemporallyWeighted, .discreteEquivalentContinuousLevel:
            if let quantity = self.averageQuantity() {
                return HealthKitRecord(
                    quantity: quantity,
                    date: self.startDate,
                    medsengerQuantityType: medsengerQuantityType,
                    sources: self.sources
                )
            }
        default:
            return nil
        }
        return nil
    }
}

@available(macOS 13.0, *)
extension HKQuantityAggregationStyle {
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

enum QuantityHealthQueryError: LocalizedError {
    case resultsIsNil
    case unableToCreateAnchorDate
}
