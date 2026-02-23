import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// Implementation of ChatRepository with Supabase
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final String _userId;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required String userId,
  })  : _remoteDataSource = remoteDataSource,
        _userId = userId;

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      final conversations = await _remoteDataSource.getConversations(_userId);
      return Right(conversations.map((model) => Conversation(
        id: model.rideId, // Using rideId as conversation id
        rideId: model.rideId,
        userId: _userId,
        driverId: model.otherUserId,
        lastMessage: model.lastMessage,
        lastMessageAt: model.lastMessageAt,
        unreadCount: model.unreadCount,
        createdAt: model.lastMessageAt ?? DateTime.now(),
        otherUserName: model.otherUserName,
        otherUserPhoto: model.otherUserPhoto,
      )).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, Conversation?>> getConversationByRideId(String rideId) async {
    try {
      final conversations = await _remoteDataSource.getConversations(_userId);
      final conversation = conversations.where((c) => c.rideId == rideId).firstOrNull;
      if (conversation == null) return const Right(null);
      
      return Right(Conversation(
        id: conversation.rideId,
        rideId: conversation.rideId,
        userId: _userId,
        driverId: conversation.otherUserId,
        lastMessage: conversation.lastMessage,
        lastMessageAt: conversation.lastMessageAt,
        unreadCount: conversation.unreadCount,
        createdAt: conversation.lastMessageAt ?? DateTime.now(),
        otherUserName: conversation.otherUserName,
        otherUserPhoto: conversation.otherUserPhoto,
      ));
    } catch (e) {
      return Left(ServerFailure('Failed to get conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation({
    required String rideId,
    required String userId,
    required String driverId,
  }) async {
    // Conversations are implicitly created when first message is sent
    // Return a new conversation object
    return Right(Conversation(
      id: rideId,
      rideId: rideId,
      userId: userId,
      driverId: driverId,
      lastMessage: null,
      lastMessageAt: null,
      unreadCount: 0,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final messages = await _remoteDataSource.getMessages(conversationId);
      return Right(messages.map((model) => ChatMessage(
        id: model.id,
        conversationId: model.rideId,
        senderId: model.senderId,
        messageType: model.messageType,
        content: model.content,
        isRead: model.isRead,
        createdAt: model.createdAt,
      )).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load messages: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String conversationId, // This is actually rideId
    required String content,
    String messageType = 'text',
  }) async {
    try {
      // Need to get the other user (driver or rider) ID
      // For now, we'll get it from the ride
      final conversations = await _remoteDataSource.getConversations(_userId);
      final conversation = conversations.where((c) => c.rideId == conversationId).firstOrNull;
      
      if (conversation == null) {
        return const Left(ServerFailure('Conversation not found'));
      }

      final message = await _remoteDataSource.sendMessage(
        rideId: conversationId,
        senderId: _userId,
        receiverId: conversation.otherUserId,
        content: content,
        messageType: messageType,
      );

      return Right(ChatMessage(
        id: message.id,
        conversationId: message.rideId,
        senderId: message.senderId,
        messageType: message.messageType,
        content: message.content,
        isRead: message.isRead,
        createdAt: message.createdAt,
      ));
    } catch (e) {
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendImage({
    required String conversationId,
    required String imagePath,
  }) async {
    // TODO: Upload image to storage first, then send URL
    return sendMessage(
      conversationId: conversationId,
      content: imagePath,
      messageType: 'image',
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> sendLocation({
    required String conversationId,
    required double latitude,
    required double longitude,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      content: '$latitude,$longitude',
      messageType: 'location',
    );
  }

  @override
  Future<Either<Failure, void>> markAsRead(String conversationId) async {
    try {
      await _remoteDataSource.markMessagesAsRead(conversationId, _userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark messages as read: $e'));
    }
  }

  @override
  Stream<ChatMessage> subscribeToMessages(String conversationId) {
    return _remoteDataSource.subscribeToMessages(conversationId).map((model) => 
      ChatMessage(
        id: model.id,
        conversationId: model.rideId,
        senderId: model.senderId,
        messageType: model.messageType,
        content: model.content,
        isRead: model.isRead,
        createdAt: model.createdAt,
      )
    );
  }

  @override
  Stream<Conversation> subscribeToConversationUpdates(String conversationId) {
    // This would require additional realtime subscription setup
    // For now, return an empty stream
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, int>> getTotalUnreadCount() async {
    try {
      final count = await _remoteDataSource.getUnreadCount(_userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure('Failed to get unread count: $e'));
    }
  }
}
