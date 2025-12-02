//
//  StarRatingView.swift
//  Travy
//
//  Reusable star rating component with interactive and display modes
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int?
    let maxRating: Int = 5
    let interactive: Bool

    init(rating: Binding<Int?>, interactive: Bool = true) {
        self._rating = rating
        self.interactive = interactive
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                    .onTapGesture {
                        if interactive {
                            if rating == index {
                                rating = nil // Tap same star to deselect
                            } else {
                                rating = index
                            }
                        }
                    }
            }

            if interactive && rating != nil {
                Button(action: {
                    rating = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
    }

    private func starType(for index: Int) -> String {
        guard let currentRating = rating else {
            return "star"
        }
        return index <= currentRating ? "star.fill" : "star"
    }
}

// Display-only star rating
struct StarRatingDisplayView: View {
    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
            }
            Text(String(format: "%.1f", rating))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func starType(for index: Int) -> String {
        let difference = rating - Double(index - 1)
        if difference >= 1.0 {
            return "star.fill"
        } else if difference > 0.0 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
