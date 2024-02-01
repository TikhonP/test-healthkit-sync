//
//  TestHealthKitApp.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import HealthKit
import SwiftUI
import SwiftData

let typesToRead: [(any MedsengerHealthType)?] = [
    MedsengerQuantityType(.stepCount, hkUnit: .count(), medsengerKey: "steps", byIntervals: DateComponents(minute: 10)),
    MedsengerQuantityType(.heartRate, hkUnit: .count().unitDivided(by: .minute()), medsengerKey: "pulse"),
    MedsengerQuantityType(.oxygenSaturation, hkUnit: .init(from: "%"),
                          medsengerKey: "spo2", customDataEncoder: { String(Int($0 * 100)) }),
    MedsengerQuantityType(.respiratoryRate, hkUnit: .count().unitDivided(by: .minute()), medsengerKey: "respiration_rate"),
    MedsengerQuantityType(
        .bloodPressureSystolic, hkUnit: .millimeterOfMercury(), medsengerKey: "systolic_pressure"),
    MedsengerQuantityType(
        .bloodPressureDiastolic, hkUnit: .millimeterOfMercury(), medsengerKey: "diastolic_pressure"),
    MedsengerQuantityType(
        .bloodGlucose,
        hkUnit: .moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter()),
        medsengerKey: "glukose"),
    MedsengerQuantityType(
        .bodyTemperature, hkUnit: .degreeCelsius(), medsengerKey: "temperature"),
    MedsengerQuantityType(
        .peakExpiratoryFlowRate, hkUnit: .liter().unitDivided(by: .minute()), medsengerKey: "peak_flow"),
    MedsengerQuantityType(.forcedVitalCapacity, hkUnit: .liter(), medsengerKey: "FVC"),
    MedsengerQuantityType(
        .forcedExpiratoryVolume1, hkUnit: .liter(), medsengerKey: "FEV1"),
    MedsengerQuantityType(
        .distanceWalkingRunning, hkUnit: .meter(),
        medsengerKey: "walking_distance", byIntervals: DateComponents(minute: 10)),
    MedsengerQuantityType(
        .activeEnergyBurned, hkUnit: .kilocalorie(),
        medsengerKey: "active_energy_burned", byIntervals: DateComponents(minute: 10)),
    MedsengerQuantityType(.bodyMass, hkUnit: .gramUnit(with: .kilo), medsengerKey: "weight"),
    MedsengerQuantityType(.height, hkUnit: .meterUnit(with: .centi), medsengerKey: "height"),
    
    MedsengerCategoryType(.menstrualFlow, medsengerKey: "information", dataEncoder: { value in
        switch HKCategoryValueMenstrualFlow(rawValue: value) {
        case .heavy:
            return "Интенсивность менструации: обильное"
        case .medium:
            return "Интенсивность менструации: умеренное"
        case .light:
            return "Интенсивность менструации: скудное"
        case .unspecified:
            return "Месячные в этот день"
        default:
            return nil
        }
    }),
]

extension HealthKitSyncService {
    static let shared = HealthKitSyncService(
        typesToRead: typesToRead.compactMap { $0 },
        skipSourcesBundleIdentifiers: [],
        getIsProtectedDataAvailable: {
            await MainActor.run {
                UIApplication.shared.isProtectedDataAvailable
            }
        })
}

@main
struct TestHealthKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
