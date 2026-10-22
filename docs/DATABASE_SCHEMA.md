# Trava Database Schema & Repository Specification
**Database Type:** JSON File-Based Document Repository (with atomic persistence and in-memory cache)  
**Location:** `backend/data/`  
**Ready for Migration to:** PostgreSQL / Supabase  

---

## 1. Collections & Entities

### 1. `users.json`
- `id` (String, PK, e.g. `usr_demo_coimbatore_01`)
- `fullName` (String)
- `email` (String, Unique)
- `passwordHash` (String, Bcrypt hash)
- `role` (String: `PASSENGER`, `MERCHANT`, `ADMIN`)
- `pointsBalance` (Integer)
- `isDemoAccount` (Boolean)
- `createdAt` (ISO 8601 Timestamp)

### 2. `sessions.json`
- `id` (String, PK)
- `userId` (String, FK to `users.id`)
- `tokenHash` (String)
- `expiresAt` (ISO 8601 Timestamp)
- `ipAddress` (String)

### 3. `routes.json`
- `id` (String, PK, e.g. `route_95`)
- `routeNumber` (String, e.g. `"95"`)
- `name` (String: `"Gandhipuram - Singanallur via Peelamedu"`)
- `city` (String: `"Coimbatore"`)
- `origin` (String: `"Gandhipuram"`)
- `destination` (String: `"Singanallur"`)
- `distanceKm` (Float: `11.8`)
- `estimatedDurationMinutes` (Integer: `38`)
- `stops` (Array of Stop objects: `id`, `name`, `shortName`, `sequence`, `latitude`, `longitude`, `isMajorJunction`)
- `direction` (String: `OUTBOUND`, `INBOUND`)
- `isDemoRoute` (Boolean)

### 4. `bus_services.json`
- `id` (String, PK: `bus_95_a`, `bus_95_b`, `bus_95_c`, `bus_95_d`)
- `busNumber` (String: `"Route 95 — Bus A"`)
- `vehicleReg` (String: `"TN 38 N 2481"`)
- `routeId` (String, FK to `routes.id`)
- `currentProgress` (Float: 0.0 to 1.0 along route)
- `speedKmH` (Integer)
- `currentLatitude` (Float)
- `currentLongitude` (Float)
- `bearing` (Integer)
- `etaMinutes` (Integer)
- `distanceRemainingKm` (Float)
- `crowdStatus` (String: `EMPTY`, `SEATS_AVAILABLE`, `PACKED`)
- `trackingStatus` (String: `SIMULATED`, `LIVE_CONTRIBUTOR`)
- `locationFreshness` (String: `LIVE`, `ESTIMATED`, `UNAVAILABLE`)
- `isSimulated` (Boolean)
- `lastUpdated` (ISO 8601 Timestamp)

### 5. `journeys.json`
- `id` (String, PK)
- `userId` (String, FK to `users.id`)
- `routeId` (String, FK to `routes.id`)
- `busId` (String, FK to `bus_services.id`)
- `boardingStopId` (String)
- `destinationStopId` (String)
- `verificationId` (String, FK to `verification_records.id`)
- `status` (String: `ACTIVE`, `COMPLETED`, `CANCELLED`)
- `distanceKm` (Float)
- `pointsAwarded` (Integer)
- `gpsPointsCount` (Integer)
- `startTime` (ISO 8601 Timestamp)
- `endTime` (ISO 8601 Timestamp, nullable)

### 6. `gps_records.json`
- `id` (String, PK)
- `userId` (String, FK to `users.id`)
- `journeyId` (String, FK to `journeys.id`)
- `routeId` (String)
- `latitude` (Float)
- `longitude` (Float)
- `accuracy` (Float)
- `recordedAt` (ISO 8601 Timestamp)
- `receivedAt` (ISO 8601 Timestamp)
- `isSimulated` (Boolean)

### 7. `verification_records.json`
- `id` (String, PK)
- `userId` (String, FK to `users.id`)
- `journeyId` (String, FK to `journeys.id`, nullable)
- `busId` (String)
- `routeId` (String)
- `status` (String: `VERIFIED`, `REJECTED`, `PENDING`)
- `verificationMode` (String: `DEMO_MOCK_VERIFICATION`, `AI_VISION`)
- `isSimulatedVerification` (Boolean)
- `confidenceScore` (Float)
- `capturedAt` (ISO 8601 Timestamp)

### 8. `rewards.json` (Points Ledger)
- `id` (String, PK)
- `userId` (String, FK to `users.id`)
- `type` (String: `WELCOME_BONUS`, `JOURNEY_CONTRIBUTION`, `REDEEM_SPEND`)
- `points` (Integer)
- `balanceAfter` (Integer)
- `description` (String)
- `journeyId` (String, nullable)
- `createdAt` (ISO 8601 Timestamp)

### 9. `coupons.json`
- `id` (String, PK)
- `code` (String, Unique, e.g. `TRAVA-BAKE-95A1`)
- `userId` (String, FK to `users.id`)
- `title` (String)
- `description` (String)
- `discountAmount` (Integer)
- `merchantName` (String: `"Annapoorna Bakery & Sweets"`)
- `location` (String)
- `status` (String: `ACTIVE`, `REDEEMED`, `EXPIRED`)
- `assignedAt` (ISO 8601 Timestamp)
- `expiresAt` (ISO 8601 Timestamp)
- `redeemedAt` (ISO 8601 Timestamp, nullable)
- `isGuaranteedReward` (Boolean)

### 10. `redemptions.json` (Audit Trail)
- `id` (String, PK)
- `couponId` (String, FK to `coupons.id`)
- `couponCode` (String)
- `userId` (String)
- `merchantInfo` (String)
- `redeemedAt` (ISO 8601 Timestamp)

### 11. `crowd_reports.json`
- `id` (String, PK)
- `routeId` (String)
- `busId` (String)
- `crowdCategory` (String: `EMPTY`, `SEATS_AVAILABLE`, `PACKED`)
- `timestamp` (ISO 8601 Timestamp)

### 12. `notifications.json`
- `id` (String, PK)
- `type` (String)
- `message` (String)
- `createdAt` (ISO 8601 Timestamp)

---

## 2. Concurrency & Integrity Safeguards

- **Safe Atomic Writes**: Uses temporary files (`.tmp.<timestamp>`) and atomic swap (`fs.renameSync`) or mutex queuing to prevent corrupt writes during simultaneous operations.
- **Atomic Coupon Redemption**: Redemption status check and state transition occur within a synchronous memory lock before writing to disk, strictly preventing double-spending.
- **Repository Interface**: Business logic in services relies exclusively on standard CRUD methods (`find`, `findById`, `create`, `update`, `delete`), facilitating direct swap to a PostgreSQL client.
