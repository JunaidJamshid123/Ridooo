-- ============================================================================
-- RIDOOO - Complete Database Schema for Supabase (V2 - Fixed)
-- ============================================================================
-- Run this script in Supabase SQL Editor
-- This script handles existing tables and adds missing columns
-- ============================================================================

-- ============================================================================
-- SECTION 1: EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- SECTION 2: HELPER FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 3: DROP EXISTING VIEWS (to avoid column reference errors)
-- ============================================================================

DROP VIEW IF EXISTS driver_earnings CASCADE;
DROP VIEW IF EXISTS ride_details CASCADE;

-- ============================================================================
-- SECTION 4: CORE TABLES
-- ============================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT,
    profile_image TEXT,
    role TEXT NOT NULL CHECK (role IN ('user', 'driver')),
    license_number TEXT,
    vehicle_model TEXT,
    vehicle_plate TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drivers table
CREATE TABLE IF NOT EXISTS drivers (
    id UUID REFERENCES users(id) PRIMARY KEY,
    license_number TEXT NOT NULL,
    vehicle_model TEXT NOT NULL,
    vehicle_plate TEXT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 5.0,
    total_rides INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 5: VEHICLE & FARE CONFIGURATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS vehicle_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    capacity INTEGER DEFAULT 4,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fare_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_type_id UUID REFERENCES vehicle_types(id) NOT NULL,
    city TEXT DEFAULT 'default',
    base_fare DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    per_km_rate DECIMAL(10,2) NOT NULL DEFAULT 12.00,
    per_min_rate DECIMAL(10,2) NOT NULL DEFAULT 2.00,
    min_fare DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    booking_fee DECIMAL(10,2) DEFAULT 10.00,
    surge_multiplier DECIMAL(3,2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vehicle_type_id, city)
);

-- Insert default vehicle types
INSERT INTO vehicle_types (name, description, capacity, sort_order) VALUES
    ('bike', 'Motorcycle - Quick & Affordable', 1, 1),
    ('economy', 'Economy Car - Budget Friendly', 4, 2),
    ('comfort', 'Comfort Car - Extra Space', 4, 3),
    ('premium', 'Premium Car - Luxury Ride', 4, 4),
    ('suv', 'SUV - For Groups', 6, 5)
ON CONFLICT (name) DO NOTHING;

-- Insert default fare configs
INSERT INTO fare_configs (vehicle_type_id, city, base_fare, per_km_rate, per_min_rate, min_fare)
SELECT id, 'default', 
    CASE name 
        WHEN 'bike' THEN 20.00
        WHEN 'economy' THEN 40.00
        WHEN 'comfort' THEN 60.00
        WHEN 'premium' THEN 100.00
        WHEN 'suv' THEN 80.00
    END,
    CASE name 
        WHEN 'bike' THEN 8.00
        WHEN 'economy' THEN 12.00
        WHEN 'comfort' THEN 15.00
        WHEN 'premium' THEN 25.00
        WHEN 'suv' THEN 18.00
    END,
    CASE name 
        WHEN 'bike' THEN 1.00
        WHEN 'economy' THEN 2.00
        WHEN 'comfort' THEN 2.50
        WHEN 'premium' THEN 4.00
        WHEN 'suv' THEN 3.00
    END,
    CASE name 
        WHEN 'bike' THEN 25.00
        WHEN 'economy' THEN 50.00
        WHEN 'comfort' THEN 80.00
        WHEN 'premium' THEN 150.00
        WHEN 'suv' THEN 100.00
    END
FROM vehicle_types
ON CONFLICT (vehicle_type_id, city) DO NOTHING;

-- ============================================================================
-- SECTION 6: PROMO CODES
-- ============================================================================

CREATE TABLE IF NOT EXISTS promo_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10,2) NOT NULL,
    max_discount DECIMAL(10,2),
    min_ride_amount DECIMAL(10,2) DEFAULT 0,
    max_usage INTEGER,
    usage_count INTEGER DEFAULT 0,
    max_usage_per_user INTEGER DEFAULT 1,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 7: RIDES TABLE - DROP AND RECREATE
-- ============================================================================

-- First drop dependent tables
DROP TABLE IF EXISTS ride_requests CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS user_promo_usage CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;

-- Now drop and recreate rides table with all columns
DROP TABLE IF EXISTS rides CASCADE;

CREATE TABLE rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    driver_id UUID REFERENCES drivers(id),
    
    -- Locations
    pickup_location TEXT NOT NULL,
    dropoff_location TEXT NOT NULL,
    pickup_latitude DECIMAL(10,8) NOT NULL,
    pickup_longitude DECIMAL(11,8) NOT NULL,
    dropoff_latitude DECIMAL(10,8) NOT NULL,
    dropoff_longitude DECIMAL(11,8) NOT NULL,
    
    -- Ride details
    vehicle_type TEXT NOT NULL,
    distance_km DECIMAL(10,2),
    duration_min INTEGER,
    
    -- Pricing
    fare DECIMAL(10,2) NOT NULL,
    base_fare DECIMAL(10,2),
    distance_fare DECIMAL(10,2),
    time_fare DECIMAL(10,2),
    surge_multiplier DECIMAL(3,2) DEFAULT 1.00,
    promo_code_id UUID REFERENCES promo_codes(id),
    discount_amount DECIMAL(10,2) DEFAULT 0,
    final_fare DECIMAL(10,2),
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'searching', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled')),
    
    -- Timestamps
    scheduled_at TIMESTAMP WITH TIME ZONE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    arrived_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    
    -- Cancellation
    cancelled_by UUID REFERENCES users(id),
    cancellation_reason TEXT,
    
    -- OTP for ride verification
    ride_otp TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 8: USER PROMO USAGE
-- ============================================================================

CREATE TABLE user_promo_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    promo_code_id UUID REFERENCES promo_codes(id) NOT NULL,
    ride_id UUID REFERENCES rides(id),
    discount_amount DECIMAL(10,2),
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, promo_code_id, ride_id)
);

-- ============================================================================
-- SECTION 9: RIDE REQUESTS
-- ============================================================================

CREATE TABLE ride_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(id) NOT NULL,
    driver_id UUID REFERENCES drivers(id) NOT NULL,
    status TEXT NOT NULL DEFAULT 'sent' 
        CHECK (status IN ('sent', 'viewed', 'accepted', 'rejected', 'expired')),
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 seconds'),
    UNIQUE(ride_id, driver_id)
);

-- ============================================================================
-- SECTION 10: DRIVER LOCATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS driver_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID REFERENCES drivers(id) NOT NULL UNIQUE,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    heading DECIMAL(5,2),
    speed DECIMAL(5,2),
    accuracy DECIMAL(8,2),
    is_online BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 11: WALLETS & TRANSACTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL UNIQUE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'PKR',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    amount DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    description TEXT,
    reference_type TEXT CHECK (reference_type IN ('ride_payment', 'refund', 'top_up', 'withdrawal', 'promo_credit', 'referral')),
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 12: PAYMENTS
-- ============================================================================

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(id) NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id) NOT NULL,
    driver_id UUID REFERENCES drivers(id),
    
    amount DECIMAL(10,2) NOT NULL,
    tip_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'wallet', 'card', 'upi')),
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    
    transaction_id TEXT,
    gateway_response JSONB,
    
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 13: RATINGS
-- ============================================================================

CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(id) NOT NULL,
    reviewer_id UUID REFERENCES users(id) NOT NULL,
    reviewee_id UUID REFERENCES users(id) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ride_id, reviewer_id)
);

-- ============================================================================
-- SECTION 14: SAVED PLACES
-- ============================================================================

CREATE TABLE IF NOT EXISTS saved_places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    label TEXT NOT NULL,
    name TEXT,
    address TEXT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    icon TEXT DEFAULT 'place',
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 15: NOTIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'ride_request', 'ride_accepted', 'driver_arrived', 'ride_started', 
        'ride_completed', 'ride_cancelled', 'payment', 'promo', 'rating',
        'wallet', 'system', 'chat'
    )),
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 16: SUPPORT
-- ============================================================================

CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) NOT NULL,
    ride_id UUID REFERENCES rides(id),
    
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT CHECK (category IN ('ride_issue', 'payment', 'driver_behavior', 'safety', 'lost_item', 'other')),
    
    status TEXT NOT NULL DEFAULT 'open' 
        CHECK (status IN ('open', 'in_progress', 'waiting_user', 'resolved', 'closed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    assigned_to TEXT,
    resolution TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID REFERENCES support_tickets(id) NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'support')),
    sender_id TEXT,
    message TEXT NOT NULL,
    attachments TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECTION 17: LOOKUP TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS cancellation_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reason TEXT NOT NULL,
    for_role TEXT NOT NULL CHECK (for_role IN ('user', 'driver', 'both')),
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0
);

INSERT INTO cancellation_reasons (reason, for_role, sort_order) VALUES
    ('Driver took too long', 'user', 1),
    ('Changed my plans', 'user', 2),
    ('Booked by mistake', 'user', 3),
    ('Driver asked to cancel', 'user', 4),
    ('Found another ride', 'user', 5),
    ('Other reason', 'user', 6),
    ('Passenger not at pickup', 'driver', 1),
    ('Passenger not responding', 'driver', 2),
    ('Wrong pickup location', 'driver', 3),
    ('Vehicle issue', 'driver', 4),
    ('Emergency', 'both', 5),
    ('Other reason', 'driver', 6)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    data_type TEXT DEFAULT 'string' CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO app_settings (key, value, description, data_type) VALUES
    ('max_search_radius_km', '10', 'Maximum radius to search for drivers', 'number'),
    ('ride_request_timeout_seconds', '30', 'Time for driver to respond to ride request', 'number'),
    ('max_ride_requests_per_driver', '3', 'Max concurrent ride requests to a driver', 'number'),
    ('cancellation_fee_percentage', '10', 'Cancellation fee as percentage of fare', 'number'),
    ('free_cancellation_minutes', '2', 'Minutes within which cancellation is free', 'number'),
    ('min_wallet_balance', '0', 'Minimum wallet balance allowed', 'number'),
    ('referral_bonus_amount', '100', 'Bonus amount for successful referral', 'number'),
    ('support_email', 'support@ridooo.com', 'Support email address', 'string'),
    ('support_phone', '+923001234567', 'Support phone number', 'string')
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- SECTION 18: TRIGGERS
-- ============================================================================

-- Drop existing triggers first to avoid errors
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_drivers_updated_at ON drivers;
DROP TRIGGER IF EXISTS update_rides_updated_at ON rides;
DROP TRIGGER IF EXISTS update_wallets_updated_at ON wallets;
DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
DROP TRIGGER IF EXISTS update_fare_configs_updated_at ON fare_configs;
DROP TRIGGER IF EXISTS update_saved_places_updated_at ON saved_places;
DROP TRIGGER IF EXISTS update_support_tickets_updated_at ON support_tickets;
DROP TRIGGER IF EXISTS update_driver_locations_updated_at ON driver_locations;
DROP TRIGGER IF EXISTS update_driver_rating_trigger ON ratings;

-- Create triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at 
    BEFORE UPDATE ON drivers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rides_updated_at 
    BEFORE UPDATE ON rides 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at 
    BEFORE UPDATE ON wallets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at 
    BEFORE UPDATE ON payments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fare_configs_updated_at 
    BEFORE UPDATE ON fare_configs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saved_places_updated_at 
    BEFORE UPDATE ON saved_places 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at 
    BEFORE UPDATE ON support_tickets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_locations_updated_at 
    BEFORE UPDATE ON driver_locations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 19: ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_promo_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancellation_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Anyone can insert during signup" ON users;
DROP POLICY IF EXISTS "Drivers can view their own data" ON drivers;
DROP POLICY IF EXISTS "Drivers can update their own data" ON drivers;
DROP POLICY IF EXISTS "Anyone can insert during driver signup" ON drivers;
DROP POLICY IF EXISTS "Users can view available drivers" ON drivers;
DROP POLICY IF EXISTS "Drivers can manage their own location" ON driver_locations;
DROP POLICY IF EXISTS "Users can view online driver locations" ON driver_locations;
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "System can create wallets" ON wallets;
DROP POLICY IF EXISTS "Users can view their own transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "System can insert transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Users can manage their own saved places" ON saved_places;
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view their own rides" ON rides;
DROP POLICY IF EXISTS "Users can create rides" ON rides;
DROP POLICY IF EXISTS "Participants can update their rides" ON rides;
DROP POLICY IF EXISTS "Drivers can view their ride requests" ON ride_requests;
DROP POLICY IF EXISTS "Drivers can update their ride requests" ON ride_requests;
DROP POLICY IF EXISTS "System can create ride requests" ON ride_requests;
DROP POLICY IF EXISTS "Users can view their own payments" ON payments;
DROP POLICY IF EXISTS "System can manage payments" ON payments;
DROP POLICY IF EXISTS "Users can view ratings" ON ratings;
DROP POLICY IF EXISTS "Users can create ratings for their rides" ON ratings;
DROP POLICY IF EXISTS "Anyone can view active promo codes" ON promo_codes;
DROP POLICY IF EXISTS "Users can view their own promo usage" ON user_promo_usage;
DROP POLICY IF EXISTS "Users can create their own promo usage" ON user_promo_usage;
DROP POLICY IF EXISTS "Users can manage their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Users can view messages on their tickets" ON support_messages;
DROP POLICY IF EXISTS "Users can add messages to their tickets" ON support_messages;
DROP POLICY IF EXISTS "Anyone can view vehicle types" ON vehicle_types;
DROP POLICY IF EXISTS "Anyone can view fare configs" ON fare_configs;
DROP POLICY IF EXISTS "Anyone can view cancellation reasons" ON cancellation_reasons;
DROP POLICY IF EXISTS "Anyone can view app settings" ON app_settings;

-- USERS
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can insert during signup" ON users
    FOR INSERT WITH CHECK (true);

-- DRIVERS
CREATE POLICY "Drivers can view their own data" ON drivers
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Drivers can update their own data" ON drivers
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can insert during driver signup" ON drivers
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view available drivers" ON drivers
    FOR SELECT USING (is_available = true);

-- DRIVER LOCATIONS
CREATE POLICY "Drivers can manage their own location" ON driver_locations
    FOR ALL USING (auth.uid() = driver_id);

CREATE POLICY "Users can view online driver locations" ON driver_locations
    FOR SELECT USING (is_online = true);

-- WALLETS
CREATE POLICY "Users can view their own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create wallets" ON wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- WALLET TRANSACTIONS
CREATE POLICY "Users can view their own transactions" ON wallet_transactions
    FOR SELECT USING (
        wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
    );

CREATE POLICY "System can insert transactions" ON wallet_transactions
    FOR INSERT WITH CHECK (
        wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
    );

-- SAVED PLACES
CREATE POLICY "Users can manage their own saved places" ON saved_places
    FOR ALL USING (auth.uid() = user_id);

-- NOTIFICATIONS
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- RIDES
CREATE POLICY "Users can view their own rides" ON rides
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = driver_id);

CREATE POLICY "Users can create rides" ON rides
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Participants can update their rides" ON rides
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = driver_id);

-- RIDE REQUESTS
CREATE POLICY "Drivers can view their ride requests" ON ride_requests
    FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their ride requests" ON ride_requests
    FOR UPDATE USING (auth.uid() = driver_id);

CREATE POLICY "System can create ride requests" ON ride_requests
    FOR INSERT WITH CHECK (true);

-- PAYMENTS
CREATE POLICY "Users can view their own payments" ON payments
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = driver_id);

CREATE POLICY "System can manage payments" ON payments
    FOR ALL WITH CHECK (auth.uid() = user_id);

-- RATINGS
CREATE POLICY "Users can view ratings" ON ratings
    FOR SELECT USING (
        auth.uid() = reviewer_id OR 
        auth.uid() = reviewee_id OR
        ride_id IN (SELECT id FROM rides WHERE user_id = auth.uid() OR driver_id = auth.uid())
    );

CREATE POLICY "Users can create ratings for their rides" ON ratings
    FOR INSERT WITH CHECK (
        auth.uid() = reviewer_id AND
        ride_id IN (SELECT id FROM rides WHERE user_id = auth.uid() OR driver_id = auth.uid())
    );

-- PROMO CODES
CREATE POLICY "Anyone can view active promo codes" ON promo_codes
    FOR SELECT USING (is_active = true);

-- USER PROMO USAGE
CREATE POLICY "Users can view their own promo usage" ON user_promo_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own promo usage" ON user_promo_usage
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- SUPPORT TICKETS
CREATE POLICY "Users can manage their own tickets" ON support_tickets
    FOR ALL USING (auth.uid() = user_id);

-- SUPPORT MESSAGES
CREATE POLICY "Users can view messages on their tickets" ON support_messages
    FOR SELECT USING (
        ticket_id IN (SELECT id FROM support_tickets WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can add messages to their tickets" ON support_messages
    FOR INSERT WITH CHECK (
        ticket_id IN (SELECT id FROM support_tickets WHERE user_id = auth.uid()) AND
        sender_type = 'user'
    );

-- PUBLIC TABLES
CREATE POLICY "Anyone can view vehicle types" ON vehicle_types
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view fare configs" ON fare_configs
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view cancellation reasons" ON cancellation_reasons
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view app settings" ON app_settings
    FOR SELECT USING (true);

-- ============================================================================
-- SECTION 20: INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_drivers_is_available ON drivers(is_available);
CREATE INDEX IF NOT EXISTS idx_drivers_rating ON drivers(rating);
CREATE INDEX IF NOT EXISTS idx_driver_locations_coords ON driver_locations(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_driver_locations_is_online ON driver_locations(is_online);
CREATE INDEX IF NOT EXISTS idx_rides_user_id ON rides(user_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver_id ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created_at ON rides(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rides_completed_at ON rides(completed_at);
CREATE INDEX IF NOT EXISTS idx_ride_requests_ride_id ON ride_requests(ride_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver_id ON ride_requests(driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests(status);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ratings_reviewee_id ON ratings(reviewee_id);

-- ============================================================================
-- SECTION 21: VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW ride_details AS
SELECT 
    r.*,
    u.name as user_name,
    u.phone_number as user_phone,
    u.profile_image as user_image,
    d_user.name as driver_name,
    d_user.phone_number as driver_phone,
    d_user.profile_image as driver_image,
    d.vehicle_model as driver_vehicle_model,
    d.vehicle_plate as driver_vehicle_plate,
    d.rating as driver_rating
FROM rides r
LEFT JOIN users u ON r.user_id = u.id
LEFT JOIN drivers d ON r.driver_id = d.id
LEFT JOIN users d_user ON d.id = d_user.id;

CREATE OR REPLACE VIEW driver_earnings AS
SELECT 
    d.id as driver_id,
    COUNT(r.id) as total_rides,
    COALESCE(SUM(CASE WHEN r.completed_at >= NOW() - INTERVAL '1 day' THEN p.amount ELSE 0 END), 0) as today_earnings,
    COALESCE(SUM(CASE WHEN r.completed_at >= NOW() - INTERVAL '7 days' THEN p.amount ELSE 0 END), 0) as week_earnings,
    COALESCE(SUM(CASE WHEN r.completed_at >= NOW() - INTERVAL '30 days' THEN p.amount ELSE 0 END), 0) as month_earnings,
    COALESCE(SUM(p.amount), 0) as total_earnings
FROM drivers d
LEFT JOIN rides r ON d.id = r.driver_id AND r.status = 'completed'
LEFT JOIN payments p ON r.id = p.ride_id AND p.status = 'completed'
GROUP BY d.id;

-- ============================================================================
-- SECTION 22: RATING UPDATE FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    driver_uuid UUID;
BEGIN
    -- Get the driver_id for this ride
    SELECT driver_id INTO driver_uuid FROM rides WHERE id = NEW.ride_id;
    
    -- Only update if this rating is for the driver (reviewee is the driver)
    IF NEW.reviewee_id = driver_uuid THEN
        -- Calculate new average rating for the driver
        SELECT AVG(rt.rating)::DECIMAL(3,2) INTO avg_rating
        FROM ratings rt
        JOIN rides ri ON rt.ride_id = ri.id
        WHERE ri.driver_id = driver_uuid
        AND rt.reviewee_id = driver_uuid;
        
        -- Update driver's rating
        UPDATE drivers 
        SET rating = COALESCE(avg_rating, 5.0),
            total_rides = total_rides + 1
        WHERE id = driver_uuid;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS update_driver_rating_trigger ON ratings;
CREATE TRIGGER update_driver_rating_trigger
    AFTER INSERT ON ratings
    FOR EACH ROW EXECUTE FUNCTION update_driver_rating();

-- ============================================================================
-- COMPLETE! Database is ready.
-- ============================================================================
