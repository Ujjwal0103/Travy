//
//  PhotoCarouselView.swift
//  Travy
//
//  Photo carousel for displaying multiple photos
//

import SwiftUI

struct PhotoCarouselView: View {
    let photos: [String]
    let entityId: UUID
    let entityType: EntityType

    @State private var selectedPhotoIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos")
                .font(.headline)

            TabView {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, filename in
                    PhotoCarouselItem(
                        filename: filename,
                        entityId: entityId,
                        entityType: entityType
                    )
                    .onTapGesture {
                        selectedPhotoIndex = index
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndex(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { photoIndex in
            FullScreenPhotoView(
                photos: photos,
                currentIndex: photoIndex.index,
                entityId: entityId,
                entityType: entityType
            )
        }
    }
}

// Carousel item view
struct PhotoCarouselItem: View {
    let filename: String
    let entityId: UUID
    let entityType: EntityType

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    ProgressView()
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = PhotoManager.shared.loadPhoto(
                filename: filename,
                for: entityId,
                type: entityType
            )

            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

// Full-screen photo viewer
struct FullScreenPhotoView: View {
    let photos: [String]
    @State var currentIndex: Int
    let entityId: UUID
    let entityType: EntityType

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, filename in
                    ZoomablePhotoView(
                        filename: filename,
                        entityId: entityId,
                        entityType: entityType
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex + 1) of \(photos.count)")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// Zoomable photo view
struct ZoomablePhotoView: View {
    let filename: String
    let entityId: UUID
    let entityType: EntityType

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // Reset if zoomed out too much
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            // Double-tap to reset zoom
                            withAnimation {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = PhotoManager.shared.loadPhoto(
                filename: filename,
                for: entityId,
                type: entityType
            )

            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

// Helper struct for photo index binding
struct PhotoIndex: Identifiable {
    let id = UUID()
    let index: Int
}
