import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

/// Callback type for realtime updates
typedef RealtimeCallback = void Function(Map<String, dynamic> payload);

/// Service for handling Supabase Realtime subscriptions
class RealtimeService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeService(this._supabase);

  /// Subscribe to ride updates for a specific ride
  RealtimeChannel subscribeToRideUpdates({
    required String rideId,
    required RealtimeCallback onUpdate,
  }) {
    final channelName = '${ApiConstants.rideUpdatesChannel}:$rideId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: ApiConstants.ridesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: rideId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to driver location updates
  RealtimeChannel subscribeToDriverLocation({
    required String driverId,
    required RealtimeCallback onUpdate,
  }) {
    final channelName = '${ApiConstants.driverLocationChannel}:$driverId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: ApiConstants.driverLocationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to chat messages for a ride
  RealtimeChannel subscribeToChatMessages({
    required String rideId,
    required RealtimeCallback onNewMessage,
  }) {
    final channelName = '${ApiConstants.chatChannel}:$rideId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.chatMessagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ride_id',
            value: rideId,
          ),
          callback: (payload) => onNewMessage(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to driver offers for a ride (user side)
  RealtimeChannel subscribeToDriverOffers({
    required String rideId,
    required RealtimeCallback onNewOffer,
  }) {
    final channelName = 'driver-offers:$rideId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.driverOffersTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ride_id',
            value: rideId,
          ),
          callback: (payload) => onNewOffer(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to ride requests for a driver (driver side)
  RealtimeChannel subscribeToRideRequests({
    required String city,
    required RealtimeCallback onNewRequest,
  }) {
    final channelName = 'ride-requests:$city';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.ridesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'city',
            value: city,
          ),
          callback: (payload) => onNewRequest(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to notifications for a user
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required RealtimeCallback onNotification,
  }) {
    final channelName = '${ApiConstants.notificationsChannel}:$userId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNotification(payload.newRecord),
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    final channel = _channels[channelName];
    if (channel != null) {
      await channel.unsubscribe();
      _channels.remove(channelName);
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
  }

  /// Check if a channel is active
  bool isSubscribed(String channelName) {
    return _channels.containsKey(channelName);
  }
}
