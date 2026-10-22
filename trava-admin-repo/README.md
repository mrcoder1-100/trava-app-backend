# TRAVA

> **Official Tagline:** *People Solving People's Problem.*  
> **Subtitle:** *Know Where Your Bus Is, on Every Route.*  
> **Demonstration City:** *Coimbatore, Tamil Nadu, India*  
> 🤖 **Architected & Engineered with IBM Bob** — Autonomous Full-Stack AI Software Development Partner  
> 📖 **Detailed Development Report:** [BUILT_WITH_IBM_BOB.md](file:///c:/Users/thama/OneDrive/Desktop/trava1/BUILT_WITH_IBM_BOB.md)  

---

## 1. Project Overview

**Trava** is a community-powered public bus-tracking platform designed to provide accurate, reliable transit tracking on routes where municipal or private GTFS feeds are unavailable.

- **Passengers waiting for a bus** can track reported positions and dynamic ETAs in real-time.
- **Passengers travelling on a bus** can voluntarily share transit coordinates.
- **Backend simulation & validation** processes GPS records, verifies on-bus presence, and calculates dynamic arrival times.
- **Contributors earn points** for eligible journeys, unlocking **guaranteed scratch-card rewards**.
- **Local bakery & shop partners** validate and redeem customer discount coupons through an independent verification portal.

---

## 2. Phase 1 — End-to-End Demonstration Script

Follow these steps for a complete, repeatable presentation:

1. **Launch Trava App**: Watch the 3-second animated intro displaying the stylized bus, road, GPS pin drop, and the official tagline: *"People Solving People's Problem."*
2. **Log In**: Use the 1-Click Demo Login (`demo@trava.org` / `Password123!`) or register a new test account (+50 welcome points).
3. **Track Bus**:
   - City: **Coimbatore**.
   - Starting point: **Gandhipuram**.
   - Destination: **Singanallur**.
   - Route: **Route 95** (Gandhipuram → Lakshmi Mills → Nava India → Peelamedu → Fun Mall → Singanallur).
   - Select **Route 95 — Bus A**.
   - Open the **Interactive Live Map** to watch the bus marker move along the route with real-time dynamic ETA countdown and the visible `DEMO MODE · SIMULATED GPS` label.
4. **Share GPS & Photo Check**:
   - Open **Share GPS** tab.
   - Choose Route 95, Bus A, Gandhipuram to Singanallur.
   - Tap **Verify Photo & Start Sharing**.
   - Review the camera check screen with the clear `DEMO MODE · MOCK VERIFICATION` label.
   - Capture photo and start journey.
5. **Active Journey & Points Awarding**:
   - Observe live GPS stream transmission and distance accumulation.
   - Tap **Stop Sharing & Claim Points**.
   - The backend processes the journey and awards **+50 points** (reaching the **100 points** target threshold!).
6. **Scratch Card — Guaranteed Reward**:
   - Navigate to the **Rewards** tab.
   - The card is now unlocked: *"Target reached! Your reward card is ready."*
   - Drag finger or mouse across the foil to scratch and reveal the guaranteed reward:
     **Annapoorna Bakery & Sweets — ₹50 Off (Code: `TRAVA-BAKE-95A1`)**.
7. **Bakery Coupon Verification Webpage**:
   - Open `http://localhost:5000/bakery` in a browser.
   - Enter `TRAVA-BAKE-95A1` (or click the quick demo pill).
   - See status: **VALID** (*"This coupon is valid and has not been redeemed."*).
   - Click **✓ Mark as Redeemed**.
   - Re-enter `TRAVA-BAKE-95A1`:
   - See status: **ALREADY USED** (*"This coupon has already been redeemed and cannot be used again."*).
8. **Repeatable Reset**:
   - Tap **↺ Reset Demo Data** (or trigger `POST /api/v1/demo/reset`) to restore pristine baseline demo data anytime.

---

## 3. Technology Stack

- **Mobile Client:** Flutter 3.44.8, Dart 3.12.2, Material 3, Google Maps Flutter (`google_maps_flutter`), Google Fonts, SharedPreferences, HTTP.
- **Backend Server:** Node.js v24, Express.js 4.21, REST APIs v1, Helmet, CORS, Morgan, JWT, Bcrypt.
- **Database:** Local JSON File-Based Document Repository with atomic file writes and in-memory caching (`backend/data/`).
- **Web Portals:** Responsive HTML5, Vanilla CSS3, JavaScript (Super Admin Command Center & Merchant Verification).
- **AI Engineering Partner:** **IBM Bob** — Autonomous Spec-Driven Full-Stack Software Engineering.

---

## 4. How to Run

### Step 1: Start the Backend Server
```bash
cd backend
npm install
node src/server.js
```
The server will start on `http://localhost:5000` and display:
- API endpoints: `http://localhost:5000/api/v1`
- Bakery Verification Webpage: `http://localhost:5000/bakery`
- Health check: `http://localhost:5000/health`

### Step 2: Open the Bakery Verification Webpage
Visit:
```
http://localhost:5000/bakery
```

### Step 3: Run the Flutter Mobile Application
In a separate terminal:
```bash
cd mobile
flutter run -d chrome
# Or run on Windows desktop / connected Android device:
# flutter run -d windows
```

---

## 5. Automated Tests

### Run Backend Tests (18 test suites passing):
```bash
cd backend
npm test
```

### Run Flutter Analysis & Tests:
```bash
cd mobile
flutter test
flutter analyze
```

---

## 6. Project Structure

```
trava/
├── backend/
│   ├── src/
│   │   ├── config/index.js
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── repositories/db.js
│   │   ├── routes/
│   │   ├── services/
│   │   ├── utils/geo.js
│   │   ├── app.js
│   │   └── server.js
│   ├── data/                 # 12 JSON repository files
│   ├── tests/api.test.js     # 18 automated Jest tests
│   ├── .env.example
│   └── package.json
├── mobile/
│   ├── lib/
│   │   ├── core/             # Theme, constants, API client
│   │   ├── models/           # User, route, bus, journey, coupon
│   │   ├── services/         # ApiService & offline queue
│   │   ├── features/
│   │   │   ├── intro/        # 3-Second animated intro
│   │   │   ├── auth/         # Login & Register
│   │   │   ├── home/         # Main 5-tab navigation & Home tab
│   │   │   ├── tracking/     # Track Bus & Interactive Canvas Map
│   │   │   ├── gps_sharing/  # Share GPS & Active Sharing
│   │   │   ├── verification/ # Camera check with mock mode
│   │   │   ├── rewards/      # Points & Interactive Scratch Card
│   │   │   └── profile/      # User profile, privacy & demo reset
│   │   └── main.dart
│   ├── test/widget_test.dart
│   └── pubspec.yaml
├── bakery-web/
│   ├── index.html            # Shopkeeper verification portal
│   ├── style.css
│   ├── app.js
│   └── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DATABASE_SCHEMA.md
│   ├── SUPABASE_MIGRATION.md
│   ├── GOOGLE_MAPS_SETUP.md
│   ├── AI_INTEGRATION.md
│   └── TESTING.md
├── .gitignore
└── README.md
```

---

## 7. Known Limitations & Next Steps

1. **Simulation vs Real GPS**: The application uses simulated bus coordinates to demonstrate reliable tracking without requiring live city-wide contributor density. The architecture seamlessly replaces simulated feeds with real passenger records.
2. **Vision API**: Uses a clearly labelled mock verification mode when `VISION_API_KEY` is omitted, eliminating third-party cost and failure points during judge evaluations.
3. **Database Migration**: The JSON repository interfaces are built to directly transition to PostgreSQL on Supabase via the provided DDL schema (`docs/SUPABASE_MIGRATION.md`).
