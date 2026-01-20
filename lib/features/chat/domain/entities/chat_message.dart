import 'package:equatable/equatable.dart';

/// Chat conversation entity
class Conversation extends Equatable {
  final String id;
  final String rideId;
  final String userId;
  final String driverId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  
  // Joined fields
  final String? otherUserName;
  final String? otherUserPhoto;

  const Conversation({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.driverId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    this.otherUserName,
    this.otherUserPhoto,
  });

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [id, rideId, lastMessage, unreadCount];
}

/// Chat message entity
class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType; // text, image, location, audio
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isLocation => messageType == 'location';
  bool get isAudio => messageType == 'audio';

  @override
  List<Object?> get props => [id, conversationId, content, createdAt];
}

/// Message type constants
class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String location = 'location';
  static const String audio = 'audio';
}
