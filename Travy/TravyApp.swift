//
//  TravyApp.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData

@main
struct TravyApp: App {
    // Create a shared model container with explicit persistence configuration
    static let sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([Trip.self, Hotel.self, City.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If there's a schema mismatch, delete the old store and try again
            print("Failed to create ModelContainer: \(error)")
            print("Attempting to delete old store and recreate...")
            
            // Delete the default store files
            let fileManager = FileManager.default
            if let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = url.appendingPathComponent("default.store")
                let shmURL = url.appendingPathComponent("default.store-shm")
                let walURL = url.appendingPathComponent("default.store-wal")
                
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: shmURL)
                try? fileManager.removeItem(at: walURL)
            }
            
            // Try creating again with a fresh store
            do {
                let schema = Schema([Trip.self, Hotel.self, City.self])
                let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer even after deleting old store: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(TravyApp.sharedModelContainer)
    }
}
