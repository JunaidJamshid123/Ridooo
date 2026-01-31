# Real-Time Ride Booking Implementation - Integration Checklist

## ✅ Completed Implementation

### 1. Database Layer
- ✅ Created `driver_offers` table with auto-expiry (5 minutes)
- ✅ Added PostgreSQL extensions: `cube`, `earthdistance`
- ✅ Created `find_nearby_drivers()` function for geospatial queries
- ✅ Created `expire_old_driver_offers()` function for automated cleanup
- ✅ Configured Row Level Security (RLS) policies
- ✅ Added indexes for performance optimization

**File:** `supabase_complete_schema_v2.sql`

### 2. Driver-Side Implementation
- ✅ Created domain layer: `DriverRidesRepository`
- ✅ Created data layer: `DriverRidesRemoteDataSource` & `DriverRidesRepositoryImpl`
- ✅ Created BLoC: `DriverRidesBloc` with 11 event handlers
- ✅ Created UI: `AvailableRidesPage`, `RideRequestCard`, `CreateOfferBottomSheet`
- ✅ Integrated real-time subscriptions for new rides

**Files Created:**
- `lib/features/driver/rides/domain/repositories/driver_rides_repository.dart`
- `lib/features/driver/rides/data/datasources/driver_rides_remote_datasource.dart`
- `lib/features/driver/rides/data/repositories/driver_rides_repository_impl.dart`
- `lib/features/driver/rides/presentation/bloc/driver_rides_*.dart`
- `lib/features/driver/rides/presentation/pages/available_rides_page.dart`
- `lib/features/driver/rides/presentation/widgets/ride_request_card.dart`
- `lib/features/driver/rides/presentation/widgets/create_offer_bottom_sheet.dart`

### 3. User-Side Implementation
- ✅ Extended `BookingRepository` with offer methods
- ✅ Created `BookingRemoteDataSourceImpl` with Supabase integration
- ✅ Updated `BookingBloc` with offer events/states
- ✅ Created UI: `IncomingOffersPage`, `DriverOfferCard`
- ✅ Added real-time offer subscriptions

**Files Created/Updated:**
- `lib/features/user/booking/data/datasources/booking_remote_datasource_impl.dart` (NEW)
- `lib/features/user/booking/presentation/bloc/booking_bloc.dart` (UPDATED)
- `lib/features/user/booking/presentation/pages/incoming_offers_page.dart` (NEW)
- `lib/features/user/booking/presentation/widgets/driver_offer_card.dart` (NEW)
- `lib/features/user/booking/domain/entities/ride.dart` (UPDATED - added copyWith)
- `lib/features/user/booking/domain/entities/driver_offer.dart` (UPDATED - added compatibility getters)

### 4. Real-Time Service
- ✅ Extended `RealtimeService` with driver-specific methods
  - `subscribeToNewRides()` - Driver receives new ride requests
  - `subscribeToDriverOffers()` - User receives new offers
  - `subscribeToDriverOfferUpdates()` - Driver tracks their offers
  - `subscribeToOfferStatusChanges()` - Status change notifications

**File Updated:** `lib/core/services/realtime_service.dart`

---

## 🔧 Required Integration Steps

### Step 1: Deploy Database Schema
```bash
# Connect to your Supabase project
psql -h db.YOUR_PROJECT_REF.supabase.co -U postgres -d postgres

# Run the schema file
\i supabase_complete_schema_v2.sql
```

**OR** Use Supabase Dashboard:
1. Go to SQL Editor
2. Paste contents of `supabase_complete_schema_v2.sql`
3. Click "Run"

### Step 2: Update Dependency Injection

Add to `lib/injection_container.dart`:

```dart
import 'core/services/realtime_service.dart';
import 'features/driver/rides/data/datasources/driver_rides_remote_datasource.dart';
import 'features/driver/rides/data/repositories/driver_rides_repository_impl.dart';
import 'features/driver/rides/domain/repositories/driver_rides_repository.dart';
import 'features/driver/rides/presentation/bloc/driver_rides_bloc.dart';
import 'features/user/booking/data/datasources/booking_remote_datasource.dart';
import 'features/user/booking/data/datasources/booking_remote_datasource_impl.dart';
import 'features/user/booking/data/repositories/booking_repository_impl.dart';
import 'features/user/booking/domain/repositories/booking_repository.dart';
import 'features/user/booking/domain/usecases/create_ride.dart';
import 'features/user/booking/domain/usecases/ride_usecases.dart';
import 'features/user/booking/presentation/bloc/booking_bloc.dart';

// In init() function, add:

// Core Services
sl.registerLazySingleton(() => RealtimeService(supabaseClient: sl()));

// Booking Feature (User Side)
sl.registerFactory(() => BookingBloc(
  createRideUseCase: sl(),
  cancelRideUseCase: sl(),
  acceptOfferUseCase: sl(),
  getActiveRideUseCase: sl(),
  repository: sl(),
  realtimeService: sl(),
));

sl.registerLazySingleton(() => CreateRide(sl()));
sl.registerLazySingleton(() => CancelRide(sl()));
sl.registerLazySingleton(() => AcceptDriverOffer(sl()));
sl.registerLazySingleton(() => GetActiveRide(sl()));

sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(
  remoteDataSource: sl(),
  userId: sl<SupabaseClient>().auth.currentUser!.id,
));

sl.registerLazySingleton<BookingRemoteDataSource>(
  () => BookingRemoteDataSourceImpl(supabaseClient: sl()),
);

// Driver Rides Feature (Driver Side)
// NOTE: This requires driver profile data - register when driver is logged in
// sl.registerFactory(() => DriverRidesBloc(
//   repository: sl(),
//   realtimeService: sl(),
//   driverId: driverProfile.id,
//   driverName: driverProfile.name,
//   driverPhone: driverProfile.phone,
//   driverPhoto: driverProfile.photoUrl,
//   driverRating: driverProfile.rating,
//   driverTotalRides: driverProfile.totalRides,
//   vehicleModel: driverProfile.vehicle.model,
//   vehicleColor: driverProfile.vehicle.color,
//   vehiclePlate: driverProfile.vehicle.plate,
// ));

sl.registerLazySingleton<DriverRidesRepository>(
  () => DriverRidesRepositoryImpl(remoteDataSource: sl()),
);

sl.registerLazySingleton<DriverRidesRemoteDataSource>(
  () => DriverRidesRemoteDataSourceImpl(supabase: sl()),
);
```

### Step 3: Register DriverRidesBloc Dynamically

Create a helper function to register the DriverRidesBloc after driver login:

```dart
// lib/core/di/driver_di.dart
import 'package:get_it/get_it.dart';
import '../../features/driver/profile/domain/entities/driver_profile.dart';
import '../../features/driver/rides/presentation/bloc/driver_rides_bloc.dart';

void registerDriverBloc(DriverProfile profile) {
  final sl = GetIt.instance;
  
  // Unregister if already registered
  if (sl.isRegistered<DriverRidesBloc>()) {
    sl.unregister<DriverRidesBloc>();
  }
  
  sl.registerFactory(() => DriverRidesBloc(
    repository: sl(),
    realtimeService: sl(),
    driverId: profile.id,
    driverName: profile.name,
    driverPhone: profile.phone,
    driverPhoto: profile.photoUrl,
    driverRating: profile.rating,
    driverTotalRides: profile.totalRides,
    vehicleModel: profile.vehicle.model,
    vehicleColor: profile.vehicle.color,
    vehiclePlate: profile.vehicle.plate,
  ));
}
```

### Step 4: Update App Router

Add routes to `lib/core/navigation/app_router.dart`:

```dart
GoRoute(
  path: '/driver/available-rides',
  name: 'available-rides',
  builder: (context, state) => BlocProvider(
    create: (_) => sl<DriverRidesBloc>(),
    child: const AvailableRidesPage(),
  ),
),
GoRoute(
  path: '/user/incoming-offers',
  name: 'incoming-offers',
  builder: (context, state) {
    final ride = state.extra as Ride;
    return BlocProvider.value(
      value: context.read<BookingBloc>(),
      child: IncomingOffersPage(ride: ride),
    );
  },
),
```

### Step 5: Navigate to Offers Page After Ride Creation

In your user booking flow, after creating a ride:

```dart
// In booking page or ride request page
BlocListener<BookingBloc, BookingState>(
  listener: (context, state) {
    if (state is RideCreated) {
      // Navigate to incoming offers page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<BookingBloc>(),
            child: IncomingOffersPage(ride: state.ride),
          ),
        ),
      );
    }
  },
  child: // Your UI
)
```

### Step 6: Test Database Functions

Run these SQL queries to test:

```sql
-- Test find_nearby_drivers
SELECT * FROM find_nearby_drivers(31.5204, 74.3587, 10);

-- Test offer expiry
SELECT * FROM driver_offers WHERE expires_at < NOW();

-- Manual trigger (for testing)
SELECT expire_old_driver_offers();
```

---

## 📋 Testing Checklist

### User Flow Testing
- [ ] User creates ride request
- [ ] Ride appears in driver's available rides list
- [ ] Driver sends offer with custom price
- [ ] User receives offer in real-time
- [ ] User can see offer timer (5 minutes)
- [ ] User can accept offer
- [ ] Other offers automatically rejected
- [ ] User can reject offer
- [ ] Driver receives acceptance/rejection notification

### Driver Flow Testing
- [ ] Driver toggles online/offline status
- [ ] Driver sees nearby ride requests
- [ ] Driver can send offer with price, ETA, message
- [ ] Driver cannot send duplicate offers
- [ ] Driver sees offer status changes
- [ ] Accepted offer navigates to active ride

### Real-Time Testing
- [ ] New rides appear without refresh
- [ ] New offers appear without refresh
- [ ] Status changes update immediately
- [ ] Expired offers automatically marked

### Edge Cases
- [ ] What happens if user accepts multiple offers (should reject others)
- [ ] What happens if offer expires (status updates to 'expired')
- [ ] What happens if ride is cancelled (all offers rejected)
- [ ] What happens if driver goes offline (existing offers remain)

---

## 🔍 Verification Commands

### Check Database Tables
```sql
-- Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('driver_offers', 'driver_locations');

-- Check driver_offers structure
\d driver_offers

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'driver_offers';
```

### Check Flutter Compilation
```bash
# Run static analysis
flutter analyze

# Check for errors in new files
flutter analyze lib/features/driver/rides/
flutter analyze lib/features/user/booking/
```

---

## ⚠️ Known Considerations

### 1. Driver Profile Required
The `DriverRidesBloc` requires driver profile data. Ensure you:
- Fetch driver profile after login
- Pass all required fields (name, rating, vehicle info)
- Handle missing/null values gracefully

### 2. Location Permissions
Ensure location permissions are granted for:
- Getting driver's current location
- Calculating nearby rides
- Real-time location tracking

### 3. Real-Time Subscriptions
- Subscriptions use Supabase Realtime (free tier: 200k monthly events)
- Unsubscribe when leaving pages to avoid memory leaks
- Handle reconnection on network issues

### 4. Offer Expiry
- Database function runs periodically (configure pg_cron or trigger)
- UI should show countdown timer
- Expired offers are not deletable (for audit trail)

### 5. Price Validation
Consider adding validation:
- Minimum offer price (e.g., 50% of estimated fare)
- Maximum offer price (e.g., 150% of estimated fare)
- Prevent unrealistic bids

---

## 🎯 Next Steps (Optional Enhancements)

1. **Push Notifications**: Notify users/drivers of new offers/status changes
2. **Location Tracking**: Real-time driver location during ride
3. **Rating System**: Allow users to rate drivers after ride completion
4. **Analytics**: Track acceptance rates, average offer prices
5. **Offer Negotiation**: Allow counter-offers (like InDrive)
6. **Multiple Offers**: Allow users to accept multiple offers and choose later
7. **Driver Preferences**: Filter by vehicle type, rating, etc.

---

## 📞 Support

If you encounter issues:
1. Check Supabase logs for database errors
2. Check Flutter console for runtime errors
3. Verify RLS policies allow operations
4. Ensure real-time is enabled in Supabase project settings
5. Check that all dependencies are injected correctly

---

**Implementation Date:** January 25, 2026  
**Status:** ✅ Complete - Ready for Integration Testing
