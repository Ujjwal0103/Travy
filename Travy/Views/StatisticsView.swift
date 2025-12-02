//
//  StatisticsView.swift
//  Travy
//
//  Main statistics dashboard showing travel analytics
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \City.visitDate, order: .reverse) private var cities: [City]
    @Query(sort: \Hotel.checkInDate, order: .reverse) private var hotels: [Hotel]

    @StateObject private var service = StatisticsService()
    @State private var selectedPeriod: TimePeriodFilter = .allTime
    @State private var statistics: TravelStatistics?

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .refreshable {
                    await loadStatistics()
                }
                .task {
                    await loadStatistics()
                }
                .onChange(of: selectedPeriod) { _, _ in
                    Task { await loadStatistics() }
                }
                .onChange(of: cities.count) { _, _ in
                    Task { await loadStatistics() }
                }
                .onChange(of: hotels.count) { _, _ in
                    Task { await loadStatistics() }
                }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if cities.isEmpty && hotels.isEmpty {
                emptyStateView
            } else {
                contentScrollView
            }
        }
    }

    private var contentScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let stats = statistics {
                    statisticsContent(stats)
                } else {
                    ProgressView("Calculating statistics...")
                        .padding()
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func statisticsContent(_ stats: TravelStatistics) -> some View {
        filterSection
        quickStatsGrid(stats)

        if stats.mostVisitedCountry != nil || stats.longestStay != nil {
            highlightsSection(stats)
        }

        chartsSection(stats)

        if !stats.topRatedCities.isEmpty {
            topRatedCitiesSection(stats)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriodFilter.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Quick Stats Grid

    private func quickStatsGrid(_ stats: TravelStatistics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "flag.fill",
                title: "Countries",
                value: "\(stats.totalCountries)",
                color: .blue
            )

            StatCard(
                icon: "mappin.circle.fill",
                title: "Cities",
                value: "\(stats.totalCities)",
                color: .green
            )

            StatCard(
                icon: "bed.double.fill",
                title: "Hotels",
                value: "\(stats.totalHotels)",
                color: .purple
            )

            StatCard(
                icon: "moon.zzz.fill",
                title: "Nights",
                value: "\(stats.totalNights)",
                color: .indigo
            )

            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Avg Stay",
                value: String(format: "%.1f nights", stats.averageStayDuration),
                color: .teal
            )

            if let avgRating = stats.averageHotelRating {
                StatCard(
                    icon: "star.fill",
                    title: "Avg Rating",
                    value: String(format: "%.1f ★", avgRating),
                    color: .orange
                )
            }
        }
    }

    // MARK: - Highlights Section

    private func highlightsSection(_ stats: TravelStatistics) -> some View {
        VStack(spacing: 12) {
            Text("Highlights")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let mostVisited = stats.mostVisitedCountry {
                HighlightCard(
                    icon: "star.fill",
                    title: "Most Visited Country",
                    value: mostVisited.name,
                    subtitle: "\(mostVisited.count) \(mostVisited.count == 1 ? "visit" : "visits")",
                    color: .orange
                )
            }

            if let mostVisitedCity = stats.mostVisitedCity {
                HighlightCard(
                    icon: "mappin.circle.fill",
                    title: "Most Visited City",
                    value: mostVisitedCity.name,
                    subtitle: "\(mostVisitedCity.count) \(mostVisitedCity.count == 1 ? "visit" : "visits")",
                    color: .green
                )
            }

            if let longestStay = stats.longestStay {
                HighlightCard(
                    icon: "arrow.up.right",
                    title: "Longest Stay",
                    value: longestStay.name,
                    subtitle: "\(longestStay.nights) \(longestStay.nights == 1 ? "night" : "nights")",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Charts Section

    private func chartsSection(_ stats: TravelStatistics) -> some View {
        VStack(spacing: 16) {
            Text("Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Cities by year
            if !stats.citiesByYear.isEmpty {
                CitiesByYearChart(data: service.prepareCitiesByYearData(from: stats))
            }

            // Hotels by year
            if !stats.hotelsByYear.isEmpty {
                HotelsByYearChart(data: service.prepareHotelsByYearData(from: stats))
            }

            // Monthly patterns
            if !stats.citiesByMonth.isEmpty {
                MonthlyTravelChart(data: service.prepareMonthData(from: stats))
            }
        }
    }

    // MARK: - Top Rated Cities Section

    private func topRatedCitiesSection(_ stats: TravelStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Rated Cities")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(Array(stats.topRatedCities.prefix(5)), id: \.city.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.city.name)
                            .font(.headline)
                        Text(item.city.country)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", item.rating))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Travel Data",
            systemImage: "chart.bar.xaxis",
            description: Text("Start adding trips, cities, and hotels to see your travel statistics!")
        )
    }

    // MARK: - Load Statistics

    private func loadStatistics() async {
        statistics = service.calculateStatistics(
            cities: cities,
            hotels: hotels,
            filter: selectedPeriod
        )
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .modelContainer(for: [City.self, Hotel.self], inMemory: true)
}
