//
//  Hotel.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import SwiftData

@Model
final class Hotel {
    var id: UUID
    var name: String
    var city: String
    var country: String
    var checkInDate: Date
    var checkOutDate: Date
    var starRating: Int?
    var amenities: String
    var notes: String
    var favoriteAspects: String
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    
    init(
        name: String,
        city: String,
        country: String,
        checkInDate: Date,
        checkOutDate: Date,
        starRating: Int? = nil,
        amenities: String = "",
        notes: String = "",
        favoriteAspects: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.city = city
        self.country = country
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        self.starRating = starRating
        self.amenities = amenities
        self.notes = notes
        self.favoriteAspects = favoriteAspects
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
    
    var nights: Int {
        Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0
    }
    
    var locationString: String {
        "\(city), \(country)"
    }
    
    var stayDescription: String {
        "\(nights) night\(nights == 1 ? "" : "s") — \(city), \(checkInDate.formatted(.dateTime.year()))"
    }
}



