//
//  City.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import SwiftData

@Model
final class City: Identifiable {
    var id: UUID
    var name: String
    var country: String
    var visitDate: Date
    var highlights: String
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    // Photo support
    var photoFilenames: [String]

    // Rating support (stored as encoded Data)
    var ratingsData: Data?

    init(
        name: String,
        country: String,
        visitDate: Date,
        highlights: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.visitDate = visitDate
        self.highlights = highlights
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.photoFilenames = []
        self.ratingsData = nil
    }

    var locationString: String {
        "\(name), \(country)"
    }

    // Computed property for easy access to ratings
    var ratings: CityRating? {
        get {
            guard let data = ratingsData else { return nil }
            return try? JSONDecoder().decode(CityRating.self, from: data)
        }
        set {
            ratingsData = try? JSONEncoder().encode(newValue)
        }
    }
}




