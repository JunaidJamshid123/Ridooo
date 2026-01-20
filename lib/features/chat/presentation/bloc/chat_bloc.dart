import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final String conversationId;
  
  const LoadMessages(this.conversationId);
  
  @override
  List<Object?> get props => [conversationId];
}

class LoadMoreMessages extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String content;
  final String messageType;
  
  const SendMessage({
    required this.content,
    this.messageType = 'text',
  });
  
  @override
  List<Object?> get props => [content, messageType];
}

class SendImage extends ChatEvent {
  final String imagePath;
  
  const SendImage(this.imagePath);
  
  @override
  List<Object?> get props => [imagePath];
}

class SendLocation extends ChatEvent {
  final double latitude;
  final double longitude;
  
  const SendLocation({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
}

class NewMessageReceived extends ChatEvent {
  final ChatMessage message;
  
  const NewMessageReceived(this.message);
  
  @override
  List<Object?> get props => [message];
}

class MarkMessagesAsRead extends ChatEvent {
  final String conversationId;
  
  const MarkMessagesAsRead(this.conversationId);
  
  @override
  List<Object?> get props => [conversationId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ConversationsLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  
  const ConversationsLoaded(this.conversations);
  
  @override
  List<Object?> get props => [conversations];
}

class MessagesLoading extends ChatState {}

class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<ChatMessage> messages;
  final bool hasMore;
  
  const MessagesLoaded({
    required this.conversationId,
    required this.messages,
    this.hasMore = true,
  });
  
  @override
  List<Object?> get props => [conversationId, messages, hasMore];
}

class MessageSending extends ChatState {
  final List<ChatMessage> messages;
  
  const MessageSending(this.messages);
  
  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  
  String? _currentConversationId;
  List<ChatMessage> _messages = [];

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<SendImage>(_onSendImage);
    on<SendLocation>(_onSendLocation);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(ConversationsLoading());

    final result = await repository.getConversations();

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (conversations) => emit(ConversationsLoaded(conversations)),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    _currentConversationId = event.conversationId;
    emit(MessagesLoading());

    final result = await repository.getMessages(
      conversationId: event.conversationId,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) {
        _messages = messages;
        emit(MessagesLoaded(
          conversationId: event.conversationId,
          messages: messages,
        ));
      },
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId == null || _messages.isEmpty) return;

    final result = await repository.getMessages(
      conversationId: _currentConversationId!,
      beforeMessageId: _messages.last.id,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (newMessages) {
        _messages = [..._messages, ...newMessages];
        emit(MessagesLoaded(
          conversationId: _currentConversationId!,
          messages: _messages,
          hasMore: newMessages.isNotEmpty,
        ));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId == null) return;

    emit(MessageSending(_messages));

    final result = await repository.sendMessage(
      conversationId: _currentConversationId!,
      content: event.content,
      messageType: event.messageType,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (message) {
        _messages = [message, ..._messages];
        emit(MessagesLoaded(
          conversationId: _currentConversationId!,
          messages: _messages,
        ));
      },
    );
  }

  Future<void> _onSendImage(
    SendImage event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId == null) return;

    emit(MessageSending(_messages));

    final result = await repository.sendImage(
      conversationId: _currentConversationId!,
      imagePath: event.imagePath,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (message) {
        _messages = [message, ..._messages];
        emit(MessagesLoaded(
          conversationId: _currentConversationId!,
          messages: _messages,
        ));
      },
    );
  }

  Future<void> _onSendLocation(
    SendLocation event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId == null) return;

    emit(MessageSending(_messages));

    final result = await repository.sendLocation(
      conversationId: _currentConversationId!,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (message) {
        _messages = [message, ..._messages];
        emit(MessagesLoaded(
          conversationId: _currentConversationId!,
          messages: _messages,
        ));
      },
    );
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (event.message.conversationId == _currentConversationId) {
      _messages = [event.message, ..._messages];
      emit(MessagesLoaded(
        conversationId: _currentConversationId!,
        messages: _messages,
      ));
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await repository.markAsRead(event.conversationId);
  }
}
