# Trava — Google Maps Integration & Configuration Guide

Google Maps is fully integrated into the Trava mobile application (`mobile/lib/features/tracking/bus_map_screen.dart`), providing live satellite and street-level geographic tracking alongside our custom offline Canvas transit map.

---

## 1. Features Implemented in the App

- **Interactive Google Maps View**: Displays real-world Coimbatore geography centered on Route 95.
- **Route 95 Polyline**: Emerald green (`#0F4C3A`) geodesic polyline connecting all 6 Coimbatore stops (Gandhipuram to Singanallur).
- **Stop Station Markers**:
  - Gandhipuram Central (Origin Terminus, Red Hue)
  - Lakshmi Mills Junction (Azure Hue)
  - Nava India Signal (Azure Hue)
  - Peelamedu Bus Stop (Azure Hue)
  - Fun Republic Mall Area (Azure Hue)
  - Singanallur Bus Terminus (Destination Terminus, Red Hue)
- **Live Animated Bus Marker**:
  - Dynamically updates position every 2 seconds from authoritative backend simulation.
  - Orange hue with bearing rotation angle following the road direction.
  - Info window displaying real-time ETA, speed, and bus identifier.
- **Dynamic Camera Following**: The camera automatically pans and smoothly follows the bus along the road.
- **Map View Controls**:
  - **Re-center Floating Button**: Automatically focuses and zooms in on the live bus.
  - **Satellite / Street Toggle**: 1-tap switch between satellite imagery and standard vector map.
  - **Map Engine Switcher**: 1-tap toggle between real-world **Google Maps** and the stylized **Schematic Transit Canvas**.
- **Cross-Platform Resilience**:
  - Natively supported on **Android**, **iOS**, and **Web (Chrome / Edge)**.
  - Automatically activates the Schematic Transit Canvas on Windows desktop or when API keys are not supplied.

---

## 2. API Key Configuration

### 2.1 Android (`mobile/android/app/src/main/AndroidManifest.xml`)
The manifest includes location permissions and the Google Maps API key meta-data:
```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <application ...>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```
To supply your production key, replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key from the Google Cloud Console.

### 2.2 Web (`mobile/web/index.html`)
The HTML head includes the Google Maps JavaScript script tag:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY_HERE"></script>
```

### 2.3 Backend Environment (`backend/.env`)
```env
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
```

---

## 3. Google Cloud Console Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (for Web)
   - **Directions API**
3. Create an API key under **Credentials** and apply platform restrictions:
   - Android package: `com.trava.trava`
   - Web domain: your domain or `localhost`
