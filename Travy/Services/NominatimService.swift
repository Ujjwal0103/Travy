//
//  NominatimService.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import CoreLocation

struct NominatimGeocodeResult: Codable {
    let placeId: Int64
    let lat: String
    let lon: String
    let displayName: String
    let address: AddressDetails?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case lat
        case lon
        case displayName = "display_name"
        case address
    }
    
    struct AddressDetails: Codable {
        let city: String?
        let town: String?
        let village: String?
        let municipality: String?
        let county: String?
        let state: String?
        let country: String?
        let countryCode: String?
        
        enum CodingKeys: String, CodingKey {
            case city
            case town
            case village
            case municipality
            case county
            case state
            case country
            case countryCode = "country_code"
        }
        
        var cityName: String? {
            city ?? town ?? village ?? municipality
        }
    }
}

class NominatimService {
    static let shared = NominatimService()
    
    private init() {}
    
    /// Geocode a city name and country to get latitude and longitude
    /// Uses Nominatim API search endpoint with q parameter
    func geocodeCity(name: String, country: String) async throws -> CLLocationCoordinate2D? {
        // Build query: "city name, country" - Nominatim accepts natural language queries
        let query = "\(name), \(country)"
        
        // Build Nominatim API URL with required parameters
        var components = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "addressdetails", value: "1"), // Get detailed address information
            URLQueryItem(name: "format", value: "json"),      // Required: get JSON response
            URLQueryItem(name: "limit", value: "1")           // Only need first result
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "NominatimService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Create request with proper headers (Nominatim requires User-Agent)
        var request = URLRequest(url: url)
        request.setValue("Travy iOS App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw NSError(domain: "NominatimService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        // Parse JSON response - API returns an array of results
        let results = try JSONDecoder().decode([NominatimGeocodeResult].self, from: data)
        
        // Take the first result as recommended (API returns multiple matching locations)
        guard let firstResult = results.first else {
            return nil
        }
        
        // Convert lat/lon strings to Double (API returns them as strings)
        guard let lat = Double(firstResult.lat),
              let lon = Double(firstResult.lon) else {
            throw NSError(domain: "NominatimService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid coordinates"])
        }
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

