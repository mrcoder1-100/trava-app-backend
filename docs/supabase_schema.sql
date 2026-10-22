-- =====================================================================
-- TRAVA — Supabase / PostgreSQL Production Schema DDL
-- Project: Trava ("People Solving People's Problem")
-- Demonstration City: Coimbatore, Tamil Nadu, India
-- Run this script in: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- =====================================================================

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    "id" TEXT PRIMARY KEY,
    "fullName" TEXT NOT NULL,
    "email" TEXT UNIQUE NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" TEXT DEFAULT 'PASSENGER',
    "pointsBalance" INT DEFAULT 50 CHECK ("pointsBalance" >= 0),
    "isDemoAccount" BOOLEAN DEFAULT FALSE,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Transit Routes (with embedded JSONB stops)
CREATE TABLE IF NOT EXISTS routes (
    "id" TEXT PRIMARY KEY,
    "routeNumber" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT DEFAULT 'Coimbatore',
    "origin" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "distanceKm" NUMERIC(6,2) NOT NULL,
    "estimatedDurationMinutes" INT NOT NULL,
    "status" TEXT DEFAULT 'ACTIVE',
    "stops" JSONB DEFAULT '[]'::jsonb,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Bus Services (Active Fleet & Simulated Vehicles)
CREATE TABLE IF NOT EXISTS bus_services (
    "id" TEXT PRIMARY KEY,
    "busNumber" TEXT NOT NULL,
    "vehicleReg" TEXT NOT NULL,
    "operatorName" TEXT,
    "operatorType" TEXT,
    "serviceType" TEXT,
    "routeId" TEXT REFERENCES routes("id") ON DELETE SET NULL,
    "direction" TEXT DEFAULT 'OUTBOUND',
    "driverName" TEXT,
    "capacity" INT DEFAULT 48,
    "crowdStatus" TEXT DEFAULT 'SEATS_AVAILABLE',
    "trackingStatus" TEXT DEFAULT 'SIMULATED',
    "locationFreshness" TEXT DEFAULT 'LIVE',
    "isSimulated" BOOLEAN DEFAULT TRUE,
    "currentProgress" NUMERIC(6,4) DEFAULT 0.0,
    "speedKmH" INT DEFAULT 30,
    "currentStopId" TEXT,
    "nextStopId" TEXT,
    "currentLatitude" NUMERIC(10,6),
    "currentLongitude" NUMERIC(10,6),
    "bearing" INT DEFAULT 0,
    "etaMinutes" INT DEFAULT 0,
    "activeJourneyId" TEXT,
    "lastUpdated" TIMESTAMPTZ DEFAULT NOW(),
    "activeContributorId" TEXT,
    "activeContributorLabel" TEXT,
    "torchPassedAt" TIMESTAMPTZ,
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Journeys
CREATE TABLE IF NOT EXISTS journeys (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "routeId" TEXT,
    "busId" TEXT,
    "boardingStopId" TEXT,
    "destinationStopId" TEXT,
    "status" TEXT DEFAULT 'ACTIVE',
    "startTime" TIMESTAMPTZ DEFAULT NOW(),
    "endTime" TIMESTAMPTZ,
    "distanceKm" NUMERIC(6,2) DEFAULT 0.0,
    "pointsAwarded" INT DEFAULT 0,
    "gpsPointsCount" INT DEFAULT 0,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 5. GPS Ingestion Records
CREATE TABLE IF NOT EXISTS gps_records (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "journeyId" TEXT,
    "routeId" TEXT,
    "latitude" NUMERIC(10,6) NOT NULL,
    "longitude" NUMERIC(10,6) NOT NULL,
    "accuracy" NUMERIC(6,2),
    "recordedAt" TIMESTAMPTZ NOT NULL,
    "receivedAt" TIMESTAMPTZ DEFAULT NOW(),
    "isSimulated" BOOLEAN DEFAULT FALSE
);

-- 6. Verification Records (Camera / Photo Verification)
CREATE TABLE IF NOT EXISTS verification_records (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "journeyId" TEXT,
    "busId" TEXT,
    "routeId" TEXT,
    "status" TEXT DEFAULT 'VERIFIED',
    "verificationMode" TEXT DEFAULT 'DEMO_MOCK_VERIFICATION',
    "isSimulatedVerification" BOOLEAN DEFAULT TRUE,
    "confidenceScore" NUMERIC(4,2) DEFAULT 0.95,
    "photoBase64" TEXT,
    "capturedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Rewards Points Ledger
CREATE TABLE IF NOT EXISTS rewards (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "type" TEXT NOT NULL,
    "points" INT NOT NULL,
    "balanceAfter" INT NOT NULL,
    "description" TEXT,
    "journeyId" TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Coupons (Guaranteed Scratch-Card Rewards)
CREATE TABLE IF NOT EXISTS coupons (
    "id" TEXT PRIMARY KEY,
    "code" TEXT UNIQUE NOT NULL,
    "userId" TEXT,
    "customerName" TEXT,
    "customerPhone" TEXT,
    "category" TEXT DEFAULT 'BAKERY',
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "offerDetails" TEXT,
    "minSpend" INT DEFAULT 0,
    "cashbackAmount" INT DEFAULT 0,
    "discountAmount" INT NOT NULL,
    "merchantName" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "status" TEXT DEFAULT 'ACTIVE',
    "assignedAt" TIMESTAMPTZ DEFAULT NOW(),
    "expiresAt" TIMESTAMPTZ,
    "redeemedAt" TIMESTAMPTZ,
    "redeemedByMerchant" TEXT,
    "isGuaranteedReward" BOOLEAN DEFAULT TRUE
);

-- 9. Redemptions Audit Log
CREATE TABLE IF NOT EXISTS redemptions (
    "id" TEXT PRIMARY KEY,
    "couponId" TEXT,
    "couponCode" TEXT NOT NULL,
    "userId" TEXT,
    "merchantInfo" TEXT NOT NULL,
    "redeemedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Crowd Reports
CREATE TABLE IF NOT EXISTS crowd_reports (
    "id" TEXT PRIMARY KEY,
    "routeId" TEXT,
    "busId" TEXT,
    "crowdCategory" TEXT NOT NULL,
    "timestamp" TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Notifications
CREATE TABLE IF NOT EXISTS notifications (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "read" BOOLEAN DEFAULT FALSE,
    "timestamp" TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Local Merchant Partners
CREATE TABLE IF NOT EXISTS partners (
    "id" TEXT PRIMARY KEY,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "owner" TEXT,
    "location" TEXT NOT NULL,
    "terminal" TEXT,
    "phone" TEXT,
    "rating" NUMERIC(3,1) DEFAULT 4.5,
    "status" TEXT DEFAULT 'VERIFIED_ACTIVE',
    "activeOffer" TEXT,
    "couponsIssued" INT DEFAULT 0,
    "couponsRedeemed" INT DEFAULT 0,
    "totalCashbackPaid" INT DEFAULT 0,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Sessions
CREATE TABLE IF NOT EXISTS sessions (
    "id" TEXT PRIMARY KEY,
    "userId" TEXT,
    "token" TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Create Fast Query Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users("email");
CREATE INDEX IF NOT EXISTS idx_bus_route ON bus_services("routeId");
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons("code");
CREATE INDEX IF NOT EXISTS idx_coupons_user ON coupons("userId");
CREATE INDEX IF NOT EXISTS idx_journeys_user ON journeys("userId");
CREATE INDEX IF NOT EXISTS idx_gps_journey ON gps_records("journeyId");

-- Disable RLS for unrestricted backend API and client read/write
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE routes DISABLE ROW LEVEL SECURITY;
ALTER TABLE bus_services DISABLE ROW LEVEL SECURITY;
ALTER TABLE journeys DISABLE ROW LEVEL SECURITY;
ALTER TABLE gps_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE verification_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE rewards DISABLE ROW LEVEL SECURITY;
ALTER TABLE coupons DISABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE crowd_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE partners DISABLE ROW LEVEL SECURITY;
ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;
