//
//  City.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import Foundation
import SwiftData

@Model
final class City {
    var id: UUID
    var name: String
    var country: String
    var visitDate: Date
    var highlights: String
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    
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
    }
    
    var locationString: String {
        "\(name), \(country)"
    }
}



