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
    @Query(sort: \City.visitDate, order: .forward) private var cities: [City]
    
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            distance: 20000000, // Far enough to show the globe
            heading: 0,
            pitch: 0
        )
    )
    @State private var selectedCity: City?
    @State private var selectedHotel: Hotel?
    @State private var highlightedCoordinate: CLLocationCoordinate2D?
    @State private var currentDistance: Double = 20000000
    @State private var currentCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var currentHeading: Double = 0

    // Zoom levels
    private let maxDistance: Double = 40000000 // Maximum zoom out (full globe)
    private let minDistance: Double = 100000   // Maximum zoom in (detailed map)

    // Computed property to get cities with coordinates, sorted by visit date
    var citiesWithCoordinates: [(city: City, coordinate: CLLocationCoordinate2D)] {
        cities.compactMap { city in
            guard let lat = city.latitude, let lon = city.longitude,
                  lat.isFinite && lon.isFinite,
                  lat >= -90 && lat <= 90,
                  lon >= -180 && lon <= 180 else { return nil }
            return (city, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    // Computed property to get hotels with coordinates
    var hotelsWithCoordinates: [(hotel: Hotel, coordinate: CLLocationCoordinate2D)] {
        hotels.compactMap { hotel in
            guard let lat = hotel.latitude, let lon = hotel.longitude,
                  lat.isFinite && lon.isFinite,
                  lat >= -90 && lat <= 90,
                  lon >= -180 && lon <= 180 else { return nil }
            return (hotel, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
    
    // Generate connection paths between consecutive cities
    var cityConnections: [CityConnection] {
        var connections: [CityConnection] = []
        let sortedCities = citiesWithCoordinates
        
        for i in 0..<sortedCities.count - 1 {
            let from = sortedCities[i]
            let to = sortedCities[i + 1]
            
            // Validate coordinates before creating connection
            let fromCoord = from.coordinate
            let toCoord = to.coordinate
            
            if fromCoord.latitude.isFinite && fromCoord.longitude.isFinite &&
               toCoord.latitude.isFinite && toCoord.longitude.isFinite {
                connections.append(CityConnection(from: fromCoord, to: toCoord))
            }
        }
        
        return connections
    }
    
    // Helper struct for city connections
    struct CityConnection: Identifiable {
        let id = UUID()
        let from: CLLocationCoordinate2D
        let to: CLLocationCoordinate2D
        let path: [CLLocationCoordinate2D] // Stored property to avoid recalculation
        
        init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
            self.from = from
            self.to = to
            // Calculate path once during initialization
            let calculatedPath = MapView.generateGreatCirclePath(from: from, to: to)
            self.path = calculatedPath.count >= 2 ? calculatedPath : [from, to]
        }
    }
    
    // Generate great circle path between two coordinates
    static func generateGreatCirclePath(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        // Validate coordinates
        guard from.latitude.isFinite && from.longitude.isFinite &&
              to.latitude.isFinite && to.longitude.isFinite else {
            return [from, to]
        }
        
        // Check if points are the same
        let threshold: Double = 0.001
        if abs(from.latitude - to.latitude) < threshold && 
           abs(from.longitude - to.longitude) < threshold {
            return [from, to]
        }
        
        let steps = 30 // Number of intermediate points (reduced for performance)
        var path: [CLLocationCoordinate2D] = []
        
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        // Calculate angular distance with bounds checking
        let cosD = sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)
        let clampedCosD = max(-1.0, min(1.0, cosD)) // Clamp to [-1, 1] for acos
        let d = acos(clampedCosD)
        
        // Handle case where points are the same or very close
        guard d > 0.001 && d.isFinite else {
            return [from, to]
        }
        
        // Avoid division by zero
        let sinD = sin(d)
        guard abs(sinD) > 0.0001 else {
            return [from, to]
        }
        
        for i in 0...steps {
            let f = Double(i) / Double(steps)
            let a = sin((1 - f) * d) / sinD
            let b = sin(f * d) / sinD
            
            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)
            
            let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            
            // Validate calculated coordinates
            if lat.isFinite && lon.isFinite {
                path.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        // Ensure we have at least 2 points for MapPolyline
        if path.count < 2 {
            return [from, to]
        }
        
        return path
    }
    
    func zoomToCity(_ city: City) {
        guard let lat = city.latitude, let lon = city.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        withAnimation(.easeInOut(duration: 0.8)) {
            currentDistance = 2000000
            currentCenter = coordinate
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: currentDistance,
                    heading: currentHeading,
                    pitch: 0
                )
            )
            highlightedCoordinate = coordinate
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            highlightedCoordinate = nil
        }
    }

    func zoomToHotel(_ hotel: Hotel) {
        guard let lat = hotel.latitude, let lon = hotel.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        withAnimation(.easeInOut(duration: 0.8)) {
            currentDistance = 2000000
            currentCenter = coordinate
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: currentDistance,
                    heading: currentHeading,
                    pitch: 0
                )
            )
            highlightedCoordinate = coordinate
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            highlightedCoordinate = nil
        }
    }

    func zoomIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDistance = max(minDistance, currentDistance * 0.5)
            updateCamera()
        }
    }

    func zoomOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDistance = min(maxDistance, currentDistance * 2.0)
            updateCamera()
        }
    }

    func updateCamera() {
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: currentCenter,
                distance: currentDistance,
                heading: currentHeading,
                pitch: 0
            )
        )
    }

    func resetToGlobe() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentDistance = 20000000
            currentCenter = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            currentHeading = 0
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: currentCenter,
                    distance: currentDistance,
                    heading: currentHeading,
                    pitch: 0
                )
            )
        }
    }

    var isGlobeView: Bool {
        currentDistance > 5000000 // Switch to map view when closer than 5M meters
    }
    
    func isCoordinateHighlighted(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let highlighted = highlightedCoordinate else { return false }
        let threshold: Double = 0.001
        return abs(highlighted.latitude - coordinate.latitude) < threshold &&
               abs(highlighted.longitude - coordinate.longitude) < threshold
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if citiesWithCoordinates.isEmpty {
                    // Show empty state
                    VStack {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No cities yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Add cities to see them on the globe")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ZStack {
                        Map(position: $cameraPosition, interactionModes: [.all]) {
                            // Draw connection lines between cities
                            ForEach(cityConnections) { connection in
                                MapPolyline(coordinates: connection.path)
                                    .stroke(.blue.opacity(0.7), lineWidth: 2.5)
                            }

                            // Add pins for each city
                            ForEach(citiesWithCoordinates, id: \.city.id) { cityData in
                                Annotation("", coordinate: cityData.coordinate) {
                                    CityPinView(
                                        city: cityData.city,
                                        isHighlighted: isCoordinateHighlighted(cityData.coordinate)
                                    )
                                    .onTapGesture {
                                        selectedCity = cityData.city
                                        zoomToCity(cityData.city)
                                    }
                                }
                            }

                            // Add pins for each hotel
                            ForEach(hotelsWithCoordinates, id: \.hotel.id) { hotelData in
                                Annotation("", coordinate: hotelData.coordinate) {
                                    HotelPinView(
                                        hotel: hotelData.hotel,
                                        isHighlighted: isCoordinateHighlighted(hotelData.coordinate)
                                    )
                                    .onTapGesture {
                                        selectedHotel = hotelData.hotel
                                        zoomToHotel(hotelData.hotel)
                                    }
                                }
                            }
                        }
                        .mapStyle(isGlobeView ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
                        .mapControls {
                            MapCompass()
                            MapPitchToggle()
                        }

                        // Floating zoom controls
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ZoomButton(icon: "plus", action: zoomIn)
                                    ZoomButton(icon: "minus", action: zoomOut)
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedCity) { city in
                CityDetailSheet(city: city) {
                    zoomToCity(city)
                }
            }
            .sheet(item: $selectedHotel) { hotel in
                HotelDetailSheet(hotel: hotel) {
                    zoomToHotel(hotel)
                }
            }
            .navigationTitle("Travel Globe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        resetToGlobe()
                    } label: {
                        Image(systemName: "globe")
                    }
                }
            }
        }
    }
}

struct CityPinView: View {
    let city: City
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            // Outer glow for highlighted pins
            if isHighlighted {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .blur(radius: 4)
            }

            // Main pin circle
            Circle()
                .fill(Color.red)
                .frame(width: 16, height: 16)

            // Inner white circle
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
        }
        .shadow(radius: isHighlighted ? 8 : 4)
        .scaleEffect(isHighlighted ? 1.5 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHighlighted)
    }
}

struct HotelPinView: View {
    let hotel: Hotel
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            // Outer glow for highlighted pins
            if isHighlighted {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .blur(radius: 4)
            }

            // Main pin circle
            Circle()
                .fill(Color.purple)
                .frame(width: 14, height: 14)

            // Hotel icon
            Image(systemName: "bed.double.fill")
                .font(.system(size: 6))
                .foregroundColor(.white)
        }
        .shadow(radius: isHighlighted ? 6 : 3)
        .scaleEffect(isHighlighted ? 1.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHighlighted)
    }
}

struct CityDetailSheet: View {
    let city: City
    let onShowOnMap: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                        CityDetailCard(city: city)

                    Button {
                        onShowOnMap()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Show on Globe")
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
            .navigationTitle("City Details")
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

struct HotelDetailSheet: View {
    let hotel: Hotel
    let onShowOnMap: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HotelDetailCard(hotel: hotel)

                    Button {
                        onShowOnMap()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Show on Globe")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Hotel Details")
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

// Floating zoom button component
struct ZoomButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
        }
    }
}

#Preview {
    MapView()
}

