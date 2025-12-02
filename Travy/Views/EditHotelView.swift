//
//  EditHotelView.swift
//  Travy
//
//  View for editing existing hotel entries
//

import SwiftUI
import SwiftData

struct EditHotelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var hotel: Hotel

    @State private var checkInDate: Date
    @State private var checkOutDate: Date
    @State private var starRating: Int?
    @State private var amenities: String
    @State private var notes: String
    @State private var favoriteAspects: String
    @State private var selectedPhotos: [UIImage] = []
    @State private var existingPhotos: [String]
    @State private var photosToDelete: [String] = []

    init(hotel: Hotel) {
        self.hotel = hotel
        _checkInDate = State(initialValue: hotel.checkInDate)
        _checkOutDate = State(initialValue: hotel.checkOutDate)
        _starRating = State(initialValue: hotel.starRating)
        _amenities = State(initialValue: hotel.amenities)
        _notes = State(initialValue: hotel.notes)
        _favoriteAspects = State(initialValue: hotel.favoriteAspects)
        _existingPhotos = State(initialValue: hotel.photoFilenames)
    }

    var totalPhotoCount: Int {
        existingPhotos.count + selectedPhotos.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hotel Information") {
                    HStack {
                        Text("Hotel:")
                            .foregroundColor(.secondary)
                        Text(hotel.name)
                    }
                    HStack {
                        Text("Location:")
                            .foregroundColor(.secondary)
                        Text("\(hotel.city), \(hotel.country)")
                    }
                }

                Section("Dates") {
                    DatePicker("Check-in", selection: $checkInDate, displayedComponents: .date)
                    DatePicker("Check-out", selection: $checkOutDate, displayedComponents: .date)
                }

                Section("Details") {
                    Picker("Star Rating", selection: $starRating) {
                        Text("None").tag(Int?.none)
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating) star\(rating == 1 ? "" : "s")").tag(Int?.some(rating))
                        }
                    }

                    TextField("Amenities (comma separated)", text: $amenities)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Favorite Aspects", text: $favoriteAspects)
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
                                        entityId: hotel.id,
                                        entityType: .hotel
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
            }
            .navigationTitle("Edit Hotel")
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
        hotel.checkInDate = checkInDate
        hotel.checkOutDate = checkOutDate
        hotel.starRating = starRating
        hotel.amenities = amenities
        hotel.notes = notes
        hotel.favoriteAspects = favoriteAspects

        // Delete removed photos
        for filename in photosToDelete {
            PhotoManager.shared.deletePhoto(filename: filename, for: hotel.id, type: .hotel)
        }

        // Update photo filenames list
        hotel.photoFilenames = existingPhotos

        // Save new photos
        for photo in selectedPhotos {
            if let filename = PhotoManager.shared.savePhoto(image: photo, for: hotel.id, type: .hotel) {
                hotel.photoFilenames.append(filename)
            }
        }

        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save hotel changes: \(error)")
        }
        
        dismiss()
    }
}
