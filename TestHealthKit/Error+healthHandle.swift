//
//  Error+healthHandle.swift
//
//
//  Created by Tikhon Petrishchev on 05.02.2024.
//

import HealthKit

@available(macOS 13.0, *)
extension Error {
    func healthHandle(_ message: String, using annalist: Annalist) {
        if (self as NSError).code == 100 {
            // Authorization session timed out
            annalist.log(.error, "HealthKit authorization session timed out.")
        } else if let hkError = self as? HKError {
            if hkError.code == .errorDatabaseInaccessible {
                annalist.log(.error, "\(message): The HealthKit data is unavailable because it’s protected and the device is locked.")
                return
            } else if hkError.code == .errorAuthorizationNotDetermined {
                annalist.log(.warning, "HealthKit authorization not determined")
                return
            }
            annalist.capture(error: hkError, withMessage: message)
        } else {
            annalist.capture(error: self, withMessage: message)
        }
    }
}
