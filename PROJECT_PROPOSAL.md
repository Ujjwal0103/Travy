# Travy

**Group Members:**  
- Ujjwal Rastogi  
- Aadit Shah  
- Keshav Mohta  

---

## 🧭 Overview

**Travy** is a native iOS travel tracking application designed to help users organize and visualize their travel history in a beautiful and intuitive way.  
With Travy, users can record **hotels** and **cities** they've visited, including **dates, locations, notes, and other details**.  

The app offers multiple ways to view travel data — including an **interactive map with pins**, a **chronological timeline**, and **organized list views** — allowing users to reflect on their adventures and plan future travels seamlessly.

---

## 💡 Motivation

The motivation behind Travy comes from the difficulty many travel enthusiasts face when trying to keep track of where they’ve been.  

While there are web tools available, a **native iOS app** offers a much richer experience with:
- Offline access  
- Smooth animations  
- Tight integration with Apple’s **MapKit**

Travy aims to make **travel journaling effortless, personal, and visually engaging.**

---

## 🧩 Core Features

### 🗺️ Interactive MapView
- Displays hotels and cities as **color-coded pins**  
- Users can tap on any pin to view details or zoom in on a location  

### 🕒 TimelineView
- Shows all travel entries in **chronological order**  
- Includes **filtering** and **search options**

### 🏙️ CitiesListView & HotelsListView
- Organizes data by **country**
- Includes **search functionality** for quick access  

### ➕ Add Views
- Allows users to create new **hotels** and **cities**  
- Integrates with **autocomplete search** powered by **MapKit’s MKLocalSearch API**

---

## 🔧 Key Technical Concepts

Travy incorporates key course and iOS development concepts such as:

### ✋ Gesture Recognition
- Supports **map interaction** via taps and zoom gestures  

### 🌐 Network Requests
- Used for **location autocomplete** and **geocoding** via **Apple’s MapKit API**

### 💾 Persistent Data Storage
- Implemented through **SwiftData’s `@Model` annotation**, ensuring all user data remains accessible across app sessions  

---

## 🚀 Summary

Travy combines **intuitive UI**, **native performance**, and **data persistence** to make tracking travel history simple, visual, and delightful.  
It’s the perfect companion for travelers who love exploring new places and keeping their memories organized.

