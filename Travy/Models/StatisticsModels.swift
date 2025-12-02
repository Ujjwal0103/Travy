//
//  StatisticsModels.swift
//  Travy
//
//  Data models for travel statistics and charts
//

import Foundation
import SwiftUI

// MARK: - Main Statistics Data Structure

struct TravelStatistics {
    // Core metrics
    let totalCountries: Int
    let totalCities: Int
    let totalHotels: Int
    let totalNights: Int
    let averageStayDuration: Double

    // Most visited
    let mostVisitedCountry: (name: String, count: Int)?
    let mostVisitedCity: (name: String, count: Int)?

    // Hotel metrics
    let longestStay: Hotel?
    let shortestStay: Hotel?
    let averageHotelRating: Double?

    // Distributions
    let citiesByYear: [Int: Int]
    let citiesByMonth: [Int: Int]
    let hotelsByYear: [Int: Int]

    // Top rated cities
    let topRatedCities: [(city: City, rating: Double)]

    // Recent stats
    let mostRecentCity: City?
    let countriesVisitedThisYear: Int
    let citiesVisitedThisYear: Int
}

// MARK: - Chart Data Models

struct YearData: Identifiable, Hashable {
    let id = UUID()
    let year: Int
    let count: Int
}

struct MonthData: Identifiable, Hashable {
    let id = UUID()
    let month: Int
    let monthName: String
    let count: Int

    init(month: Int, count: Int) {
        self.month = month
        self.count = count

        // Convert month number to name
        let formatter = DateFormatter()
        formatter.monthSymbols = DateFormatter().shortMonthSymbols
        self.monthName = formatter.shortMonthSymbols[month - 1]
    }
}

struct TagData: Identifiable, Hashable {
    let id = UUID()
    let tag: String
    let count: Int

    var color: Color {
        switch tag {
        case "Business":
            return .blue
        case "Vacation":
            return .orange
        case "Conference":
            return .purple
        case "Family":
            return .green
        case "Solo":
            return .red
        case "Adventure":
            return .teal
        default:
            return .gray
        }
    }
}

struct RatedCityData: Identifiable {
    let id: UUID
    let cityName: String
    let country: String
    let rating: Double
    let city: City

    init(city: City, rating: Double) {
        self.id = city.id
        self.cityName = city.name
        self.country = city.country
        self.rating = rating
        self.city = city
    }
}

// MARK: - Time Period Filter

enum TimePeriodFilter: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case thisYear = "This Year"
    case lastSixMonths = "Last 6 Months"
    case lastYear = "Last Year"

    var id: String { rawValue }

    func startDate(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .allTime:
            return nil // No filtering
        case .thisYear:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .lastSixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now)
        case .lastYear:
            let startOfThisYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return calendar.date(byAdding: .year, value: -1, to: startOfThisYear)
        }
    }
}
