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

  /// Subscribe to new rides (driver side) - listen for all new rides
  /// Then filter on client side for 'searching' status
  RealtimeChannel subscribeToNewRides({
    required RealtimeCallback onNewRide,
    RealtimeCallback? onRideUpdate,
  }) {
    final channelName = 'new-rides-all';

    final channel = _supabase.channel(channelName)
        // Listen for new ride inserts
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.ridesTable,
          callback: (payload) {
            final status = payload.newRecord['status'];
            if (status == 'searching') {
              onNewRide(payload.newRecord);
            }
          },
        )
        // Also listen for ride updates (status changes to 'searching')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: ApiConstants.ridesTable,
          callback: (payload) {
            final newStatus = payload.newRecord['status'];
            final oldStatus = payload.oldRecord['status'];
            
            // New ride became 'searching'
            if (newStatus == 'searching' && oldStatus != 'searching') {
              onNewRide(payload.newRecord);
            }
            // Ride was 'searching' but now changed (accepted/cancelled)
            else if (oldStatus == 'searching' && newStatus != 'searching') {
              onRideUpdate?.call(payload.newRecord);
            }
          },
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }
  
  /// Subscribe to all searching rides for drivers with polling fallback
  RealtimeChannel subscribeToSearchingRides({
    required RealtimeCallback onRideAdded,
    required RealtimeCallback onRideRemoved,
  }) {
    final channelName = 'searching-rides-broadcast';

    final channel = _supabase.channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: ApiConstants.ridesTable,
          callback: (payload) {
            final eventType = payload.eventType;
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            
            if (eventType == PostgresChangeEvent.insert) {
              if (newRecord['status'] == 'searching') {
                onRideAdded(newRecord);
              }
            } else if (eventType == PostgresChangeEvent.update) {
              // Check if ride became searching
              if (newRecord['status'] == 'searching' && 
                  (oldRecord.isEmpty || oldRecord['status'] != 'searching')) {
                onRideAdded(newRecord);
              }
              // Check if ride was searching but now isn't
              else if (newRecord['status'] != 'searching' && 
                       oldRecord['status'] == 'searching') {
                onRideRemoved(newRecord);
              }
            } else if (eventType == PostgresChangeEvent.delete) {
              onRideRemoved(oldRecord);
            }
          },
        );

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Subscribe to driver's own offer updates
  RealtimeChannel subscribeToDriverOfferUpdates({
    required String driverId,
    required RealtimeCallback onUpdate,
  }) {
    final channelName = 'driver-offers-updates:$driverId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: ApiConstants.driverOffersTable,
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

  /// Subscribe to offer status changes for a specific ride (user side)
  RealtimeChannel subscribeToOfferStatusChanges({
    required String rideId,
    required RealtimeCallback onStatusChange,
  }) {
    final channelName = 'offer-status:$rideId';

    final channel = _supabase.channel(channelName).onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: ApiConstants.driverOffersTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ride_id',
            value: rideId,
          ),
          callback: (payload) => onStatusChange(payload.newRecord),
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
