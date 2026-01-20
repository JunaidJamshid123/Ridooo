import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';

/// Notifications repository interface
abstract class NotificationRepository {
  /// Get all notifications for current user
  Future<Either<Failure, List<AppNotification>>> getNotifications({
    int limit = 20,
    int offset = 0,
  });

  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadCount();

  /// Mark notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead();

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Delete all notifications
  Future<Either<Failure, void>> deleteAllNotifications();

  /// Subscribe to new notifications
  Stream<AppNotification> subscribeToNotifications();

  /// Update FCM token
  Future<Either<Failure, void>> updateFcmToken(String token);
}
