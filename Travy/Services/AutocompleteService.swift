//
//  AutocompleteService.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import MapKit
import Combine

struct AutocompleteResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let type: ResultType
    
    enum ResultType: Hashable {
        case city
        case hotel
        case place
    }
    
    // Custom Hashable conformance to handle CLLocationCoordinate2D
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(type)
    }
    
    static func == (lhs: AutocompleteResult, rhs: AutocompleteResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.type == rhs.type
    }
}

class AutocompleteService: ObservableObject {
    @Published var suggestions: [AutocompleteResult] = []
    @Published var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    
    func searchCities(query: String) {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        searchTask?.cancel()
        isSearching = true
        
        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                let results = response.mapItems.compactMap { item -> AutocompleteResult? in
                    guard let coordinate = item.placemark.location?.coordinate else { return nil }
                    
                    let title = item.name ?? item.placemark.name ?? ""
                    var subtitle = ""
                    
                    // Build subtitle from address components
                    if let city = item.placemark.locality {
                        subtitle = city
                        if let country = item.placemark.country {
                            subtitle += ", \(country)"
                        }
                    } else if let country = item.placemark.country {
                        subtitle = country
                    }
                    
                    // Determine if it's a hotel or city
                    let type: AutocompleteResult.ResultType
                    if item.pointOfInterestCategory == .hotel || 
                       item.name?.lowercased().contains("hotel") == true ||
                       item.name?.lowercased().contains("resort") == true {
                        type = .hotel
                    } else if item.placemark.locality != nil {
                        type = .city
                    } else {
                        type = .place
                    }
                    
                    return AutocompleteResult(
                        title: title,
                        subtitle: subtitle,
                        coordinate: coordinate,
                        type: type
                    )
                }
                
                await MainActor.run {
                    self.suggestions = Array(results.prefix(10)) // Limit to 10 results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.suggestions = []
                    self.isSearching = false
                }
            }
        }
    }
    
    func searchHotels(query: String) {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        searchTask?.cancel()
        isSearching = true
        
        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(query) hotel"
            request.resultTypes = [.pointOfInterest]
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.hotel, .restaurant])
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                let results = response.mapItems.compactMap { item -> AutocompleteResult? in
                    guard let coordinate = item.placemark.location?.coordinate else { return nil }
                    
                    let title = item.name ?? ""
                    var subtitle = ""
                    
                    if let city = item.placemark.locality {
                        subtitle = city
                        if let country = item.placemark.country {
                            subtitle += ", \(country)"
                        }
                    } else if let country = item.placemark.country {
                        subtitle = country
                    }
                    
                    return AutocompleteResult(
                        title: title,
                        subtitle: subtitle,
                        coordinate: coordinate,
                        type: .hotel
                    )
                }
                
                await MainActor.run {
                    self.suggestions = Array(results.prefix(10))
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.suggestions = []
                    self.isSearching = false
                }
            }
        }
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        suggestions = []
        isSearching = false
    }
}

