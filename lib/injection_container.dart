import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Features - Auth
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource_supabase.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Features - User Booking
import 'features/user/booking/data/datasources/booking_remote_datasource.dart';
import 'features/user/booking/data/datasources/booking_remote_datasource_impl.dart';
import 'features/user/booking/data/repositories/booking_repository_impl.dart';
import 'features/user/booking/domain/repositories/booking_repository.dart';
import 'features/user/booking/domain/usecases/create_ride.dart' as create_ride;
import 'features/user/booking/domain/usecases/ride_usecases.dart' as usecases;
import 'features/user/booking/presentation/bloc/booking_bloc.dart';

// Features - Driver Rides
import 'features/driver/rides/data/datasources/driver_rides_remote_datasource.dart';
import 'features/driver/rides/data/repositories/driver_rides_repository_impl.dart';
import 'features/driver/rides/domain/repositories/driver_rides_repository.dart';
import 'features/driver/rides/presentation/bloc/driver_rides_bloc.dart';

// Core Services
import 'core/services/realtime_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============== Features ==============
  
  // Auth Feature
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // ============== User Booking Feature ==============
  // Bloc - Factory since it needs user-specific data
  // Note: BookingBloc requires userId which should come from auth state
  // You'll need to provide userId when creating the bloc
  sl.registerFactoryParam<BookingBloc, String, void>(
    (userId, _) => BookingBloc(
      createRideUseCase: sl<create_ride.CreateRide>(param1: userId),
      cancelRideUseCase: sl<usecases.CancelRide>(param1: userId),
      acceptOfferUseCase: sl<usecases.AcceptDriverOffer>(param1: userId),
      getActiveRideUseCase: sl<usecases.GetActiveRide>(param1: userId),
      repository: sl<BookingRepository>(param1: userId),
      realtimeService: sl(),
    ),
  );

  // Use cases - need userId param
  sl.registerFactoryParam<create_ride.CreateRide, String, void>(
    (userId, _) => create_ride.CreateRide(sl<BookingRepository>(param1: userId)),
  );
  sl.registerFactoryParam<usecases.CancelRide, String, void>(
    (userId, _) => usecases.CancelRide(sl<BookingRepository>(param1: userId)),
  );
  sl.registerFactoryParam<usecases.AcceptDriverOffer, String, void>(
    (userId, _) => usecases.AcceptDriverOffer(sl<BookingRepository>(param1: userId)),
  );
  sl.registerFactoryParam<usecases.GetActiveRide, String, void>(
    (userId, _) => usecases.GetActiveRide(sl<BookingRepository>(param1: userId)),
  );

  // Repository - needs userId
  sl.registerFactoryParam<BookingRepository, String, void>(
    (userId, _) => BookingRepositoryImpl(
      remoteDataSource: sl(),
      userId: userId,
    ),
  );

  // Data sources
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // ============== Driver Rides Feature ==============
  // Bloc - requires driver profile data
  sl.registerFactoryParam<DriverRidesBloc, DriverBlocParams, void>(
    (params, _) => DriverRidesBloc(
      repository: sl(),
      realtimeService: sl(),
      driverId: params.driverId,
      driverName: params.driverName,
      driverPhone: params.driverPhone,
      driverPhoto: params.driverPhoto,
      driverRating: params.driverRating,
      driverTotalRides: params.driverTotalRides,
      vehicleModel: params.vehicleModel,
      vehicleColor: params.vehicleColor,
      vehiclePlate: params.vehiclePlate,
    ),
  );

  // Repository
  sl.registerLazySingleton<DriverRidesRepository>(
    () => DriverRidesRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DriverRidesRemoteDataSource>(
    () => DriverRidesRemoteDataSourceImpl(supabase: sl()),
  );

  // ============== Core ==============
  // Realtime Service
  sl.registerLazySingleton(() => RealtimeService(sl()));

  // ============== External ==============
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Supabase.instance.client);
}

/// Parameters class for creating DriverRidesBloc
class DriverBlocParams {
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final double driverRating;
  final int driverTotalRides;
  final String vehicleModel;
  final String? vehicleColor;
  final String vehiclePlate;

  DriverBlocParams({
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverPhoto,
    required this.driverRating,
    required this.driverTotalRides,
    required this.vehicleModel,
    this.vehicleColor,
    required this.vehiclePlate,
  });
}
