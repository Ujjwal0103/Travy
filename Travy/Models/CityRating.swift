//
//  CityRating.swift
//  Travy
//
//  Multi-category rating system for cities
//

import Foundation

struct CityRating: Codable, Hashable {
    var food: Int?           // 1-5 stars
    var culture: Int?        // 1-5 stars
    var safety: Int?         // 1-5 stars
    var affordability: Int?  // 1-5 stars
    var cleanliness: Int?    // 1-5 stars
    var nightlife: Int?      // 1-5 stars
    var scenery: Int?        // 1-5 stars
    var transportation: Int? // 1-5 stars

    // Computed property to get average rating
    var averageRating: Double? {
        let ratings = [food, culture, safety, affordability, cleanliness, nightlife, scenery, transportation].compactMap { $0 }

        guard !ratings.isEmpty else { return nil }

        let sum = ratings.reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }

    // Get all rated categories as tuples
    var ratedCategories: [(String, Int)] {
        var categories: [(String, Int)] = []

        if let food = food { categories.append(("Food", food)) }
        if let culture = culture { categories.append(("Culture", culture)) }
        if let safety = safety { categories.append(("Safety", safety)) }
        if let affordability = affordability { categories.append(("Affordability", affordability)) }
        if let cleanliness = cleanliness { categories.append(("Cleanliness", cleanliness)) }
        if let nightlife = nightlife { categories.append(("Nightlife", nightlife)) }
        if let scenery = scenery { categories.append(("Scenery", scenery)) }
        if let transportation = transportation { categories.append(("Transportation", transportation)) }

        return categories
    }

    // Check if any category is rated
    var hasAnyRating: Bool {
        return food != nil || culture != nil || safety != nil || affordability != nil ||
               cleanliness != nil || nightlife != nil || scenery != nil || transportation != nil
    }

    // Initialize with all nil values
    init(food: Int? = nil, culture: Int? = nil, safety: Int? = nil,
         affordability: Int? = nil, cleanliness: Int? = nil, nightlife: Int? = nil,
         scenery: Int? = nil, transportation: Int? = nil) {
        self.food = food
        self.culture = culture
        self.safety = safety
        self.affordability = affordability
        self.cleanliness = cleanliness
        self.nightlife = nightlife
        self.scenery = scenery
        self.transportation = transportation
    }
}
