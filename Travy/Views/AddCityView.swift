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
    @State private var selectedPhotos: [UIImage] = []
    @State private var cityRating = CityRating()
    @State private var isGeocoding = false
    
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
                            if isGeocoding {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Getting location...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if latitude != nil && longitude != nil {
                                Text("📍 Location found")
                                    .font(.caption)
                                    .foregroundColor(.green)
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

                Section("Photos") {
                    PhotoPickerButton(photos: $selectedPhotos, maxPhotos: 10)
                    PhotoGridView(photos: $selectedPhotos)
                }

                Section("Ratings") {
                    CategoryRatingInput(rating: $cityRating)
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
            .onChange(of: name) { oldValue, newValue in
                if !newValue.isEmpty && !country.isEmpty {
                    geocodeCity()
                }
            }
            .onChange(of: country) { oldValue, newValue in
                if !name.isEmpty && !newValue.isEmpty {
                    geocodeCity()
                }
            }
        }
    }
    
    private func geocodeCity() {
        guard !name.isEmpty && !country.isEmpty else { return }
        
        // If coordinates already exist from autocomplete, don't geocode again
        if latitude != nil && longitude != nil {
            return
        }
        
        isGeocoding = true
        
        Task {
            do {
                if let coordinate = try await NominatimService.shared.geocodeCity(name: name, country: country) {
                    await MainActor.run {
                        self.latitude = coordinate.latitude
                        self.longitude = coordinate.longitude
                        self.isGeocoding = false
                    }
                } else {
                    await MainActor.run {
                        self.isGeocoding = false
                    }
                }
            } catch {
                print("Geocoding error: \(error)")
                await MainActor.run {
                    self.isGeocoding = false
                }
            }
        }
    }
    
    private func saveCity() {
        // If coordinates are missing, try to geocode one more time before saving
        if latitude == nil || longitude == nil {
            Task {
                do {
                    if let coordinate = try await NominatimService.shared.geocodeCity(name: name, country: country) {
                        await MainActor.run {
                            self.latitude = coordinate.latitude
                            self.longitude = coordinate.longitude
                            self.performSave()
                        }
                    } else {
                        await MainActor.run {
                            // Save without coordinates if geocoding fails
                            self.performSave()
                        }
                    }
                } catch {
                    print("Geocoding error: \(error)")
                    await MainActor.run {
                        // Save without coordinates if geocoding fails
                        self.performSave()
                    }
                }
            }
        } else {
            performSave()
        }
    }
    
    private func performSave() {
        let city = City(
            name: name,
            country: country,
            visitDate: visitDate,
            highlights: highlights,
            latitude: latitude,
            longitude: longitude
        )

        // Save photos and get filenames
        for photo in selectedPhotos {
            if let filename = PhotoManager.shared.savePhoto(image: photo, for: city.id, type: .city) {
                city.photoFilenames.append(filename)
            }
        }

        // Save rating if any category is rated
        if cityRating.hasAnyRating {
            city.ratings = cityRating
        }

        modelContext.insert(city)
        
        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save city: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    AddCityView()
        .modelContainer(for: [City.self], inMemory: true)
}

