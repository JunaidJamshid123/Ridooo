import 'package:equatable/equatable.dart';

/// App notification entity (in-app notifications, not push)
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // ride, promo, system, payment
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  bool get isRideNotification => type == 'ride';
  bool get isPromoNotification => type == 'promo';
  bool get isSystemNotification => type == 'system';
  bool get isPaymentNotification => type == 'payment';

  String? get rideId => data?['ride_id'];
  String? get actionUrl => data?['action_url'];

  @override
  List<Object?> get props => [id, title, type, isRead, createdAt];
}

/// Notification type constants
class NotificationType {
  static const String ride = 'ride';
  static const String promo = 'promo';
  static const String system = 'system';
  static const String payment = 'payment';
}
