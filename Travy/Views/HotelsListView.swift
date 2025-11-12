//
//  HotelsListView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct HotelsListView: View {
    @Query(sort: \Hotel.checkInDate, order: .reverse) private var hotels: [Hotel]
    @State private var searchText = ""
    @State private var showingAddHotel = false
    
    var filteredHotels: [Hotel] {
        if searchText.isEmpty {
            return hotels
        }
        return hotels.filter { hotel in
            hotel.name.localizedCaseInsensitiveContains(searchText) ||
            hotel.city.localizedCaseInsensitiveContains(searchText) ||
            hotel.country.localizedCaseInsensitiveContains(searchText) ||
            hotel.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedHotels: [String: [Hotel]] {
        Dictionary(grouping: filteredHotels) { hotel in
            hotel.country
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredHotels.isEmpty {
                    ContentUnavailableView(
                        "No Hotels Yet",
                        systemImage: "bed.double",
                        description: Text("Start tracking your stays by adding hotels you've visited.")
                    )
                } else {
                    ForEach(Array(groupedHotels.keys.sorted()), id: \.self) { country in
                        Section(country) {
                            ForEach(groupedHotels[country] ?? []) { hotel in
                                NavigationLink {
                                    HotelDetailView(hotel: hotel)
                                } label: {
                                    HotelRowView(hotel: hotel)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Hotels")
            .searchable(text: $searchText, prompt: "Search hotels...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHotel = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHotel) {
                AddHotelView()
            }
        }
    }
}

struct HotelRowView: View {
    let hotel: Hotel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.headline)
                Text(hotel.locationString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(hotel.stayDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let rating = hotel.starRating {
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
}

struct HotelDetailView: View {
    let hotel: Hotel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(hotel.name)
                        .font(.largeTitle)
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
                        HStack(spacing: 2) {
                            ForEach(0..<rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
                
                if !hotel.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                        Text(hotel.amenities)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if !hotel.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(hotel.notes)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if !hotel.favoriteAspects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite Aspects")
                            .font(.headline)
                        Text(hotel.favoriteAspects)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if let lat = hotel.latitude, let lon = hotel.longitude {
                    HotelMapView(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .frame(height: 200)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Hotel", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(hotel)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this hotel? This action cannot be undone.")
        }
    }
}

struct HotelMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .standard
        mapView.isUserInteractionEnabled = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        mapView.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}

#Preview {
    HotelsListView()
        .modelContainer(for: [Hotel.self], inMemory: true)
}

