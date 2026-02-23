-- ============================================================================
-- RIDOOO - Delete All Data Script
-- ============================================================================
-- WARNING: This will DELETE ALL DATA from your Supabase database!
-- Run this in the Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Disable Row Level Security temporarily (optional, for faster deletion)
-- ============================================================================

-- If you have RLS enabled and deletions are blocked, run this first:
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE drivers DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE rides DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE driver_offers DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE ratings DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE wallets DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE wallet_transactions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE driver_locations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE saved_places DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE support_messages DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Delete from child tables first (tables with foreign keys)
-- ============================================================================

-- Delete chat messages (if table exists)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'chat_messages') THEN
        DELETE FROM chat_messages WHERE true;
    END IF;
END $$;

-- Delete ratings (references rides, users, drivers)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ratings') THEN
        DELETE FROM ratings WHERE true;
    END IF;
END $$;

-- Delete wallet transactions (references wallets)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'wallet_transactions') THEN
        DELETE FROM wallet_transactions WHERE true;
    END IF;
END $$;

-- Delete driver offers (references rides, drivers)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'driver_offers') THEN
        DELETE FROM driver_offers WHERE true;
    END IF;
END $$;

-- Delete rides (references users, drivers)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'rides') THEN
        DELETE FROM rides WHERE true;
    END IF;
END $$;

-- Delete driver locations (references drivers)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'driver_locations') THEN
        DELETE FROM driver_locations WHERE true;
    END IF;
END $$;

-- Delete saved places (references users)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'saved_places') THEN
        DELETE FROM saved_places WHERE true;
    END IF;
END $$;

-- Delete notifications (references users)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
        DELETE FROM notifications WHERE true;
    END IF;
END $$;

-- Delete support messages (references users)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'support_messages') THEN
        DELETE FROM support_messages WHERE true;
    END IF;
END $$;

-- ============================================================================
-- STEP 3: Delete from parent tables
-- ============================================================================

-- Delete wallets (references users)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'wallets') THEN
        DELETE FROM wallets WHERE true;
    END IF;
END $$;

-- Delete drivers (references users via id)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'drivers') THEN
        DELETE FROM drivers WHERE true;
    END IF;
END $$;

-- Delete users (references auth.users)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        DELETE FROM users WHERE true;
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Delete from Supabase Auth (IMPORTANT!)
-- ============================================================================

-- This deletes all authenticated users from Supabase Auth
-- You need to be careful with this!
DELETE FROM auth.users WHERE true;

-- ============================================================================
-- STEP 5: Re-enable RLS if you disabled it
-- ============================================================================

-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE driver_offers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- VERIFICATION: Check auth.users is empty
-- ============================================================================

SELECT 'auth.users' as table_name, COUNT(*) as row_count FROM auth.users;

-- Check other tables (run separately if needed)
-- SELECT 'users', COUNT(*) FROM users;
-- SELECT 'drivers', COUNT(*) FROM drivers;
-- SELECT 'rides', COUNT(*) FROM rides;

-- ============================================================================
-- ALTERNATIVE: Simple delete just auth users (if above is too complex)
-- ============================================================================

-- Just delete from auth.users - this should cascade or you can delete
-- the public tables manually in Supabase Table Editor
-- DELETE FROM auth.users WHERE true;
