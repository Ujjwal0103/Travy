//
//  MapView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct MapView: View {
    @Query private var trips: [Trip]
    @Query private var hotels: [Hotel]
    @Query private var cities: [City]
    
    @State private var viewMode: ViewMode = .all
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedItem: MapItem?
    @State private var highlightedCoordinate: CLLocationCoordinate2D?
    @State private var showingAddTrip = false
    @State private var showingAddHotel = false
    @State private var showingAddCity = false
    
    enum ViewMode: String, CaseIterable {
        case all = "All"
        case cities = "Cities"
        case hotels = "Hotels"
        case trips = "Trips"
    }
    
    enum MapItem: Identifiable {
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
        
        var coordinate: CLLocationCoordinate2D? {
            switch self {
            case .trip(let trip):
                if let lat = trip.latitude, let lon = trip.longitude {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            case .hotel(let hotel):
                if let lat = hotel.latitude, let lon = hotel.longitude {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            case .city(let city):
                if let lat = city.latitude, let lon = city.longitude {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
            return nil
        }
    }
    
    var visibleItems: [MapItem] {
        var items: [MapItem] = []
        
        switch viewMode {
        case .all:
            items.append(contentsOf: trips.map { MapItem.trip($0) })
            items.append(contentsOf: hotels.map { MapItem.hotel($0) })
            items.append(contentsOf: cities.map { MapItem.city($0) })
        case .cities:
            items.append(contentsOf: cities.map { MapItem.city($0) })
        case .hotels:
            items.append(contentsOf: hotels.map { MapItem.hotel($0) })
        case .trips:
            items.append(contentsOf: trips.map { MapItem.trip($0) })
        }
        
        return items.filter { $0.coordinate != nil }
    }
    
    func visitCount(for item: MapItem) -> Int {
        switch item {
        case .city(let city):
            return cities.filter { $0.name == city.name && $0.country == city.country }.count
        case .hotel(let hotel):
            return hotels.filter { $0.name == hotel.name && $0.city == hotel.city && $0.country == hotel.country }.count
        case .trip:
            return 1
        }
    }
    
    func zoomToCoordinate(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: 5000,
                    heading: 0,
                    pitch: 0
                )
            )
            highlightedCoordinate = coordinate
        }
        
        // Clear highlight after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            highlightedCoordinate = nil
        }
    }
    
    func isCoordinateHighlighted(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let highlighted = highlightedCoordinate else { return false }
        // Use a small threshold for coordinate comparison (approximately 100 meters)
        let threshold: Double = 0.001
        return abs(highlighted.latitude - coordinate.latitude) < threshold &&
               abs(highlighted.longitude - coordinate.longitude) < threshold
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Map(position: $cameraPosition) {
                    ForEach(visibleItems) { item in
                        if let coordinate = item.coordinate {
                            Annotation("", coordinate: coordinate) {
                                MapPinView(
                                    item: item,
                                    visitCount: visitCount(for: item),
                                    isHighlighted: isCoordinateHighlighted(coordinate)
                                )
                                .onTapGesture {
                                    selectedItem = item
                                    if let coord = item.coordinate {
                                        zoomToCoordinate(coord)
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .sheet(item: $selectedItem) { item in
                    MapItemDetailView(item: item) {
                        if let coord = item.coordinate {
                            zoomToCoordinate(coord)
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
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

struct MapPinView: View {
    let item: MapView.MapItem
    let visitCount: Int
    let isHighlighted: Bool
    
    var body: some View {
        ZStack {
            // Outer glow for highlighted pins
            if isHighlighted {
                Circle()
                    .fill(pinColor.opacity(0.3))
                    .frame(width: baseSize * 2.5, height: baseSize * 2.5)
                    .blur(radius: 4)
            }
            
            // Main pin circle with size based on visit count
            Circle()
                .fill(pinColor)
                .frame(width: pinSize, height: pinSize)
            
            // Inner white circle
            Circle()
                .fill(.white)
                .frame(width: pinSize * 0.4, height: pinSize * 0.4)
            
            // Visit count badge for multiple visits
            if visitCount > 1 {
                Text("\(visitCount)")
                    .font(.system(size: pinSize * 0.35, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .shadow(radius: isHighlighted ? 8 : 4)
        .scaleEffect(isHighlighted ? 1.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHighlighted)
    }
    
    var baseSize: CGFloat {
        switch item {
        case .trip: return 12
        case .hotel: return 14
        case .city: return 16
        }
    }
    
    var pinSize: CGFloat {
        // Scale pin size based on visit count (heat-map style)
        let multiplier: CGFloat
        if visitCount >= 5 {
            multiplier = 1.8
        } else if visitCount >= 3 {
            multiplier = 1.5
        } else if visitCount >= 2 {
            multiplier = 1.2
        } else {
            multiplier = 1.0
        }
        return baseSize * multiplier
    }
    
    var pinColor: Color {
        switch item {
        case .trip: return .blue
        case .hotel: return .purple
        case .city: return .green
        }
    }
}

struct MapItemDetailView: View {
    let item: MapView.MapItem
    let onShowOnMap: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch item {
                    case .trip(let trip):
                        TripDetailCard(trip: trip)
                    case .hotel(let hotel):
                        HotelDetailCard(hotel: hotel)
                    case .city(let city):
                        CityDetailCard(city: city)
                    }
                    
                    Button {
                        onShowOnMap()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Show on Map")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TripDetailCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trip.locationString)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(trip.startDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                Text("→")
                Label(trip.endDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if !trip.notes.isEmpty {
                Text(trip.notes)
                    .font(.body)
            }
            
            HStack {
                Text(trip.travelTag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Text("\(trip.duration) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HotelDetailCard: View {
    let hotel: Hotel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hotel.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(hotel.locationString)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(hotel.checkInDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                Text("→")
                Label(hotel.checkOutDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Text(hotel.stayDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let rating = hotel.starRating {
                HStack {
                    ForEach(0..<rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            
            if !hotel.notes.isEmpty {
                Text(hotel.notes)
                    .font(.body)
            }
            
            if !hotel.favoriteAspects.isEmpty {
                Text("Favorite: \(hotel.favoriteAspects)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CityDetailCard: View {
    let city: City
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(city.locationString)
                .font(.title2)
                .fontWeight(.bold)
            
            Label(city.visitDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !city.highlights.isEmpty {
                Text("Highlights: \(city.highlights)")
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    MapView()
}

