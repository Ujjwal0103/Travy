//
//  TimelineView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @Query(sort: \Hotel.checkInDate, order: .reverse) private var hotels: [Hotel]
    @Query(sort: \City.visitDate, order: .reverse) private var cities: [City]
    
    @State private var searchText = ""
    @State private var selectedFilter: TimelineFilter = .all
    
    enum TimelineFilter: String, CaseIterable {
        case all = "All"
        case trips = "Trips"
        case hotels = "Hotels"
        case cities = "Cities"
    }
    
    // Group items hierarchically: trips contain cities, cities contain hotels
    var groupedTimelineItems: [GroupedTimelineItem] {
        var grouped: [GroupedTimelineItem] = []
        
        // Get all cities that are not part of trips
        let citiesInTrips = Set(trips.flatMap { $0.cities.map { $0.id } })
        let standaloneCities = cities.filter { !citiesInTrips.contains($0.id) }
        
        // Get all hotels grouped by city
        let hotelsByCity = Dictionary(grouping: hotels) { hotel in
            "\(hotel.city.lowercased()), \(hotel.country.lowercased())"
        }
        
        // Add trips with their cities
        if selectedFilter == .all || selectedFilter == .trips {
            for trip in trips.sorted(by: { $0.startDate > $1.startDate }) {
                var tripCities: [GroupedTimelineItem] = []
                
                // Add cities in this trip
                for city in trip.cities.sorted(by: { $0.visitDate > $1.visitDate }) {
                    let cityKey = "\(city.name.lowercased()), \(city.country.lowercased())"
                    let cityHotels = hotelsByCity[cityKey]?.sorted(by: { $0.checkInDate > $1.checkInDate }) ?? []
                    
                    var hotelItems: [GroupedTimelineItem] = []
                    if selectedFilter == .all || selectedFilter == .hotels {
                        for hotel in cityHotels {
                            if searchText.isEmpty || hotelMatchesSearch(hotel) {
                                hotelItems.append(.hotel(hotel))
                            }
                        }
                    }
                    
                    // Show city if: all filter, cities filter, OR if it has hotels (for hotels filter)
                    if selectedFilter == .all || selectedFilter == .cities || selectedFilter == .hotels && !hotelItems.isEmpty {
                        if searchText.isEmpty || cityMatchesSearch(city) || !hotelItems.isEmpty {
                            tripCities.append(.city(city, hotels: hotelItems))
                        }
                    }
                }
                
                // Only show trip if it has cities or if not filtering by hotels
                if selectedFilter != .hotels || !tripCities.isEmpty {
                    if searchText.isEmpty || tripMatchesSearch(trip) {
                        grouped.append(.trip(trip, cities: tripCities))
                    }
                }
            }
        }
        
        // Add standalone cities (not in trips)
        // Show cities if: all filter, cities filter, OR if they have hotels (for hotels filter)
        if selectedFilter == .all || selectedFilter == .cities || selectedFilter == .hotels {
            for city in standaloneCities.sorted(by: { $0.visitDate > $1.visitDate }) {
                let cityKey = "\(city.name.lowercased()), \(city.country.lowercased())"
                let cityHotels = hotelsByCity[cityKey]?.sorted(by: { $0.checkInDate > $1.checkInDate }) ?? []
                
                var hotelItems: [GroupedTimelineItem] = []
                if selectedFilter == .all || selectedFilter == .hotels {
                    for hotel in cityHotels {
                        if searchText.isEmpty || hotelMatchesSearch(hotel) {
                            hotelItems.append(.hotel(hotel))
                        }
                    }
                }
                
                // Show city if: all filter, cities filter, OR if it has hotels (for hotels filter)
                if selectedFilter == .all || selectedFilter == .cities || (selectedFilter == .hotels && !hotelItems.isEmpty) {
                    if searchText.isEmpty || cityMatchesSearch(city) || !hotelItems.isEmpty {
                        grouped.append(.city(city, hotels: hotelItems))
                    }
                }
            }
        }
        
        // Add standalone hotels (not in any city we know about)
        if selectedFilter == .all || selectedFilter == .hotels {
            let allCityKeys = Set(cities.map { "\($0.name.lowercased()), \($0.country.lowercased())" })
            let allTripCityKeys = Set(trips.flatMap { $0.cities.map { "\($0.name.lowercased()), \($0.country.lowercased())" } })
            let knownCityKeys = allCityKeys.union(allTripCityKeys)
            
            for hotel in hotels.sorted(by: { $0.checkInDate > $1.checkInDate }) {
                let hotelKey = "\(hotel.city.lowercased()), \(hotel.country.lowercased())"
                if !knownCityKeys.contains(hotelKey) {
                    if searchText.isEmpty || hotelMatchesSearch(hotel) {
                        grouped.append(.hotel(hotel))
                    }
                }
            }
        }
        
        return grouped
    }
    
    private func tripMatchesSearch(_ trip: Trip) -> Bool {
        let citiesText = trip.cities.map { "\($0.name) \($0.country)" }.joined(separator: " ")
        let searchable = "\(trip.name) \(citiesText) \(trip.notes) \(trip.travelTag)"
        return searchable.localizedCaseInsensitiveContains(searchText)
    }
    
    private func cityMatchesSearch(_ city: City) -> Bool {
        let searchable = "\(city.name) \(city.country) \(city.highlights)"
        return searchable.localizedCaseInsensitiveContains(searchText)
    }
    
    private func hotelMatchesSearch(_ hotel: Hotel) -> Bool {
        let searchable = "\(hotel.name) \(hotel.city) \(hotel.country) \(hotel.notes)"
        return searchable.localizedCaseInsensitiveContains(searchText)
    }
    
    @State private var showingAddTrip = false
    @State private var showingAddHotel = false
    @State private var showingAddCity = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search trips, hotels, cities...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TimelineFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Timeline
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(groupedTimelineItems) { item in
                            GroupedTimelineItemView(item: item)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddTrip = true
                        } label: {
                            Label("Add Trip", systemImage: "airplane")
                        }
                        Button {
                            showingAddHotel = true
                        } label: {
                            Label("Add Hotel", systemImage: "bed.double")
                        }
                        Button {
                            showingAddCity = true
                        } label: {
                            Label("Add City", systemImage: "mappin.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
            .sheet(isPresented: $showingAddHotel) {
                AddHotelView()
            }
            .sheet(isPresented: $showingAddCity) {
                AddCityView()
            }
        }
    }
}

// Hierarchical timeline items
enum GroupedTimelineItem: Identifiable {
    case trip(Trip, cities: [GroupedTimelineItem])
    case city(City, hotels: [GroupedTimelineItem])
    case hotel(Hotel)
    
    var id: UUID {
        switch self {
        case .trip(let trip, _): return trip.id
        case .city(let city, _): return city.id
        case .hotel(let hotel): return hotel.id
        }
    }
    
    var date: Date {
        switch self {
        case .trip(let trip, _): return trip.startDate
        case .city(let city, _): return city.visitDate
        case .hotel(let hotel): return hotel.checkInDate
        }
    }
}

struct GroupedTimelineItemView: View {
    let item: GroupedTimelineItem
    let indentLevel: Int
    
    init(item: GroupedTimelineItem, indentLevel: Int = 0) {
        self.item = item
        self.indentLevel = indentLevel
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date indicator (only show for top-level items)
            if indentLevel == 0 {
                VStack {
                    Circle()
                        .fill(itemColor)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 20)
            } else {
                // Spacer for indented items
                Spacer()
                    .frame(width: 20)
            }
            
            // Content card with nested items
            VStack(alignment: .leading, spacing: 4) {
                switch item {
                case .trip(let trip, let cities):
                    TripTimelineCard(trip: trip)
                    if !cities.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(cities) { cityItem in
                                GroupedTimelineItemView(item: cityItem, indentLevel: indentLevel + 1)
                            }
                        }
                    }
                case .city(let city, let hotels):
                    CityTimelineCard(city: city)
                    if !hotels.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(hotels) { hotelItem in
                                GroupedTimelineItemView(item: hotelItem, indentLevel: indentLevel + 1)
                            }
                        }
                    }
                case .hotel(let hotel):
                    HotelTimelineCard(hotel: hotel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, indentLevel > 0 ? 4 : 0)
        }
    }
    
    var itemColor: Color {
        switch item {
        case .trip: return .blue
        case .city: return .green
        case .hotel: return .purple
        }
    }
}

struct TripTimelineCard: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "airplane")
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(trip.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if !trip.cities.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(trip.locationString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(trip.startDate.formatted(.dateTime.month().day().year()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    Text("\(trip.duration) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    Text(trip.travelTag)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct HotelTimelineCard: View {
    let hotel: Hotel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bed.double.fill")
                .foregroundColor(.purple)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(hotel.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(hotel.locationString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Text(hotel.checkInDate.formatted(.dateTime.month().day().year()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    Text(hotel.stayDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if let rating = hotel.starRating {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        HStack(spacing: 1) {
                            ForEach(0..<rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 8))
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CityTimelineCard: View {
    let city: City

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(city.locationString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let ratings = city.ratings, let avgRating = ratings.averageRating {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 8))
                            Text(String(format: "%.1f", avgRating))
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    Text(city.visitDate.formatted(.dateTime.month().day().year()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if !city.highlights.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        Text(city.highlights)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Trip.self, Hotel.self, City.self], inMemory: true)
}

