import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

/// Chat repository interface
abstract class ChatRepository {
  /// Get all conversations for current user
  Future<Either<Failure, List<Conversation>>> getConversations();

  /// Get conversation by ride ID
  Future<Either<Failure, Conversation?>> getConversationByRideId(String rideId);

  /// Create a new conversation for a ride
  Future<Either<Failure, Conversation>> createConversation({
    required String rideId,
    required String userId,
    required String driverId,
  });

  /// Get messages for a conversation
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  });

  /// Send a text message
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  });

  /// Send an image message
  Future<Either<Failure, ChatMessage>> sendImage({
    required String conversationId,
    required String imagePath,
  });

  /// Send location message
  Future<Either<Failure, ChatMessage>> sendLocation({
    required String conversationId,
    required double latitude,
    required double longitude,
  });

  /// Mark messages as read
  Future<Either<Failure, void>> markAsRead(String conversationId);

  /// Subscribe to new messages in a conversation
  Stream<ChatMessage> subscribeToMessages(String conversationId);

  /// Subscribe to conversation updates (last message, unread count)
  Stream<Conversation> subscribeToConversationUpdates(String conversationId);

  /// Get unread message count across all conversations
  Future<Either<Failure, int>> getTotalUnreadCount();
}
