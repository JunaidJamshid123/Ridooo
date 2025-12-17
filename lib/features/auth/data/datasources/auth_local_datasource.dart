import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<void> cacheToken(String token);
  Future<String?> getToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String cachedUserKey = 'CACHED_USER';
  static const String cachedTokenKey = 'CACHED_TOKEN';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      cachedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString != null) {
      return UserModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(cachedUserKey);
    await sharedPreferences.remove(cachedTokenKey);
  }

  @override
  Future<void> cacheToken(String token) async {
    await sharedPreferences.setString(cachedTokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(cachedTokenKey);
  }
}
