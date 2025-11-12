//
//  CitiesListView.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import SwiftData
import MapKit

struct CitiesListView: View {
    @Query(sort: \City.visitDate, order: .reverse) private var cities: [City]
    @State private var searchText = ""
    @State private var showingAddCity = false
    
    var filteredCities: [City] {
        if searchText.isEmpty {
            return cities
        }
        return cities.filter { city in
            city.name.localizedCaseInsensitiveContains(searchText) ||
            city.country.localizedCaseInsensitiveContains(searchText) ||
            city.highlights.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedCities: [String: [City]] {
        Dictionary(grouping: filteredCities) { city in
            city.country
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredCities.isEmpty {
                    ContentUnavailableView(
                        "No Cities Yet",
                        systemImage: "mappin.circle",
                        description: Text("Start tracking your travels by adding cities you've visited.")
                    )
                } else {
                    ForEach(Array(groupedCities.keys.sorted()), id: \.self) { country in
                        Section(country) {
                            ForEach(groupedCities[country] ?? []) { city in
                                NavigationLink {
                                    CityDetailView(city: city)
                                } label: {
                                    CityRowView(city: city)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cities")
            .searchable(text: $searchText, prompt: "Search cities...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCity) {
                AddCityView()
            }
        }
    }
}

struct CityRowView: View {
    let city: City
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                Text(city.visitDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if !city.highlights.isEmpty {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

struct CityDetailView: View {
    let city: City
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(city.locationString)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Label(city.visitDate.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !city.highlights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlights")
                            .font(.headline)
                        Text(city.highlights)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if let lat = city.latitude, let lon = city.longitude {
                    CityMapView(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
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
        .alert("Delete City", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(city)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this city? This action cannot be undone.")
        }
    }
}

struct CityMapView: UIViewRepresentable {
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
    CitiesListView()
        .modelContainer(for: [City.self], inMemory: true)
}

