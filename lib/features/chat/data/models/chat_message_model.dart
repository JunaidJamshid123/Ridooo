import 'package:equatable/equatable.dart';

/// Chat message model for database operations
class ChatMessageModel extends Equatable {
  final String id;
  final String rideId;
  final String senderId;
  final String receiverId;
  final String messageType;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  
  // Joined fields (from users table)
  final String? senderName;
  final String? senderPhoto;

  const ChatMessageModel({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender']?['name'] as String?,
      senderPhoto: json['sender']?['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_type': messageType,
      'content': content,
      'is_read': isRead,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? rideId,
    String? senderId,
    String? receiverId,
    String? messageType,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    String? senderName,
    String? senderPhoto,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
    );
  }

  @override
  List<Object?> get props => [id, rideId, content, createdAt];
}

/// Chat conversation model
class ChatConversationModel extends Equatable {
  final String rideId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatConversationModel({
    required this.rideId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine other user based on current user
    final user1Id = json['user1_id'] as String?;
    final user2Id = json['user2_id'] as String?;
    final otherId = user1Id == currentUserId ? user2Id : user1Id;
    
    return ChatConversationModel(
      rideId: json['ride_id'] as String,
      otherUserId: otherId ?? '',
      otherUserName: json['other_user_name'] as String? ?? 'Unknown',
      otherUserPhoto: json['other_user_photo'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [rideId, otherUserId, lastMessage, unreadCount];
}
