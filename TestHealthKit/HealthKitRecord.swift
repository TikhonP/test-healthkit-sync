//
//  HealthKitRecord.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit

/// Store `HealthKit` record for submit it to Medsenger server
@available(iOS 14.0, macOS 13.0, *)
struct HealthKitRecord: Encodable {
    
    let categoryName: String
    
    let source: String = "health"
    
    /// `Date` as time since 1970
    let time: Date
    
    let value: String
    
}

@available(iOS 14.0, macOS 13.0, *)
extension HealthKitRecord {
    
    /// Init for MedsengerQuantityQuery.
    init(quantity: HKQuantity, date: Date, medsengerQuantityType: MedsengerQuantityType, sources: [HKSource]?) {
        self.categoryName = medsengerQuantityType.medsengerKey
        self.time = date
        let value = quantity.doubleValue(for: medsengerQuantityType.hkUnit)
        self.value = medsengerQuantityType.customDataEncoder?(value) ?? String(value)
    }
    
    /// Init for MedsengerCategoryQuery.
    init?(categorySample: HKCategorySample, medsengerCategoryType: MedsengerCategoryType) {
        guard let value = medsengerCategoryType.dataEncoder(categorySample.value) else {
            return nil
        }
        self.categoryName = medsengerCategoryType.medsengerKey
        self.time = categorySample.startDate
        self.value = value
    }
    
}

extension Array<HealthKitRecord> {
    func submit() async throws {
        guard !self.isEmpty else {
            return
        }
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try jsonEncoder.encode(self)
        
        var request = URLRequest(url: URL(string: "http://194.87.219.15:8080/sample/")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        _ = try await URLSession.shared.upload(for: request, from: data)
    }
}
