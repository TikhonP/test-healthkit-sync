//
//  ContentView.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Health Sync Service") {
                    Button("Authorize health") {
                        Task {
                            await HealthKitSyncService.shared.requestAuthorization()
                        }
                    }
                    Button("Start observing health changes") {
                        Task {
                            await HealthKitSyncService.shared.startObservingChanges()
                        }
                    }
                    Button("Stop observing health changes") {
                        Task {
                            await HealthKitSyncService.shared.stopObservingChanges()
                        }
                    }
                    Button("Fetch samples") {
                        Task {
                            await HealthKitSyncService.shared.fetchSamples()
                        }
                    }
                    
                }
                
                Section {
                    Button("Reset User Defaults store") {
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                    }
                }
                
                Section {
                    Link("Samples", destination: URL(string: "http://194.87.219.15:8080/samples/")!)
                }
            }
            .navigationTitle("HealthKit sync test")
            .tint(.cyan)
        }
    }
}

#Preview {
    ContentView()
}
