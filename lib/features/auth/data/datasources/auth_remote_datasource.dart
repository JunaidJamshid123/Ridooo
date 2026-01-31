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
  });
  
  Future<void> logout();
  
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // final http.Client client;
  
  // AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // TODO: Implement API call
    // final response = await client.post(
    //   Uri.parse('$baseUrl/auth/login'),
    //   body: {'email': email, 'password': password},
    // );
    
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    return const UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      phoneNumber: '+1234567890',
      role: UserRole.user,
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    // TODO: Implement API call
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      role: UserRole.user,
    );
  }

  @override
  Future<void> logout() async {
    // TODO: Implement API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // TODO: Implement API call
    await Future.delayed(const Duration(milliseconds: 500));
    return const UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      phoneNumber: '+1234567890',
      role: UserRole.user,
    );
  }
}
