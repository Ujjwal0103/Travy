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

// Nominatim API Response structures
struct NominatimResult: Codable {
    let lat: String
    let lon: String
    let displayName: String
    let type: String
    let addressType: String?
    let address: NominatimAddress?

    enum CodingKeys: String, CodingKey {
        case lat, lon, type
        case displayName = "display_name"
        case addressType = "addresstype"
        case address
    }
}

struct NominatimAddress: Codable {
    let city: String?
    let town: String?
    let village: String?
    let country: String?
    let hotel: String?
    let tourism: String?
}

class AutocompleteService: ObservableObject {
    @Published var suggestions: [AutocompleteResult] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 500_000_000 // 500ms in nanoseconds
    private let minQueryLength = 3 // Don't search until at least 3 characters

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    func searchCities(query: String) {
        // Clear suggestions if query is too short
        guard query.count >= minQueryLength else {
            suggestions = []
            isSearching = false
            searchTask?.cancel()
            return
        }

        searchTask?.cancel()
        isSearching = true

        searchTask = Task {
            // Debounce: wait before making the request
            try? await Task.sleep(nanoseconds: debounceDelay)

            // Check if cancelled during debounce
            guard !Task.isCancelled else {
                await MainActor.run { self.isSearching = false }
                return
            }

            do {
                let results = try await performNominatimSearch(query: query, filterType: .city)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.suggestions = Array(results.prefix(10))
                    self.isSearching = false
                }
            } catch is CancellationError {
                // Ignore cancellation errors - they're expected when user types quickly
                await MainActor.run { self.isSearching = false }
            } catch {
                print("City search error: \(error.localizedDescription)")
                await MainActor.run {
                    self.suggestions = []
                    self.isSearching = false
                }
            }
        }
    }
    
    func searchHotels(query: String) {
        // Clear suggestions if query is too short
        guard query.count >= minQueryLength else {
            suggestions = []
            isSearching = false
            searchTask?.cancel()
            return
        }

        searchTask?.cancel()
        isSearching = true

        searchTask = Task {
            // Debounce: wait before making the request
            try? await Task.sleep(nanoseconds: debounceDelay)

            // Check if cancelled during debounce
            guard !Task.isCancelled else {
                await MainActor.run { self.isSearching = false }
                return
            }

            do {
                let results = try await performNominatimSearch(query: query, filterType: .hotel)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.suggestions = Array(results.prefix(10))
                    self.isSearching = false
                }
            } catch is CancellationError {
                // Ignore cancellation errors - they're expected when user types quickly
                await MainActor.run { self.isSearching = false }
            } catch {
                print("Hotel search error: \(error.localizedDescription)")
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

    // MARK: - Private Helper Methods

    private func performNominatimSearch(query: String, filterType: AutocompleteResult.ResultType) async throws -> [AutocompleteResult] {
        // Build the search query - for hotels, append "hotel" to help Nominatim find relevant results
        let searchQuery = filterType == .hotel ? "\(query) hotel" : query

        var urlComponents = URLComponents(string: "https://nominatim.openstreetmap.org/search")

        let queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "limit", value: "15")
        ]

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            print("❌ Failed to create URL")
            throw URLError(.badURL)
        }

        print("🌐 Nominatim URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("TravyApp/1.0 (iOS; Travel Logging App)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://github.com/travy-app", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 10

        // Check if task was cancelled before making request
        try Task.checkCancellation()

        let (data, response) = try await session.data(for: request)

        // Check again after network call
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw URLError(.badServerResponse)
        }

        print("📡 HTTP Status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Nominatim HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }

        // Debug: print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Response length: \(responseString.count) characters")
            print("First 200 chars: \(String(responseString.prefix(200)))")
        }

        let nominatimResults = try JSONDecoder().decode([NominatimResult].self, from: data)
        print("✅ Decoded \(nominatimResults.count) results from Nominatim")

        let parsedResults = parseNominatimResults(nominatimResults, preferredType: filterType)
        print("✅ Parsed to \(parsedResults.count) autocomplete results")

        return parsedResults
    }

    private func parseNominatimResults(_ results: [NominatimResult], preferredType: AutocompleteResult.ResultType) -> [AutocompleteResult] {
        return results.compactMap { result in
            guard let latitude = Double(result.lat),
                  let longitude = Double(result.lon),
                  latitude.isFinite && longitude.isFinite else {
                return nil
            }

            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            // Extract title and subtitle
            var title = ""
            var subtitle = ""
            var resultType = preferredType

            // Determine result type based on Nominatim response
            let displayComponents = result.displayName.components(separatedBy: ", ")

            if let address = result.address {
                // Check if it's a hotel
                let isHotel = address.hotel != nil ||
                              address.tourism == "hotel" ||
                              result.type == "hotel" ||
                              result.type == "tourism" ||
                              result.displayName.lowercased().contains("hotel")

                if isHotel && preferredType == .hotel {
                    resultType = .hotel
                    // Use hotel name from address or first component of display name
                    title = address.hotel ?? displayComponents.first ?? result.displayName

                    // Build subtitle with city and country
                    var parts: [String] = []
                    if let city = address.city ?? address.town ?? address.village {
                        parts.append(city)
                    }
                    if let country = address.country {
                        parts.append(country)
                    }
                    subtitle = parts.isEmpty ? result.displayName : parts.joined(separator: ", ")
                } else {
                    // It's a city or place
                    title = address.city ?? address.town ?? address.village ?? displayComponents.first ?? result.displayName

                    if let city = address.city ?? address.town ?? address.village {
                        resultType = .city
                        subtitle = address.country ?? ""
                    } else {
                        resultType = .place
                        // Build subtitle from remaining components
                        subtitle = displayComponents.count > 1 ? displayComponents.dropFirst().joined(separator: ", ") : ""
                    }
                }
            } else {
                // No address details, use display_name
                if displayComponents.count >= 2 {
                    title = displayComponents[0]
                    subtitle = displayComponents.dropFirst().joined(separator: ", ")
                } else {
                    title = result.displayName
                    subtitle = ""
                }
                resultType = .place
            }

            // Filter based on preferred type for better results
            if preferredType == .hotel && resultType != .hotel {
                // When searching for hotels, skip non-hotel results
                return nil
            }

            return AutocompleteResult(
                title: title,
                subtitle: subtitle,
                coordinate: coordinate,
                type: resultType
            )
        }
    }
}

