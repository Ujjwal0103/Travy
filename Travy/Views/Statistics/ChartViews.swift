//
//  ChartViews.swift
//  Travy
//
//  Chart components using Swift Charts for travel statistics
//

import SwiftUI
import Charts

// MARK: - Cities by Year Bar Chart

struct CitiesByYearChart: View {
    let data: [YearData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cities Visited by Year")
                .font(.headline)
                .padding(.horizontal)

            if data.isEmpty {
                Text("No city data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Year", item.year),
                        y: .value("Cities", item.count)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Cities by year bar chart")
        .accessibilityValue("\(data.count) years of travel data")
    }
}

// MARK: - Hotels by Year Bar Chart

struct HotelsByYearChart: View {
    let data: [YearData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hotels Stayed by Year")
                .font(.headline)
                .padding(.horizontal)

            if data.isEmpty {
                Text("No hotel data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Year", item.year),
                        y: .value("Hotels", item.count)
                    )
                    .foregroundStyle(.purple.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Hotels by year bar chart")
        .accessibilityValue("\(data.count) years of hotel stays")
    }
}

// MARK: - Monthly Travel Bar Chart

struct MonthlyTravelChart: View {
    let data: [MonthData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Travel by Month")
                .font(.headline)
                .padding(.horizontal)

            if data.isEmpty {
                Text("No monthly data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.monthName),
                        y: .value("Trips", item.count)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Travel by month bar chart")
        .accessibilityValue("\(data.count) months with trips")
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            CitiesByYearChart(data: [
                YearData(year: 2022, count: 5),
                YearData(year: 2023, count: 8),
                YearData(year: 2024, count: 12)
            ])

            HotelsByYearChart(data: [
                YearData(year: 2022, count: 3),
                YearData(year: 2023, count: 6),
                YearData(year: 2024, count: 10)
            ])

            MonthlyTravelChart(data: [
                MonthData(month: 1, count: 2),
                MonthData(month: 3, count: 5),
                MonthData(month: 6, count: 8),
                MonthData(month: 12, count: 3)
            ])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
