//
//  AutocompleteTextField.swift
//  Travy
//
//  Created by Ujjwal Rastogi on 11/6/25.
//

import SwiftUI
import MapKit

struct AutocompleteTextField: View {
    let placeholder: String
    @Binding var text: String
    let suggestions: [AutocompleteResult]
    let onSelect: (AutocompleteResult) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.roundedBorder)
            
            if isFocused && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions) { suggestion in
                            Button {
                                onSelect(suggestion)
                                isFocused = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: suggestion.type == .hotel ? "bed.double.fill" : "mappin.circle.fill")
                                        .foregroundColor(suggestion.type == .hotel ? .purple : .green)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            
                            if suggestion.id != suggestions.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    AutocompleteTextField(
        placeholder: "Search...",
        text: $text,
        suggestions: [
            AutocompleteResult(
                title: "Tokyo",
                subtitle: "Tokyo, Japan",
                coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                type: .city
            )
        ],
        onSelect: { _ in }
    )
    .padding()
}

