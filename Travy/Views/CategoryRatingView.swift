//
//  CategoryRatingView.swift
//  Travy
//
//  Components for inputting and displaying category ratings
//

import SwiftUI

// Input view for rating categories
struct CategoryRatingInput: View {
    @Binding var rating: CityRating

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rate Your Experience")
                .font(.headline)

            CategoryRatingRow(
                icon: "fork.knife",
                category: "Food",
                rating: $rating.food,
                color: .orange
            )

            CategoryRatingRow(
                icon: "theatermasks",
                category: "Culture",
                rating: $rating.culture,
                color: .purple
            )

            CategoryRatingRow(
                icon: "shield.fill",
                category: "Safety",
                rating: $rating.safety,
                color: .blue
            )

            CategoryRatingRow(
                icon: "dollarsign.circle",
                category: "Affordability",
                rating: $rating.affordability,
                color: .green
            )

            CategoryRatingRow(
                icon: "sparkles",
                category: "Cleanliness",
                rating: $rating.cleanliness,
                color: .cyan
            )

            CategoryRatingRow(
                icon: "moon.stars.fill",
                category: "Nightlife",
                rating: $rating.nightlife,
                color: .indigo
            )

            CategoryRatingRow(
                icon: "mountain.2.fill",
                category: "Scenery",
                rating: $rating.scenery,
                color: .teal
            )

            CategoryRatingRow(
                icon: "car.fill",
                category: "Transportation",
                rating: $rating.transportation,
                color: .pink
            )
        }
    }
}

// Individual category rating row
struct CategoryRatingRow: View {
    let icon: String
    let category: String
    @Binding var rating: Int?
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

            Text(category)
                .frame(width: 130, alignment: .leading)

            StarRatingView(rating: $rating, interactive: true)
        }
    }
}

// Display view for rated categories
struct CategoryRatingDisplay: View {
    let rating: CityRating

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ratings")
                    .font(.headline)

                Spacer()

                if let average = rating.averageRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        Text(String(format: "%.1f", average))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !rating.ratedCategories.isEmpty {
                VStack(spacing: 12) {
                    ForEach(rating.ratedCategories, id: \.0) { category, value in
                        CategoryRatingDisplayRow(
                            category: category,
                            rating: value
                        )
                    }
                }
            } else {
                Text("No ratings yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// Individual category display row
struct CategoryRatingDisplayRow: View {
    let category: String
    let rating: Int

    var icon: String {
        switch category {
        case "Food": return "fork.knife"
        case "Culture": return "theatermasks"
        case "Safety": return "shield.fill"
        case "Affordability": return "dollarsign.circle"
        case "Cleanliness": return "sparkles"
        case "Nightlife": return "moon.stars.fill"
        case "Scenery": return "mountain.2.fill"
        case "Transportation": return "car.fill"
        default: return "star.fill"
        }
    }

    var color: Color {
        switch category {
        case "Food": return .orange
        case "Culture": return .purple
        case "Safety": return .blue
        case "Affordability": return .green
        case "Cleanliness": return .cyan
        case "Nightlife": return .indigo
        case "Scenery": return .teal
        case "Transportation": return .pink
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 25)

            Text(category)
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)

            // Star display
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
            }

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (CGFloat(rating) / 5.0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}
