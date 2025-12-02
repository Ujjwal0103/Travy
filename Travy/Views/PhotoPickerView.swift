//
//  PhotoPickerView.swift
//  Travy
//
//  Photo selection and grid display components
//

import SwiftUI
import PhotosUI

// Photo Picker Button using PHPickerViewController
struct PhotoPickerButton: View {
    @Binding var photos: [UIImage]
    let maxPhotos: Int
    @State private var showingPicker = false

    var canAddMore: Bool {
        photos.count < maxPhotos
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                if canAddMore {
                    showingPicker = true
                }
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(canAddMore ? "Add Photo" : "Maximum \(maxPhotos) photos")
                    Spacer()
                    if canAddMore {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!canAddMore)

            Text("\(photos.count) of \(maxPhotos) photos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(images: $photos, maxPhotos: maxPhotos)
        }
    }
}

// Photo Grid Display
struct PhotoGridView: View {
    @Binding var photos: [UIImage]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        if !photos.isEmpty {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)

                        Button(action: {
                            photos.remove(at: index)
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
    }
}

// UIViewControllerRepresentable for PHPickerViewController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let maxPhotos: Int
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxPhotos - images.count
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            if self.parent.images.count < self.parent.maxPhotos {
                                self.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}
