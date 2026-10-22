# Trava REST API Documentation — v1
**Base URL:** `http://localhost:5000/api/v1`  
**Authentication:** `Bearer <JWT_TOKEN>` in Authorization header.

---

## 1. Authentication

### Register
- **URL:** `POST /api/v1/auth/register`
- **Body:**
  ```json
  {
    "fullName": "Ramesh Kumar",
    "email": "ramesh@example.com",
    "password": "Password123!"
  }
  ```
- **Response (201):**
  ```json
  {
    "success": true,
    "message": "User registered successfully",
    "user": {
      "id": "usr_abc12345",
      "fullName": "Ramesh Kumar",
      "email": "ramesh@example.com",
      "role": "PASSENGER",
      "pointsBalance": 50
    },
    "token": "eyJhbGciOi..."
  }
  ```

### Login
- **URL:** `POST /api/v1/auth/login`
- **Body:**
  ```json
  {
    "email": "demo@trava.org",
    "password": "Password123!"
  }
  ```
- **Response (200):**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "user": {
      "id": "usr_demo_coimbatore_01",
      "fullName": "Demo Passenger",
      "email": "demo@trava.org",
      "pointsBalance": 50
    },
    "token": "eyJhbGciOi..."
  }
  ```

---

## 2. Routes & Stops

### Get All Routes
- **URL:** `GET /api/v1/routes`
- **Response (200):**
  ```json
  {
    "success": true,
    "count": 1,
    "data": [
      {
        "id": "route_95",
        "routeNumber": "95",
        "name": "Gandhipuram - Singanallur via Peelamedu",
        "city": "Coimbatore",
        "origin": "Gandhipuram",
        "destination": "Singanallur",
        "distanceKm": 11.8,
        "stops": [...]
      }
    ]
  }
  ```

### Get Route Stops
- **URL:** `GET /api/v1/routes/:id/stops`
- **Response (200):** Array of stop objects including coordinates and sequences.

---

## 3. Bus Tracking & Simulation

### Get Route Buses
- **URL:** `GET /api/v1/routes/:id/buses`
- **Response (200):**
  ```json
  {
    "success": true,
    "routeId": "route_95",
    "count": 4,
    "isSimulatedData": true,
    "demoLabel": "DEMO MODE · SIMULATED GPS",
    "data": [
      {
        "id": "bus_95_a",
        "busNumber": "Route 95 — Bus A",
        "vehicleReg": "TN 38 N 2481",
        "currentProgress": 0.15,
        "speedKmH": 32,
        "etaMinutes": 26,
        "crowdStatus": "SEATS_AVAILABLE"
      }
    ]
  }
  ```

### Get Live Bus Status
- **URL:** `GET /api/v1/buses/:id/live`
- **Response (200):**
  ```json
  {
    "success": true,
    "busId": "bus_95_a",
    "latitude": 11.016844,
    "longitude": 76.967812,
    "bearing": 110,
    "etaMinutes": 26,
    "distanceRemainingKm": 9.8,
    "demoLabel": "DEMO MODE · SIMULATED GPS",
    "lastUpdated": "2026-10-19T13:30:00Z"
  }
  ```

---

## 4. Journeys & GPS Contribution

### Start Journey
- **URL:** `POST /api/v1/journeys/start`
- **Body:**
  ```json
  {
    "routeId": "route_95",
    "busId": "bus_95_a",
    "boardingStopId": "stop_gandhipuram",
    "destinationStopId": "stop_singanallur",
    "mockVerification": true
  }
  ```

### Stop Journey & Award Points
- **URL:** `POST /api/v1/journeys/:id/stop`
- **Response (200):**
  ```json
  {
    "success": true,
    "journey": {
      "id": "jrn_12345",
      "status": "COMPLETED",
      "pointsAwarded": 50
    },
    "pointsResult": {
      "isEligible": true,
      "pointsAwarded": 50,
      "currentBalance": 100,
      "unlockedCard": {
        "id": "sc_789",
        "isGuaranteedReward": true
      }
    }
  }
  ```

---

## 5. Bakery Coupon Verification & Redemption

### Validate Coupon (Shopkeeper Portal)
- **URL:** `POST /api/v1/coupons/validate`
- **Body:** `{ "code": "TRAVA-BAKE-95A1" }`
- **Status Responses:**
  - `VALID` (200): Unredeemed, active coupon with discount details.
  - `ALREADY_USED` (200): Already redeemed; shows redemption timestamp.
  - `EXPIRED` (200): Past expiry date.
  - `INVALID_COUPON` (200/400): Code not found.

### Redeem Coupon (Atomic)
- **URL:** `POST /api/v1/coupons/redeem` (or `POST /api/v1/coupons/:id/redeem`)
- **Body:**
  ```json
  {
    "code": "TRAVA-BAKE-95A1",
    "merchantInfo": "Annapoorna Bakery Gandhipuram Counter #1"
  }
  ```
- **Response (200):**
  ```json
  {
    "success": true,
    "status": "REDEEMED_SUCCESSFULLY",
    "message": "Coupon redeemed successfully!"
  }
  ```

---

## 6. Demonstration Controls

- `POST /api/v1/demo/reset`: Restores all routes, 4 buses, demo user, and coupons to baseline state.
- `POST /api/v1/demo/tick`: Manually advances simulation by specified seconds.
- `POST /api/v1/demo/pass-the-torch`: Simulates contributor handoff without tracking drop.
