import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

/// Service for handling file storage operations with Supabase Storage
class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$fileName';

      await _supabase.storage
          .from(ApiConstants.profilePhotosBucket)
          .upload(path, file);

      final url = _supabase.storage
          .from(ApiConstants.profilePhotosBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Upload driver document
  Future<String?> uploadDriverDocument({
    required String driverId,
    required String documentType,
    required File file,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final fileName =
          '$driverId-$documentType-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'documents/$driverId/$fileName';

      await _supabase.storage
          .from(ApiConstants.driverDocumentsBucket)
          .upload(path, file);

      final url = _supabase.storage
          .from(ApiConstants.driverDocumentsBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      print('Error uploading driver document: $e');
      return null;
    }
  }

  /// Upload chat media (image/audio)
  Future<String?> uploadChatMedia({
    required String rideId,
    required String senderId,
    required File file,
    required String mediaType, // 'image' or 'audio'
  }) async {
    try {
      final extension = file.path.split('.').last;
      final fileName =
          '$senderId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$rideId/$mediaType/$fileName';

      await _supabase.storage
          .from(ApiConstants.chatMediaBucket)
          .upload(path, file);

      final url = _supabase.storage
          .from(ApiConstants.chatMediaBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      print('Error uploading chat media: $e');
      return null;
    }
  }

  /// Delete a file from storage
  Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get signed URL for private files
  Future<String?> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600, // 1 hour
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return signedUrl;
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }
}
