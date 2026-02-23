import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// Remote data source for chat operations with Supabase
abstract class ChatRemoteDataSource {
  /// Get all conversations for current user
  Future<List<ChatConversationModel>> getConversations(String userId);
  
  /// Get messages for a specific ride
  Future<List<ChatMessageModel>> getMessages(String rideId);
  
  /// Send a new message
  Future<ChatMessageModel> sendMessage({
    required String rideId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  });
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String rideId, String userId);
  
  /// Subscribe to new messages for a ride
  Stream<ChatMessageModel> subscribeToMessages(String rideId);
  
  /// Get unread message count for user
  Future<int> getUnreadCount(String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase;
  
  ChatRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  @override
  Future<List<ChatConversationModel>> getConversations(String userId) async {
    try {
      // Get distinct ride_ids where user is involved in chat
      final response = await _supabase
          .from('chat_messages')
          .select('''
            ride_id,
            sender_id,
            receiver_id,
            content,
            created_at,
            sender:users!chat_messages_sender_id_fkey(id, name, profile_image),
            receiver:users!chat_messages_receiver_id_fkey(id, name, profile_image)
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      // Group by ride_id and get the latest message for each conversation
      final Map<String, Map<String, dynamic>> conversationsMap = {};
      
      for (final msg in response as List) {
        final rideId = msg['ride_id'] as String;
        if (!conversationsMap.containsKey(rideId)) {
          // Determine other user
          final senderId = msg['sender_id'] as String;
          final receiverId = msg['receiver_id'] as String;
          final isUserSender = senderId == userId;
          
          final otherUser = isUserSender 
              ? msg['receiver'] as Map<String, dynamic>?
              : msg['sender'] as Map<String, dynamic>?;
          
          conversationsMap[rideId] = {
            'ride_id': rideId,
            'other_user_id': isUserSender ? receiverId : senderId,
            'other_user_name': otherUser?['name'] ?? 'Unknown',
            'other_user_photo': otherUser?['profile_image'],
            'last_message': msg['content'],
            'last_message_at': msg['created_at'],
            'unread_count': 0,
          };
        }
      }

      // Get unread counts
      for (final rideId in conversationsMap.keys) {
        final unreadResponse = await _supabase
            .from('chat_messages')
            .select()
            .eq('ride_id', rideId)
            .eq('receiver_id', userId)
            .eq('is_read', false);
        
        conversationsMap[rideId]!['unread_count'] = (unreadResponse as List).length;
      }

      return conversationsMap.values
          .map((json) => ChatConversationModel.fromJson(json, userId))
          .toList();
    } catch (e) {
      print('Error getting conversations: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String rideId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            *,
            sender:users!chat_messages_sender_id_fkey(name, profile_image)
          ''')
          .eq('ride_id', rideId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String rideId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'ride_id': rideId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'content': content,
            'message_type': messageType,
            'is_read': false,
          })
          .select('''
            *,
            sender:users!chat_messages_sender_id_fkey(name, profile_image)
          ''')
          .single();

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  @override
  Future<void> markMessagesAsRead(String rideId, String userId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('ride_id', rideId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  @override
  Stream<ChatMessageModel> subscribeToMessages(String rideId) {
    final controller = StreamController<ChatMessageModel>.broadcast();
    
    final channel = _supabase.channel('chat:$rideId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ride_id',
            value: rideId,
          ),
          callback: (payload) {
            try {
              final message = ChatMessageModel.fromJson(payload.newRecord);
              controller.add(message);
            } catch (e) {
              print('Error parsing realtime message: $e');
            }
          },
        );
    
    channel.subscribe();
    
    // Clean up on stream close
    controller.onCancel = () {
      channel.unsubscribe();
    };
    
    return controller.stream;
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
