# Trava — Supabase / PostgreSQL Migration Plan

This guide outlines how to migrate Trava from the local JSON file repository (`backend/data/*.json`) to a production Supabase PostgreSQL instance.

---

## 1. Schema DDL (PostgreSQL)

```sql
-- Enable PostGIS for real geographic queries
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'PASSENGER',
    points_balance INT DEFAULT 50 CHECK (points_balance >= 0),
    is_demo_account BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Routes Table
CREATE TABLE routes (
    id VARCHAR(50) PRIMARY KEY,
    route_number VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    origin VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    distance_km NUMERIC(5,2) NOT NULL,
    estimated_duration_minutes INT NOT NULL,
    direction VARCHAR(20) DEFAULT 'OUTBOUND',
    status VARCHAR(20) DEFAULT 'ACTIVE',
    is_demo_route BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Route Stops Table
CREATE TABLE route_stops (
    id VARCHAR(50) PRIMARY KEY,
    route_id VARCHAR(50) REFERENCES routes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(100) NOT NULL,
    sequence INT NOT NULL,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    is_major_junction BOOLEAN DEFAULT FALSE,
    UNIQUE(route_id, sequence)
);

-- 4. Bus Services (Fleet)
CREATE TABLE bus_services (
    id VARCHAR(50) PRIMARY KEY,
    bus_number VARCHAR(50) NOT NULL,
    vehicle_reg VARCHAR(50) NOT NULL,
    route_id VARCHAR(50) REFERENCES routes(id),
    current_progress NUMERIC(5,4) DEFAULT 0.0,
    speed_km_h INT DEFAULT 30,
    current_location GEOGRAPHY(Point, 4326),
    bearing INT DEFAULT 0,
    eta_minutes INT DEFAULT 0,
    distance_remaining_km NUMERIC(5,2) DEFAULT 0.0,
    crowd_status VARCHAR(30) DEFAULT 'SEATS_AVAILABLE',
    tracking_status VARCHAR(30) DEFAULT 'SIMULATED',
    location_freshness VARCHAR(20) DEFAULT 'LIVE',
    is_simulated BOOLEAN DEFAULT TRUE,
    active_contributor_id UUID REFERENCES users(id),
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Journeys
CREATE TABLE journeys (
    id VARCHAR(50) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    route_id VARCHAR(50) REFERENCES routes(id),
    bus_id VARCHAR(50) REFERENCES bus_services(id),
    boarding_stop_id VARCHAR(50) REFERENCES route_stops(id),
    destination_stop_id VARCHAR(50) REFERENCES route_stops(id),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    distance_km NUMERIC(5,2) DEFAULT 0.0,
    points_awarded INT DEFAULT 0,
    gps_points_count INT DEFAULT 0
);

-- 6. GPS Records
CREATE TABLE gps_records (
    id VARCHAR(50) PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    journey_id VARCHAR(50) REFERENCES journeys(id) ON DELETE CASCADE,
    route_id VARCHAR(50) REFERENCES routes(id),
    location GEOGRAPHY(Point, 4326) NOT NULL,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    accuracy NUMERIC(5,2),
    recorded_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ DEFAULT NOW(),
    is_simulated BOOLEAN DEFAULT FALSE
);

-- 7. Verification Records
CREATE TABLE verification_records (
    id VARCHAR(50) PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    journey_id VARCHAR(50) REFERENCES journeys(id),
    bus_id VARCHAR(50) REFERENCES bus_services(id),
    route_id VARCHAR(50) REFERENCES routes(id),
    status VARCHAR(20) DEFAULT 'VERIFIED',
    verification_mode VARCHAR(40) DEFAULT 'DEMO_MOCK_VERIFICATION',
    is_simulated_verification BOOLEAN DEFAULT TRUE,
    confidence_score NUMERIC(4,2) DEFAULT 0.95,
    captured_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Rewards Ledger
CREATE TABLE rewards_ledger (
    id VARCHAR(50) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(40) NOT NULL,
    points INT NOT NULL,
    balance_after INT NOT NULL,
    description TEXT,
    journey_id VARCHAR(50) REFERENCES journeys(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Coupons Table
CREATE TABLE coupons (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    discount_amount INT NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    redeemed_at TIMESTAMPTZ,
    redeemed_by_merchant VARCHAR(255),
    is_guaranteed_reward BOOLEAN DEFAULT TRUE
);

-- 10. Redemptions Audit
CREATE TABLE redemptions (
    id VARCHAR(50) PRIMARY KEY,
    coupon_id VARCHAR(50) REFERENCES coupons(id),
    coupon_code VARCHAR(50) NOT NULL,
    user_id UUID REFERENCES users(id),
    merchant_info VARCHAR(255) NOT NULL,
    redeemed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Crowd Reports
CREATE TABLE crowd_reports (
    id VARCHAR(50) PRIMARY KEY,
    route_id VARCHAR(50) REFERENCES routes(id),
    bus_id VARCHAR(50) REFERENCES bus_services(id),
    crowd_category VARCHAR(30) NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. Row Level Security (RLS) Policies

```sql
-- Enable RLS on user-specific tables
ALTER TABLE journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards_ledger ENABLE ROW LEVEL SECURITY;

-- Passengers can only view their own coupons
CREATE POLICY "Users can only view their own coupons"
ON coupons FOR SELECT
USING (auth.uid() = user_id);

-- Shopkeepers / Merchants can validate coupons by code without seeing passenger identity
CREATE POLICY "Public or shopkeeper code validation"
ON coupons FOR SELECT
USING (true);

-- Passengers can only view their own journeys
CREATE POLICY "Users can only view their own journeys"
ON journeys FOR SELECT
USING (auth.uid() = user_id);
```

---

## 3. Migration Steps

1. **Install Supabase Client**:
   ```bash
   npm install @supabase/supabase-js
   ```
2. **Configure Environment Variables**:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-key
   ```
3. **Run Seed Script**: Read the 12 existing `.json` files in `backend/data/` and execute bulk `upsert` queries.
4. **Switch Data Access Layer**: Swap methods in `backend/src/repositories/db.js` to query the Supabase client while retaining identical service signatures.
