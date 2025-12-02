//
//  EditCityView.swift
//  Travy
//
//  View for editing existing city entries
//

import SwiftUI
import SwiftData

struct EditCityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var city: City

    @State private var visitDate: Date
    @State private var highlights: String
    @State private var selectedPhotos: [UIImage] = []
    @State private var existingPhotos: [String]
    @State private var cityRating: CityRating
    @State private var photosToDelete: [String] = []

    init(city: City) {
        self.city = city
        _visitDate = State(initialValue: city.visitDate)
        _highlights = State(initialValue: city.highlights)
        _existingPhotos = State(initialValue: city.photoFilenames)
        _cityRating = State(initialValue: city.ratings ?? CityRating())
    }

    var totalPhotoCount: Int {
        existingPhotos.count + selectedPhotos.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("City Information") {
                    HStack {
                        Text("City:")
                            .foregroundColor(.secondary)
                        Text(city.name)
                    }
                    HStack {
                        Text("Country:")
                            .foregroundColor(.secondary)
                        Text(city.country)
                    }
                    DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                }

                Section("Highlights") {
                    TextField("What made this visit special?", text: $highlights, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photos") {
                    // Existing photos
                    if !existingPhotos.isEmpty {
                        Text("Current Photos")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(existingPhotos, id: \.self) { filename in
                                ZStack(alignment: .topTrailing) {
                                    ThumbnailImage(
                                        filename: filename,
                                        entityId: city.id,
                                        entityType: .city
                                    )
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)

                                    Button(action: {
                                        existingPhotos.removeAll { $0 == filename }
                                        photosToDelete.append(filename)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                            .font(.system(size: 20))
                                    }
                                    .padding(4)
                                }
                            }
                        }
                    }

                    // Add new photos
                    if totalPhotoCount < 10 {
                        PhotoPickerButton(photos: $selectedPhotos, maxPhotos: 10 - existingPhotos.count)
                        PhotoGridView(photos: $selectedPhotos)
                    } else {
                        Text("Maximum 10 photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Ratings") {
                    CategoryRatingInput(rating: $cityRating)
                }
            }
            .navigationTitle("Edit City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        // Update basic info
        city.visitDate = visitDate
        city.highlights = highlights

        // Delete removed photos
        for filename in photosToDelete {
            PhotoManager.shared.deletePhoto(filename: filename, for: city.id, type: .city)
        }

        // Update photo filenames list
        city.photoFilenames = existingPhotos

        // Save new photos
        for photo in selectedPhotos {
            if let filename = PhotoManager.shared.savePhoto(image: photo, for: city.id, type: .city) {
                city.photoFilenames.append(filename)
            }
        }

        // Update rating
        if cityRating.hasAnyRating {
            city.ratings = cityRating
        } else {
            city.ratingsData = nil
        }

        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save city changes: \(error)")
        }
        
        dismiss()
    }
}
