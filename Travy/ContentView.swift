//
//  ContentView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(0)
            
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(1)
            
            CitiesListView()
                .tabItem {
                    Label("Cities", systemImage: "mappin.circle")
                }
                .tag(2)
            
            HotelsListView()
                .tabItem {
                    Label("Hotels", systemImage: "bed.double")
                }
                .tag(3)

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, Hotel.self, City.self], inMemory: true)
}
