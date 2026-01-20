# Supabase Setup Guide for Ridooo

## 1. Create a Supabase Account

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up for a free account
3. Create a new project

## 2. Get Your Project Credentials

After creating your project:

1. Go to **Project Settings** → **API**
2. Copy your **Project URL** and **anon/public key**
3. Update `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  
  // ... rest of the file
}
```

## 3. Create Database Tables

Go to **SQL Editor** in your Supabase dashboard and run these queries:

### Create Users Table

```sql
-- Users table
CREATE TABLE users (
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

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies for users table
CREATE POLICY "Users can view their own data" 
  ON users FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" 
  ON users FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Anyone can insert during signup" 
  ON users FOR INSERT 
  WITH CHECK (true);
```

### Create Drivers Table

```sql
-- Drivers table
CREATE TABLE drivers (
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

-- Enable Row Level Security
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Policies for drivers table
CREATE POLICY "Drivers can view their own data" 
  ON drivers FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Drivers can update their own data" 
  ON drivers FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Anyone can insert during driver signup" 
  ON drivers FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Users can view all drivers" 
  ON drivers FOR SELECT 
  USING (true);
```

### Create Rides Table

```sql
-- Rides table
CREATE TABLE rides (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES drivers(id),
  user_id UUID REFERENCES users(id) NOT NULL,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  pickup_latitude DECIMAL(10,8) NOT NULL,
  pickup_longitude DECIMAL(11,8) NOT NULL,
  dropoff_latitude DECIMAL(10,8) NOT NULL,
  dropoff_longitude DECIMAL(11,8) NOT NULL,
  vehicle_type TEXT NOT NULL,
  fare DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;

-- Policies for rides table
CREATE POLICY "Users can view their own rides" 
  ON rides FOR SELECT 
  USING (auth.uid() = user_id OR auth.uid() = driver_id);

CREATE POLICY "Users can create rides" 
  ON rides FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users and drivers can update their rides" 
  ON rides FOR UPDATE 
  USING (auth.uid() = user_id OR auth.uid() = driver_id);
```

### Create Triggers for Updated_at

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for all tables
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at 
  BEFORE UPDATE ON drivers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rides_updated_at 
  BEFORE UPDATE ON rides 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 4. Configure Storage (Optional for Profile Images)

1. Go to **Storage** in Supabase dashboard
2. Create a new bucket called `profile-images`
3. Make it public or set appropriate policies

### Storage Policy

```sql
-- Allow authenticated users to upload their profile images
CREATE POLICY "Users can upload their own profile images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to view all profile images
CREATE POLICY "Anyone can view profile images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-images');
```

## 5. Test Your Setup

After setting up:

1. Run your Flutter app
2. Try to sign up as a user
3. Try to sign up as a driver
4. Check your Supabase dashboard to see if data is being created

## Database Schema Overview

```
auth.users (Supabase Auth)
    ↓
users (Custom table)
    ├── id (references auth.users)
    ├── name
    ├── email
    ├── phone_number
    ├── role (user/driver)
    └── driver fields (if role = driver)

drivers (Only for driver role)
    ├── id (references users)
    ├── license_number
    ├── vehicle_model
    ├── vehicle_plate
    ├── is_available
    └── rating

rides
    ├── id
    ├── user_id (references users)
    ├── driver_id (references drivers)
    ├── pickup/dropoff locations
    ├── fare
    └── status
```

## Important Notes

1. **Authentication**: Supabase handles authentication automatically
2. **Row Level Security (RLS)**: Ensures users can only access their own data
3. **Policies**: Control who can read/write data
4. **Triggers**: Automatically update timestamps

## Troubleshooting

If you encounter issues:

1. Check if your Supabase URL and anon key are correct
2. Verify all tables are created in SQL Editor
3. Check if Row Level Security policies are enabled
4. Look at Supabase logs for any errors
5. Make sure email confirmation is disabled in **Authentication** → **Settings** for testing

## Next Steps

1. Test user registration and login
2. Implement profile image upload
3. Add ride booking functionality
4. Set up real-time subscriptions for ride updates
