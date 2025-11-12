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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Trip.self, Hotel.self, City.self])
    }
}
