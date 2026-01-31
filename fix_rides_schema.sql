-- ============================================================================
-- RIDOOO - Fix Rides Table Schema + Enable Realtime
-- ============================================================================
-- Run this script in Supabase SQL Editor to add missing columns
-- This script is safe to run multiple times (uses IF NOT EXISTS logic)
-- ============================================================================

-- ============================================================================
-- STEP 1: Add missing columns to rides table
-- ============================================================================

-- Add pickup_address (alias for pickup_location)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS pickup_address TEXT;

-- Add dropoff_address (alias for dropoff_location)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS dropoff_address TEXT;

-- Add estimated_fare column
ALTER TABLE rides ADD COLUMN IF NOT EXISTS estimated_fare DECIMAL(10,2);

-- Add actual_fare column  
ALTER TABLE rides ADD COLUMN IF NOT EXISTS actual_fare DECIMAL(10,2);

-- Add offered_price column (for InDrive-style bidding)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS offered_price DECIMAL(10,2);

-- Add estimated_duration_minutes column
ALTER TABLE rides ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER;

-- Add payment_method column
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'rides' AND column_name = 'payment_method') THEN
        ALTER TABLE rides ADD COLUMN payment_method TEXT DEFAULT 'cash';
    END IF;
END $$;

-- Add payment_status column
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'rides' AND column_name = 'payment_status') THEN
        ALTER TABLE rides ADD COLUMN payment_status TEXT DEFAULT 'pending';
    END IF;
END $$;

-- Add otp column (alias for ride_otp)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS otp TEXT;

-- ============================================================================
-- STEP 2: Sync existing data if you have old records
-- ============================================================================

-- Copy data from pickup_location to pickup_address if pickup_address is null
UPDATE rides SET pickup_address = pickup_location WHERE pickup_address IS NULL AND pickup_location IS NOT NULL;

-- Copy data from dropoff_location to dropoff_address if dropoff_address is null
UPDATE rides SET dropoff_address = dropoff_location WHERE dropoff_address IS NULL AND dropoff_location IS NOT NULL;

-- Copy data from fare to estimated_fare if estimated_fare is null
UPDATE rides SET estimated_fare = fare WHERE estimated_fare IS NULL AND fare IS NOT NULL;

-- Copy data from duration_min to estimated_duration_minutes if null
UPDATE rides SET estimated_duration_minutes = duration_min WHERE estimated_duration_minutes IS NULL AND duration_min IS NOT NULL;

-- Copy data from ride_otp to otp if otp is null
UPDATE rides SET otp = ride_otp WHERE otp IS NULL AND ride_otp IS NOT NULL;

-- ============================================================================
-- STEP 3: Create trigger to keep columns in sync
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_rides_columns()
RETURNS TRIGGER AS $$
BEGIN
    -- Sync pickup_address and pickup_location
    IF NEW.pickup_address IS NOT NULL AND NEW.pickup_location IS NULL THEN
        NEW.pickup_location = NEW.pickup_address;
    ELSIF NEW.pickup_location IS NOT NULL AND NEW.pickup_address IS NULL THEN
        NEW.pickup_address = NEW.pickup_location;
    END IF;
    
    -- Sync dropoff_address and dropoff_location
    IF NEW.dropoff_address IS NOT NULL AND NEW.dropoff_location IS NULL THEN
        NEW.dropoff_location = NEW.dropoff_address;
    ELSIF NEW.dropoff_location IS NOT NULL AND NEW.dropoff_address IS NULL THEN
        NEW.dropoff_address = NEW.dropoff_location;
    END IF;
    
    -- Sync fare and estimated_fare
    IF NEW.estimated_fare IS NOT NULL AND NEW.fare IS NULL THEN
        NEW.fare = NEW.estimated_fare;
    ELSIF NEW.fare IS NOT NULL AND NEW.estimated_fare IS NULL THEN
        NEW.estimated_fare = NEW.fare;
    END IF;
    
    -- Sync duration_min and estimated_duration_minutes
    IF NEW.estimated_duration_minutes IS NOT NULL AND NEW.duration_min IS NULL THEN
        NEW.duration_min = NEW.estimated_duration_minutes;
    ELSIF NEW.duration_min IS NOT NULL AND NEW.estimated_duration_minutes IS NULL THEN
        NEW.estimated_duration_minutes = NEW.duration_min;
    END IF;
    
    -- Sync otp and ride_otp
    IF NEW.otp IS NOT NULL AND NEW.ride_otp IS NULL THEN
        NEW.ride_otp = NEW.otp;
    ELSIF NEW.ride_otp IS NOT NULL AND NEW.otp IS NULL THEN
        NEW.otp = NEW.ride_otp;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS sync_rides_columns_trigger ON rides;

-- Create the trigger
CREATE TRIGGER sync_rides_columns_trigger
    BEFORE INSERT OR UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION sync_rides_columns();

-- ============================================================================
-- STEP 4: Ensure driver_offers table exists
-- ============================================================================

CREATE TABLE IF NOT EXISTS driver_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(id) ON DELETE CASCADE NOT NULL,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE NOT NULL,
    
    -- Offer details
    offered_price DECIMAL(10,2) NOT NULL CHECK (offered_price > 0),
    estimated_arrival_min INTEGER,
    message TEXT,
    
    -- Driver info (denormalized for quick access)
    driver_name TEXT NOT NULL,
    driver_phone TEXT,
    driver_photo TEXT,
    driver_rating DECIMAL(3,2) DEFAULT 5.0,
    driver_total_rides INTEGER DEFAULT 0,
    vehicle_model TEXT NOT NULL,
    vehicle_color TEXT,
    vehicle_plate TEXT NOT NULL,
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'cancelled')),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '5 minutes'),
    responded_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(ride_id, driver_id)
);

-- Create indexes for driver_offers if they don't exist
CREATE INDEX IF NOT EXISTS idx_driver_offers_ride_id ON driver_offers(ride_id);
CREATE INDEX IF NOT EXISTS idx_driver_offers_driver_id ON driver_offers(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_offers_status ON driver_offers(status);

-- ============================================================================
-- STEP 5: Enable RLS policies for driver_offers
-- ============================================================================

ALTER TABLE driver_offers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view offers for their rides" ON driver_offers;
DROP POLICY IF EXISTS "Drivers can create offers" ON driver_offers;
DROP POLICY IF EXISTS "Drivers can view their own offers" ON driver_offers;
DROP POLICY IF EXISTS "Drivers can update their own offers" ON driver_offers;
DROP POLICY IF EXISTS "Users can update offer status" ON driver_offers;
DROP POLICY IF EXISTS "Anyone can view pending offers" ON driver_offers;

-- Create policies
CREATE POLICY "Users can view offers for their rides" ON driver_offers
    FOR SELECT USING (
        ride_id IN (SELECT id FROM rides WHERE user_id = auth.uid())
        OR driver_id = auth.uid()
    );

CREATE POLICY "Drivers can create offers" ON driver_offers
    FOR INSERT WITH CHECK (
        auth.uid() = driver_id
    );

CREATE POLICY "Drivers can update their own offers" ON driver_offers
    FOR UPDATE USING (auth.uid() = driver_id);

CREATE POLICY "Users can update offer status" ON driver_offers
    FOR UPDATE USING (
        ride_id IN (SELECT id FROM rides WHERE user_id = auth.uid())
    );

-- ============================================================================
-- STEP 6: Fix Rides RLS policies to allow drivers to see searching rides
-- ============================================================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their own rides" ON rides;
DROP POLICY IF EXISTS "Users can create rides" ON rides;
DROP POLICY IF EXISTS "Participants can update their rides" ON rides;
DROP POLICY IF EXISTS "Drivers can view searching rides" ON rides;
DROP POLICY IF EXISTS "Anyone can view searching rides" ON rides;

-- Users can view their own rides (as passenger or driver)
CREATE POLICY "Users can view their own rides" ON rides
    FOR SELECT USING (
        auth.uid() = user_id 
        OR auth.uid() = driver_id
    );

-- CRITICAL: Drivers can see rides that are searching for drivers
CREATE POLICY "Drivers can view searching rides" ON rides
    FOR SELECT USING (
        status = 'searching'
        AND EXISTS (SELECT 1 FROM drivers WHERE id = auth.uid() AND is_available = true)
    );

-- Users can create rides
CREATE POLICY "Users can create rides" ON rides
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Participants can update their rides
CREATE POLICY "Participants can update their rides" ON rides
    FOR UPDATE USING (
        auth.uid() = user_id 
        OR auth.uid() = driver_id
    );

-- ============================================================================
-- STEP 7: Enable Realtime for rides and driver_offers tables
-- ============================================================================

-- Enable realtime publication for rides table
ALTER PUBLICATION supabase_realtime ADD TABLE rides;

-- Enable realtime publication for driver_offers table  
ALTER PUBLICATION supabase_realtime ADD TABLE driver_offers;

-- Enable realtime publication for driver_locations table
ALTER PUBLICATION supabase_realtime ADD TABLE driver_locations;

-- ============================================================================
-- STEP 8: Create indexes for new columns on rides
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_rides_payment_status ON rides(payment_status);
CREATE INDEX IF NOT EXISTS idx_rides_payment_method ON rides(payment_method);
CREATE INDEX IF NOT EXISTS idx_rides_status_searching ON rides(status) WHERE status = 'searching';

-- ============================================================================
-- STEP 9: Update updated_at trigger on driver_offers
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_driver_offers_updated_at ON driver_offers;
CREATE TRIGGER update_driver_offers_updated_at
    BEFORE UPDATE ON driver_offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 10: Create function to notify nearby drivers (optional, for push notifications)
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_new_ride()
RETURNS TRIGGER AS $$
BEGIN
    -- This function can be extended to send push notifications
    -- For now, it just ensures the ride is visible via realtime
    IF NEW.status = 'searching' THEN
        -- The realtime subscription will automatically pick this up
        NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notify_new_ride_trigger ON rides;
CREATE TRIGGER notify_new_ride_trigger
    AFTER INSERT OR UPDATE ON rides
    FOR EACH ROW
    WHEN (NEW.status = 'searching')
    EXECUTE FUNCTION notify_new_ride();

-- ============================================================================
-- DONE! Schema is now fixed and realtime is enabled
-- ============================================================================

-- Verify the rides table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'rides'
ORDER BY ordinal_position;
