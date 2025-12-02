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
    var name: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var travelTag: String // "Business", "Vacation", "Conference", etc.
    var cities: [City]
    var hotels: [Hotel]
    var createdAt: Date
    
    init(
        name: String,
        startDate: Date,
        endDate: Date,
        notes: String = "",
        travelTag: String = "Vacation",
        cities: [City] = [],
        hotels: [Hotel] = []
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.travelTag = travelTag
        self.cities = cities
        self.hotels = hotels
        self.createdAt = Date()
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var locationString: String {
        if cities.isEmpty {
            return "No cities"
        } else if cities.count == 1 {
            return cities[0].locationString
        } else {
            return "\(cities.count) cities"
        }
    }
}






