//
//  StatisticsService.swift
//  Travy
//
//  Service for calculating travel statistics from SwiftData models
//

import Foundation
import SwiftUI

@MainActor
class StatisticsService: ObservableObject {
    @Published var statistics: TravelStatistics?
    @Published var isLoading = false

    private var lastCalculation: Date?
    private let cacheTimeout: TimeInterval = 60 // 1 minute cache

    func calculateStatistics(
        cities: [City],
        hotels: [Hotel],
        filter: TimePeriodFilter = .allTime
    ) -> TravelStatistics {

        // Filter data based on time period
        let filteredCities = filterCities(cities, by: filter)
        let filteredHotels = filterHotels(hotels, by: filter)

        // Calculate unique countries from cities
        let uniqueCountries = Set(filteredCities.map { $0.country }).count

        // Calculate unique cities
        let uniqueCities = filteredCities.count

        // Total nights stayed (sum of all hotel stays)
        let totalNights = filteredHotels.reduce(0) { $0 + $1.nights }

        // Average stay duration
        let avgStayDuration = filteredHotels.isEmpty ? 0 :
            Double(totalNights) / Double(filteredHotels.count)

        // Most visited country (from cities)
        let countryFrequency = Dictionary(grouping: filteredCities, by: { $0.country })
            .mapValues { $0.count }
        let mostVisited = countryFrequency.max(by: { $0.value < $1.value })

        // Most visited city
        let cityFrequency = Dictionary(grouping: filteredCities, by: { $0.name })
            .mapValues { $0.count }
        let mostVisitedCity = cityFrequency.max(by: { $0.value < $1.value })

        // Cities by year
        let citiesByYear = Dictionary(grouping: filteredCities, by: { city in
            Calendar.current.component(.year, from: city.visitDate)
        }).mapValues { $0.count }

        // Cities by month (1-12)
        let citiesByMonth = Dictionary(grouping: filteredCities, by: { city in
            Calendar.current.component(.month, from: city.visitDate)
        }).mapValues { $0.count }

        // Hotels by year
        let hotelsByYear = Dictionary(grouping: filteredHotels, by: { hotel in
            Calendar.current.component(.year, from: hotel.checkInDate)
        }).mapValues { $0.count }

        // Top rated cities
        let ratedCities = filteredCities
            .compactMap { city -> (city: City, rating: Double)? in
                guard let rating = city.ratings?.averageRating else { return nil }
                return (city, rating)
            }
            .sorted { $0.rating > $1.rating }
            .prefix(10)

        // Longest and shortest hotel stays
        let sortedByNights = filteredHotels.sorted { $0.nights > $1.nights }

        // Average hotel rating
        let hotelRatings = filteredHotels.compactMap { $0.starRating }
        let avgHotelRating = hotelRatings.isEmpty ? nil :
            Double(hotelRatings.reduce(0, +)) / Double(hotelRatings.count)

        // Calculate current year stats
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let citiesThisYear = cities.filter {
            calendar.component(.year, from: $0.visitDate) == currentYear
        }.count
        let countriesThisYear = Set(cities.filter {
            calendar.component(.year, from: $0.visitDate) == currentYear
        }.map { $0.country }).count

        return TravelStatistics(
            totalCountries: uniqueCountries,
            totalCities: uniqueCities,
            totalHotels: filteredHotels.count,
            totalNights: totalNights,
            averageStayDuration: avgStayDuration,
            mostVisitedCountry: mostVisited.map { ($0.key, $0.value) },
            mostVisitedCity: mostVisitedCity.map { ($0.key, $0.value) },
            longestStay: sortedByNights.first,
            shortestStay: sortedByNights.last,
            averageHotelRating: avgHotelRating,
            citiesByYear: citiesByYear,
            citiesByMonth: citiesByMonth,
            hotelsByYear: hotelsByYear,
            topRatedCities: Array(ratedCities),
            mostRecentCity: filteredCities.max(by: { $0.visitDate < $1.visitDate }),
            countriesVisitedThisYear: countriesThisYear,
            citiesVisitedThisYear: citiesThisYear
        )
    }

    // MARK: - Filtering Helpers

    private func filterCities(_ cities: [City], by filter: TimePeriodFilter) -> [City] {
        guard let startDate = filter.startDate() else {
            return cities
        }
        return cities.filter { $0.visitDate >= startDate }
    }

    private func filterHotels(_ hotels: [Hotel], by filter: TimePeriodFilter) -> [Hotel] {
        guard let startDate = filter.startDate() else {
            return hotels
        }
        return hotels.filter { $0.checkInDate >= startDate }
    }

    // MARK: - Chart Data Preparation

    func prepareCitiesByYearData(from statistics: TravelStatistics) -> [YearData] {
        statistics.citiesByYear
            .map { YearData(year: $0.key, count: $0.value) }
            .sorted { $0.year < $1.year }
    }

    func prepareHotelsByYearData(from statistics: TravelStatistics) -> [YearData] {
        statistics.hotelsByYear
            .map { YearData(year: $0.key, count: $0.value) }
            .sorted { $0.year < $1.year }
    }

    func prepareMonthData(from statistics: TravelStatistics) -> [MonthData] {
        statistics.citiesByMonth
            .map { MonthData(month: $0.key, count: $0.value) }
            .sorted { $0.month < $1.month }
    }

    func prepareRatedCityData(from statistics: TravelStatistics) -> [RatedCityData] {
        statistics.topRatedCities
            .map { RatedCityData(city: $0.city, rating: $0.rating) }
    }
}
