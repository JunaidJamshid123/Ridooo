import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });
  
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
  });
  
  Future<void> logout();
  
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthenticationException('Login failed');
      }
      
      // Fetch user data from users table
      final userData = await supabaseClient
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();
      
      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthenticationException('Registration failed');
      }
      
      // Create user profile
      final userModel = UserModel(
        id: response.user!.id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        licenseNumber: licenseNumber,
        vehicleModel: vehicleModel,
        vehiclePlate: vehiclePlate,
      );
      
      // Insert user data into users table
      await supabaseClient
          .from(SupabaseConfig.usersTable)
          .insert(userModel.toJson());
      
      // If driver, insert into drivers table
      if (role == UserRole.driver) {
        await supabaseClient.from(SupabaseConfig.driversTable).insert({
          'id': response.user!.id,
          'license_number': licenseNumber,
          'vehicle_model': vehicleModel,
          'vehicle_plate': vehiclePlate,
          'is_available': true,
          'rating': 5.0,
        });
      }
      
      return userModel;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      
      if (user == null) {
        return null;
      }
      
      final userData = await supabaseClient
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', user.id)
          .single();
      
      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }
}
