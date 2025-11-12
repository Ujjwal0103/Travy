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
    
    var filteredItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        if selectedFilter == .all || selectedFilter == .trips {
            items.append(contentsOf: trips.map { TimelineItem.trip($0) })
        }
        if selectedFilter == .all || selectedFilter == .hotels {
            items.append(contentsOf: hotels.map { TimelineItem.hotel($0) })
        }
        if selectedFilter == .all || selectedFilter == .cities {
            items.append(contentsOf: cities.map { TimelineItem.city($0) })
        }
        
        // Sort by date (most recent first)
        items.sort { item1, item2 in
            let date1 = item1.date
            let date2 = item2.date
            return date1 > date2
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.searchableText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
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
                    LazyVStack(spacing: 16) {
                        ForEach(filteredItems) { item in
                            TimelineItemView(item: item)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
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

enum TimelineItem: Identifiable {
    case trip(Trip)
    case hotel(Hotel)
    case city(City)
    
    var id: UUID {
        switch self {
        case .trip(let trip): return trip.id
        case .hotel(let hotel): return hotel.id
        case .city(let city): return city.id
        }
    }
    
    var date: Date {
        switch self {
        case .trip(let trip): return trip.startDate
        case .hotel(let hotel): return hotel.checkInDate
        case .city(let city): return city.visitDate
        }
    }
    
    var searchableText: String {
        switch self {
        case .trip(let trip):
            return "\(trip.city) \(trip.country) \(trip.notes) \(trip.travelTag)"
        case .hotel(let hotel):
            return "\(hotel.name) \(hotel.city) \(hotel.country) \(hotel.notes)"
        case .city(let city):
            return "\(city.name) \(city.country) \(city.highlights)"
        }
    }
}

struct TimelineItemView: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date indicator
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
            
            // Content card
            VStack(alignment: .leading, spacing: 8) {
                switch item {
                case .trip(let trip):
                    TripTimelineCard(trip: trip)
                case .hotel(let hotel):
                    HotelTimelineCard(hotel: hotel)
                case .city(let city):
                    CityTimelineCard(city: city)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var itemColor: Color {
        switch item {
        case .trip: return .blue
        case .hotel: return .purple
        case .city: return .green
        }
    }
}

struct TripTimelineCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text("Trip")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(trip.startDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(trip.locationString)
                .font(.headline)
            
            HStack {
                Text("\(trip.duration) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text(trip.travelTag)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !trip.notes.isEmpty {
                Text(trip.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct HotelTimelineCard: View {
    let hotel: Hotel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Hotel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(hotel.checkInDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(hotel.name)
                .font(.headline)
            
            Text(hotel.locationString)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(hotel.stayDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let rating = hotel.starRating {
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CityTimelineCard: View {
    let city: City
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
                Text("City")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(city.visitDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(city.locationString)
                .font(.headline)
            
            if !city.highlights.isEmpty {
                Text(city.highlights)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Trip.self, Hotel.self, City.self], inMemory: true)
}

