-- =====================================================================
-- TRAVA: Supabase RLS Policies & Column Patch
-- Run this in Supabase Dashboard -> SQL Editor -> New Query -> Run
-- =====================================================================

-- 1. Add missing columns
ALTER TABLE routes ADD COLUMN IF NOT EXISTS "direction" TEXT DEFAULT 'OUTBOUND';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS "type" TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS "busId" TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE notifications ALTER COLUMN "id" DROP NOT NULL;
ALTER TABLE notifications ALTER COLUMN "title" DROP NOT NULL;

-- 2. Grant full CRUD access to anon role for all Trava tables
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'users', 'routes', 'bus_services', 'journeys', 
        'gps_records', 'verification_records', 'rewards', 
        'coupons', 'redemptions', 'crowd_reports', 
        'notifications', 'partners', 'sessions'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "Anon full access %s" ON %I;', tbl, tbl);
        EXECUTE format('CREATE POLICY "Anon full access %s" ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);', tbl, tbl);
    END LOOP;
END $$;
