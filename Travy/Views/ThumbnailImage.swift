//
//  ThumbnailImage.swift
//  Travy
//
//  Async thumbnail image loading component
//

import SwiftUI

struct ThumbnailImage: View {
    let filename: String
    let entityId: UUID
    let entityType: EntityType

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    ProgressView()
                }
            } else {
                // Fallback for missing image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = PhotoManager.shared.loadThumbnail(
                filename: filename,
                for: entityId,
                type: entityType
            )

            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}
