# Travy - Travel Tracking App

## App Name
**Travy**

## Group Members
[Your Name/Names Here]

## App Idea
Travy is a native iOS travel tracking application that helps users organize and visualize their travel history. The app allows users to record trips, hotels, and cities they've visited, with each entry including dates, locations, notes, and other relevant details. Users can view their travel data in multiple formats: an interactive map showing all locations, a chronological timeline, and organized list views.

## Motivation
Travel enthusiasts often struggle to keep track of all the places they've visited, hotels they've stayed at, and trips they've taken over time. While websites can display this information, a native iOS app provides a superior experience with offline access, native MapKit integration for interactive maps, smooth animations, and seamless data persistence. Travy makes it easy to build a personal travel journal that's always accessible on your device, helping users reminisce about past adventures and plan future travels based on their history.

## Architecture
The app follows a SwiftUI-based MVVM architecture with SwiftData for persistence. The main views include:
- **MapView**: Interactive map displaying trips, hotels, and cities as color-coded pins with tap gestures for details
- **TimelineView**: Chronological view of all travel entries with search and filtering capabilities
- **CitiesListView** & **HotelsListView**: Organized list views grouped by country with search functionality
- **Add Views**: Forms for creating new trips, hotels, and cities with autocomplete search integration

Data models (Trip, Hotel, City) use SwiftData's `@Model` annotation for automatic persistence. The app integrates with MapKit's `MKLocalSearch` API for location autocomplete and geocoding services.

## Course Concepts Included
1. **Gesture Recognition**: Tap gestures on map pins to view details and zoom to locations
2. **Network Requests**: Integration with MapKit's `MKLocalSearch` API for location autocomplete and geocoding
3. **Persistent Data Storage**: SwiftData framework for storing trips, hotels, and cities with automatic persistence across app launches

