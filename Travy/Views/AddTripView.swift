//
//  AddTripView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var hotels: [Hotel]
    
    @State private var city = ""
    @State private var country = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var travelTag = "Vacation"
    @State private var selectedHotels: Set<UUID> = []
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var isGeocoding = false
    
    let travelTags = ["Vacation", "Business", "Conference", "Family", "Solo", "Adventure"]
    
    var availableHotels: [Hotel] {
        hotels.filter { hotel in
            hotel.city.lowercased() == city.lowercased() &&
            hotel.country.lowercased() == country.lowercased()
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Information") {
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Details") {
                    Picker("Travel Tag", selection: $travelTag) {
                        ForEach(travelTags, id: \.self) { tag in
                            Text(tag).tag(tag)
                        }
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if !availableHotels.isEmpty {
                    Section("Hotels in \(city)") {
                        ForEach(availableHotels) { hotel in
                            HStack {
                                Text(hotel.name)
                                Spacer()
                                if selectedHotels.contains(hotel.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedHotels.contains(hotel.id) {
                                    selectedHotels.remove(hotel.id)
                                } else {
                                    selectedHotels.insert(hotel.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(city.isEmpty || country.isEmpty)
                }
            }
            .onChange(of: city) { _, _ in
                geocodeLocation()
            }
            .onChange(of: country) { _, _ in
                geocodeLocation()
            }
        }
    }
    
    private func geocodeLocation() {
        guard !city.isEmpty && !country.isEmpty else { return }
        isGeocoding = true
        
        let geocoder = CLGeocoder()
        let address = "\(city), \(country)"
        geocoder.geocodeAddressString(address) { placemarks, error in
            isGeocoding = false
            if let placemark = placemarks?.first,
               let location = placemark.location {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
            }
        }
    }
    
    private func saveTrip() {
        let associatedHotels = hotels.filter { selectedHotels.contains($0.id) }
        let trip = Trip(
            city: city,
            country: country,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            travelTag: travelTag,
            hotels: associatedHotels,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(trip)
        dismiss()
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [Trip.self, Hotel.self], inMemory: true)
}



