//
//  AddHotelView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct AddHotelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var autocompleteService = AutocompleteService()
    @State private var searchText = ""
    @State private var name = ""
    @State private var city = ""
    @State private var country = ""
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date()
    @State private var starRating: Int? = nil
    @State private var amenities = ""
    @State private var notes = ""
    @State private var favoriteAspects = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hotel Information") {
                    AutocompleteTextField(
                        placeholder: "Search for a hotel...",
                        text: $searchText,
                        suggestions: autocompleteService.suggestions,
                        onSelect: { result in
                            name = result.title
                            // Extract city and country from subtitle
                            // Format is typically "City, Country" or just "Country"
                            if result.subtitle.contains(",") {
                                let parts = result.subtitle.components(separatedBy: ", ")
                                if parts.count >= 2 {
                                    city = parts.first ?? ""
                                    country = parts.last ?? ""
                                } else {
                                    // If only one comma, split differently
                                    let components = result.subtitle.split(separator: ",")
                                    if components.count >= 2 {
                                        city = String(components[0]).trimmingCharacters(in: .whitespaces)
                                        country = String(components[1]).trimmingCharacters(in: .whitespaces)
                                    } else {
                                        city = result.subtitle
                                    }
                                }
                            } else {
                                // If no comma, assume it's just the country or city
                                // Try to determine if it's a city or country
                                city = result.subtitle
                            }
                            latitude = result.coordinate.latitude
                            longitude = result.coordinate.longitude
                            searchText = result.title
                            autocompleteService.cancelSearch()
                        }
                    )
                    
                    if !name.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected: \(name)")
                                .font(.headline)
                            if !city.isEmpty || !country.isEmpty {
                                Text("\(city)\(city.isEmpty ? "" : ", ")\(country)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Dates") {
                    DatePicker("Check-in", selection: $checkInDate, displayedComponents: .date)
                    DatePicker("Check-out", selection: $checkOutDate, displayedComponents: .date)
                }
                
                Section("Details") {
                    Picker("Star Rating", selection: $starRating) {
                        Text("None").tag(Int?.none)
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating) star\(rating == 1 ? "" : "s")").tag(Int?.some(rating))
                        }
                    }
                    
                    TextField("Amenities (comma separated)", text: $amenities)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Favorite Aspects", text: $favoriteAspects)
                }
            }
            .navigationTitle("Add Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHotel()
                    }
                    .disabled(name.isEmpty || city.isEmpty || country.isEmpty)
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty && newValue != name {
                    autocompleteService.searchHotels(query: newValue)
                } else if newValue.isEmpty {
                    autocompleteService.cancelSearch()
                }
            }
        }
    }
    
    private func saveHotel() {
        let hotel = Hotel(
            name: name,
            city: city,
            country: country,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            starRating: starRating,
            amenities: amenities,
            notes: notes,
            favoriteAspects: favoriteAspects,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(hotel)
        dismiss()
    }
}

#Preview {
    AddHotelView()
        .modelContainer(for: [Hotel.self], inMemory: true)
}

