//
//  AddCityView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct AddCityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var autocompleteService = AutocompleteService()
    @State private var searchText = ""
    @State private var name = ""
    @State private var country = ""
    @State private var visitDate = Date()
    @State private var highlights = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("City Information") {
                    AutocompleteTextField(
                        placeholder: "Search for a city...",
                        text: $searchText,
                        suggestions: autocompleteService.suggestions,
                        onSelect: { result in
                            // For cities, use the title as city name
                            // Extract city and country from result
                            if result.type == .city {
                                name = result.title
                                // Extract country from subtitle
                                if result.subtitle.contains(",") {
                                    let parts = result.subtitle.components(separatedBy: ", ")
                                    if parts.count >= 2 {
                                        country = parts.last ?? result.subtitle
                                    } else {
                                        country = result.subtitle
                                    }
                                } else {
                                    country = result.subtitle
                                }
                            } else {
                                // For places, try to extract city name
                                name = result.title
                                country = result.subtitle
                            }
                            latitude = result.coordinate.latitude
                            longitude = result.coordinate.longitude
                            searchText = "\(name), \(country)"
                            autocompleteService.cancelSearch()
                        }
                    )
                    
                    if !name.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected: \(name)")
                                .font(.headline)
                            if !country.isEmpty {
                                Text(country)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                }
                
                Section("Highlights") {
                    TextField("What made this visit special?", text: $highlights, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCity()
                    }
                    .disabled(name.isEmpty || country.isEmpty)
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty && newValue != name {
                    autocompleteService.searchCities(query: newValue)
                } else if newValue.isEmpty {
                    autocompleteService.cancelSearch()
                }
            }
        }
    }
    
    private func saveCity() {
        let city = City(
            name: name,
            country: country,
            visitDate: visitDate,
            highlights: highlights,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(city)
        dismiss()
    }
}

#Preview {
    AddCityView()
        .modelContainer(for: [City.self], inMemory: true)
}

