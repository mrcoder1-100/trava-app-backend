# Project Trava — System Architecture
**App Name:** Trava  
**Official Tagline:** People Solving People's Problem.  
**Subtitle:** Know Where Your Bus Is, on Every Route.  
**Demonstration City:** Coimbatore, Tamil Nadu, India  

---

## 1. High-Level Architecture Overview

Trava is a community-powered public transit tracking platform that delivers predictable, reliable bus-tracking on routes where municipal or private GTFS-RT feeds are absent.

```
                           +-------------------------------------+
                           |            PASSENGERS               |
                           |       (Community Network)           |
                           +-----------------+-------------------+
                                             |
                   +-------------------------+-------------------------+
                   |                                                   |
                   v                                                   v
       [ PASSENGER WAITING AT STOP ]                       [ PASSENGER ON A BUS ]
       - Track Bus Workflow                                - Share GPS Workflow
       - Route 95 Selection                                - Camera Photo Check
       - Live Transit Map                                  - Periodic Verification
       - Dynamic ETA Countdown                             - Contributor Points
       - Crowd Reporting                                   - Scratch Card Rewards
                   |                                                   |
                   |                                                   |
                   v                                                   v
+------------------------------------------------------------------------------------+
|                                 TRAVA MOBILE APP                                    |
|  - Flutter (Material 3 Design System)                                              |
|  - Offline SQLite / In-Memory GPS Queue                                            |
|  - 3-Second Deterministic Intro Animation                                          |
|  - REST HTTP Client (ApiService)                                                   |
+------------------------------------------+-----------------------------------------+
                                           |  REST API (JSON over HTTP)
                                           v
+------------------------------------------------------------------------------------+
|                             TRAVA BACKEND SERVER                                    |
|  - Node.js & Express.js REST Framework                                             |
|  - JWT Authentication & Bcrypt Password Hashing                                    |
|  - Deterministic Bus Simulation Engine (Authoritative Source)                      |
|  - Dynamic Haversine & Route Distance ETA Engine                                   |
|  - Atomic Coupon Ledger & Concurrency Protection                                   |
|  - Pass the Torch Contributor Handoff Service                                      |
+------------------------------------------+-----------------------------------------+
         |                                                   |
         v                                                   v
+------------------------+                         +---------------------------------+
|   LOCAL JSON REPOSITORY|                         |    BAKERY VERIFICATION PORTAL   |
|  - users.json          |                         |  - HTML5 / CSS3 / Vanilla JS    |
|  - sessions.json       |                         |  - Real-time Coupon Validation  |
|  - routes.json         |                         |  - Atomic Mark as Redeemed      |
|  - bus_services.json   |                         |  - Duplicate Replay Prevention  |
|  - journeys.json       |                         +---------------------------------+
|  - gps_records.json    |
|  - verification_records|
|  - rewards.json        |
|  - coupons.json        |
|  - redemptions.json    |
|  - crowd_reports.json  |
|  - notifications.json  |
+------------------------+
```

---

## 2. Core Architectural Principles

1. **Clear Data Distinction**:
   - **Simulated Demonstration Data**: Labelled explicitly with `DEMO MODE · SIMULATED GPS` and `DEMO MODE · MOCK VERIFICATION`.
   - **Genuine GPS Data**: Consenting passengers contributing live coordinates while travelling on the vehicle.
   - **Derived Estimates**: Distance and speed calculations with stop dwell times.
   - **Unavailable / Degraded**: Status indicated clearly when data freshness falls below confidence limits.

2. **Decoupled Roles in a Unified App**:
   - Both passenger tracking and passenger GPS sharing exist in a unified mobile application.
   - A passenger waiting at Gandhipuram uses Track Bus; a passenger travelling between Gandhipuram and Peelamedu uses Share GPS.

3. **Privacy by Design**:
   - Aggregated positions are published to other passengers.
   - Individual contributor identities, personal names, account details, and movement history are strictly masked.

4. **Guaranteed Rewards Model**:
   - Every unlocked scratch card contains a guaranteed, pre-assigned reward.
   - No chance-based outcomes or empty cards.

---

## 3. Component Details

### 3.1 Flutter Mobile Client
- **Animated Intro**: 3.0-second canvas painter rendering road drawing, bus transit, GPS location pin drop, and Trava branding with the official tagline.
- **Track Bus**: City, origin stop, destination stop selection with Route 95 timetable, 4 simulated buses (Bus A, B, C, D), and canvas transit map with real-time ETA countdown.
- **Share GPS**: Explicit consent screen, camera photo verification with mock fallback, live GPS batch streaming, distance counter, and stop journey action.
- **Rewards**: Points ledger, progress to target (100 pts), interactive scratch-to-reveal canvas, and guaranteed coupon cards.

### 3.2 Node.js / Express Backend
- **Data Access Layer**: `JsonDatabase` repository managing safe disk writes, in-memory caching, atomic swaps, and demo resetting.
- **Simulation Service**: Authoritative timer advancing bus progress along Route 95 stop coordinates deterministically every 2 seconds.
- **Dynamic ETA Engine**: Computes distance remaining along polyline segments, accounting for speed and stop dwell times.
- **Rewards & Redemption Service**: Enforces points criteria, ledger transactions, guaranteed coupon assignment, and race-condition-protected atomic redemptions.

### 3.3 Bakery Verification Webpage
- Standalone, responsive shopkeeper portal served directly at `/bakery`.
- Validates coupon codes and executes atomic redemptions.
- Renders `VALID`, `ALREADY USED`, `INVALID COUPON`, and `EXPIRED` status states.
