//
//  Trip.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var city: String
    var country: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var travelTag: String // "Business", "Vacation", "Conference", etc.
    var hotels: [Hotel]
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    
    init(
        city: String,
        country: String,
        startDate: Date,
        endDate: Date,
        notes: String = "",
        travelTag: String = "Vacation",
        hotels: [Hotel] = [],
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.city = city
        self.country = country
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.travelTag = travelTag
        self.hotels = hotels
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var locationString: String {
        "\(city), \(country)"
    }
}



