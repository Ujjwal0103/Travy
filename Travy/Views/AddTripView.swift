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
    @Query private var allCities: [City]
    @Query private var allHotels: [Hotel]
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var travelTag = "Vacation"
    @State private var selectedCities: [City] = []
    @State private var selectedHotels: Set<UUID> = []
    @State private var showingAddCity = false
    @State private var showingAddHotel = false
    @State private var cityForHotel: City? = nil
    
    let travelTags = ["Vacation", "Business", "Conference", "Family", "Solo", "Adventure"]
    
    var availableHotels: [Hotel] {
        guard !selectedCities.isEmpty else { return [] }
        let selectedCityNames = Set(selectedCities.map { $0.name.lowercased() })
        let selectedCountries = Set(selectedCities.map { $0.country.lowercased() })
        
        return allHotels.filter { hotel in
            selectedCityNames.contains(hotel.city.lowercased()) &&
            selectedCountries.contains(hotel.country.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Information") {
                    TextField("Trip Name", text: $tripName)
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
                
                Section {
                    HStack {
                        Text("Cities")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddCity = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if selectedCities.isEmpty {
                        Text("No cities added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(selectedCities) { city in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(city.name)
                                        .font(.headline)
                                    Text(city.country)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    selectedCities.removeAll { $0.id == city.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Cities in Trip")
                }
                
                if !selectedCities.isEmpty {
                    Section {
                        HStack {
                            Text("Hotels")
                                .font(.headline)
                            Spacer()
                            Button {
                                showingAddHotel = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if availableHotels.isEmpty {
                            Text("No hotels found for selected cities")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(availableHotels) { hotel in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                Text(hotel.name)
                                            .font(.headline)
                                        Text(hotel.locationString)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
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
                    } header: {
                        Text("Hotels in Selected Cities")
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
                    .disabled(tripName.isEmpty || selectedCities.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddCity) {
                AddCityViewForTrip(selectedCities: $selectedCities, allCities: allCities)
            }
            .sheet(isPresented: $showingAddHotel) {
                AddHotelViewForTrip(
                    selectedHotels: $selectedHotels,
                    allHotels: allHotels,
                    cities: selectedCities
                )
            }
        }
    }
    
    private func saveTrip() {
        let associatedHotels = allHotels.filter { selectedHotels.contains($0.id) }
        let trip = Trip(
            name: tripName,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            travelTag: travelTag,
            cities: selectedCities,
            hotels: associatedHotels
        )
        modelContext.insert(trip)
        
        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save trip: \(error)")
        }
        
        dismiss()
    }
}

// Helper view for adding cities from within trip
struct AddCityViewForTrip: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCities: [City]
    let allCities: [City]
    
    @StateObject private var autocompleteService = AutocompleteService()
    @State private var searchText = ""
    @State private var showingNewCityForm = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingNewCityForm = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New City")
                        }
                    }
                }
                
                Section("Existing Cities") {
                    ForEach(allCities) { city in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city.name)
                                    .font(.headline)
                                Text(city.country)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedCities.contains(where: { $0.id == city.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let index = selectedCities.firstIndex(where: { $0.id == city.id }) {
                                selectedCities.remove(at: index)
                            } else {
                                selectedCities.append(city)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewCityForm) {
                AddCityViewWithHotelOption(selectedCities: $selectedCities)
            }
        }
    }
}

// Helper view for adding hotels from within trip
struct AddHotelViewForTrip: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHotels: Set<UUID>
    let allHotels: [Hotel]
    let cities: [City]
    
    @State private var showingNewHotelForm = false
    @State private var selectedCityForHotel: City? = nil
    
    var availableHotels: [Hotel] {
        guard !cities.isEmpty else { return [] }
        let cityNames = Set(cities.map { $0.name.lowercased() })
        let countries = Set(cities.map { $0.country.lowercased() })
        
        return allHotels.filter { hotel in
            cityNames.contains(hotel.city.lowercased()) &&
            countries.contains(hotel.country.lowercased())
        }
    }
    
    var hotelsByCity: [String: [Hotel]] {
        Dictionary(grouping: availableHotels) { hotel in
            "\(hotel.city), \(hotel.country)"
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if cities.count == 1 {
                            selectedCityForHotel = cities.first
                            showingNewHotelForm = true
                        } else {
                            // Show city picker if multiple cities
                            // For now, use first city - could add a picker here
                            selectedCityForHotel = cities.first
                            showingNewHotelForm = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Hotel")
                        }
                    }
                }
                
                if availableHotels.isEmpty {
                    Section {
                        Text("No hotels found for selected cities")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                } else {
                    ForEach(Array(hotelsByCity.keys.sorted()), id: \.self) { cityKey in
                        Section(cityKey) {
                            ForEach(hotelsByCity[cityKey] ?? []) { hotel in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(hotel.name)
                                            .font(.headline)
                                        Text(hotel.locationString)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
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
            }
            .navigationTitle("Select Hotels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewHotelForm) {
                if let city = selectedCityForHotel {
                    AddHotelViewWithCity(city: city)
                }
            }
        }
    }
}

// Helper view for adding a city with option to add hotels
struct AddCityViewWithHotelOption: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCities: [City]
    
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
    @State private var showingAddHotel = false
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
                            if result.type == .city {
                                name = result.title
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
                
                if !name.isEmpty && !country.isEmpty {
                    Section {
                        Button {
                            showingAddHotel = true
                        } label: {
                            HStack {
                                Image(systemName: "bed.double.fill")
                                Text("Add Hotel in \(name)")
                            }
                        }
                    }
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
            .sheet(isPresented: $showingAddHotel) {
                AddHotelViewWithCity(city: nil, cityName: name, country: country)
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
        
        // Add to selected cities
        selectedCities.append(city)
        
        dismiss()
    }
}

// Helper view for adding a hotel with city pre-filled
struct AddHotelViewWithCity: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCities: [City]
    
    let city: City?
    let cityName: String?
    let country: String?
    
    @StateObject private var autocompleteService = AutocompleteService()
    @State private var searchText = ""
    @State private var name = ""
    @State private var hotelCity = ""
    @State private var hotelCountry = ""
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date()
    @State private var starRating: Int? = nil
    @State private var amenities = ""
    @State private var notes = ""
    @State private var favoriteAspects = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var selectedPhotos: [UIImage] = []
    
    init(city: City) {
        self.city = city
        self.cityName = city.name
        self.country = city.country
    }
    
    init(city: City?, cityName: String, country: String) {
        self.city = city
        self.cityName = cityName
        self.country = country
    }
    
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
                            if result.subtitle.contains(",") {
                                let parts = result.subtitle.components(separatedBy: ", ")
                                if parts.count >= 2 {
                                    hotelCity = parts.first ?? ""
                                    hotelCountry = parts.last ?? ""
                                } else {
                                    let components = result.subtitle.split(separator: ",")
                                    if components.count >= 2 {
                                        hotelCity = String(components[0]).trimmingCharacters(in: .whitespaces)
                                        hotelCountry = String(components[1]).trimmingCharacters(in: .whitespaces)
                                    } else {
                                        hotelCity = result.subtitle
                                    }
                                }
                            } else {
                                hotelCity = result.subtitle
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
                            if !hotelCity.isEmpty || !hotelCountry.isEmpty {
                                Text("\(hotelCity)\(hotelCity.isEmpty ? "" : ", ")\(hotelCountry)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Pre-fill city and country if provided
                    if let cityName = cityName, let country = country {
                        HStack {
                            Text("City:")
                                .foregroundColor(.secondary)
                            Text(cityName)
                        }
                        HStack {
                            Text("Country:")
                                .foregroundColor(.secondary)
                            Text(country)
                        }
                        .onAppear {
                            hotelCity = cityName
                            hotelCountry = country
                        }
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

                Section("Photos") {
                    PhotoPickerButton(photos: $selectedPhotos, maxPhotos: 10)
                    PhotoGridView(photos: $selectedPhotos)
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
                    .disabled(name.isEmpty || hotelCity.isEmpty || hotelCountry.isEmpty)
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty && newValue != name {
                    autocompleteService.searchHotels(query: newValue)
                } else if newValue.isEmpty {
                    autocompleteService.cancelSearch()
                }
            }
            .onAppear {
                if let cityName = cityName, let country = country {
                    hotelCity = cityName
                    hotelCountry = country
                }
            }
        }
    }
    
    private func saveHotel() {
        // Check if city exists, if not create it
        let cityExists = allCities.contains { existingCity in
            existingCity.name.lowercased() == hotelCity.lowercased() &&
            existingCity.country.lowercased() == hotelCountry.lowercased()
        }
        
        if !cityExists {
            // Create a new city for this hotel
            let newCity = City(
                name: hotelCity,
                country: hotelCountry,
                visitDate: checkInDate, // Use hotel check-in date as visit date
                highlights: "",
                latitude: latitude,
                longitude: longitude
            )
            modelContext.insert(newCity)
        }
        
        let hotel = Hotel(
            name: name,
            city: hotelCity,
            country: hotelCountry,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            starRating: starRating,
            amenities: amenities,
            notes: notes,
            favoriteAspects: favoriteAspects,
            latitude: latitude,
            longitude: longitude
        )

        // Save photos and get filenames
        for photo in selectedPhotos {
            if let filename = PhotoManager.shared.savePhoto(image: photo, for: hotel.id, type: .hotel) {
                hotel.photoFilenames.append(filename)
            }
        }

        modelContext.insert(hotel)
        
        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save hotel: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [Trip.self, Hotel.self, City.self], inMemory: true)
}
