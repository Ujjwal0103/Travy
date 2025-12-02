//
//  PhotoManager.swift
//  Travy
//
//  Manages local photo storage for cities and hotels
//

import Foundation
import UIKit

enum EntityType: String {
    case city = "Cities"
    case hotel = "Hotels"
}

class PhotoManager {
    static let shared = PhotoManager()

    private let fileManager = FileManager.default
    private let maxPhotos = 10

    private init() {
        createDirectoriesIfNeeded()
    }

    // MARK: - Directory Management

    private func createDirectoriesIfNeeded() {
        let citiesURL = getBaseURL(for: .city)
        let hotelsURL = getBaseURL(for: .hotel)

        try? fileManager.createDirectory(at: citiesURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: hotelsURL, withIntermediateDirectories: true)
    }

    private func getBaseURL(for entityType: EntityType) -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
            .appendingPathComponent("Photos")
            .appendingPathComponent(entityType.rawValue)
    }

    private func getEntityDirectory(for entityId: UUID, type: EntityType) -> URL {
        return getBaseURL(for: type).appendingPathComponent(entityId.uuidString)
    }

    // MARK: - Photo Count

    func getPhotoCount(for entityId: UUID, type: EntityType) -> Int {
        let entityDir = getEntityDirectory(for: entityId, type: type)

        guard let contents = try? fileManager.contentsOfDirectory(atPath: entityDir.path) else {
            return 0
        }

        // Count only original photos (not thumbnails)
        return contents.filter { !$0.contains("_thumb") && $0.hasSuffix(".jpg") }.count
    }

    func canAddPhoto(for entityId: UUID, type: EntityType) -> Bool {
        return getPhotoCount(for: entityId, type: type) < maxPhotos
    }

    // MARK: - Save Photo

    func savePhoto(image: UIImage, for entityId: UUID, type: EntityType) -> String? {
        // Check photo limit
        guard canAddPhoto(for: entityId, type: type) else {
            print("Photo limit reached for \(type.rawValue) \(entityId)")
            return nil
        }

        // Create entity directory if needed
        let entityDir = getEntityDirectory(for: entityId, type: type)
        try? fileManager.createDirectory(at: entityDir, withIntermediateDirectories: true)

        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = entityDir.appendingPathComponent(filename)
        let thumbURL = entityDir.appendingPathComponent(filename.replacingOccurrences(of: ".jpg", with: "_thumb.jpg"))

        // Save original image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        do {
            try imageData.write(to: fileURL)

            // Generate and save thumbnail
            if let thumbnail = generateThumbnail(from: image, size: CGSize(width: 200, height: 200)) {
                if let thumbData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try thumbData.write(to: thumbURL)
                }
            }

            return filename
        } catch {
            print("Error saving photo: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Load Photo

    func loadPhoto(filename: String, for entityId: UUID, type: EntityType) -> UIImage? {
        let entityDir = getEntityDirectory(for: entityId, type: type)
        let fileURL = entityDir.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    func loadThumbnail(filename: String, for entityId: UUID, type: EntityType) -> UIImage? {
        let entityDir = getEntityDirectory(for: entityId, type: type)
        let thumbFilename = filename.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        let thumbURL = entityDir.appendingPathComponent(thumbFilename)

        // Try to load thumbnail first
        if fileManager.fileExists(atPath: thumbURL.path) {
            return UIImage(contentsOfFile: thumbURL.path)
        }

        // Fall back to original if thumbnail doesn't exist
        return loadPhoto(filename: filename, for: entityId, type: type)
    }

    // MARK: - Delete Photo

    func deletePhoto(filename: String, for entityId: UUID, type: EntityType) {
        let entityDir = getEntityDirectory(for: entityId, type: type)
        let fileURL = entityDir.appendingPathComponent(filename)
        let thumbFilename = filename.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        let thumbURL = entityDir.appendingPathComponent(thumbFilename)

        // Delete original
        try? fileManager.removeItem(at: fileURL)

        // Delete thumbnail
        try? fileManager.removeItem(at: thumbURL)
    }

    func deleteAllPhotos(for entityId: UUID, type: EntityType) {
        let entityDir = getEntityDirectory(for: entityId, type: type)
        try? fileManager.removeItem(at: entityDir)
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from image: UIImage, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
