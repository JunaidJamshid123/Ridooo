import 'package:equatable/equatable.dart';

/// Support ticket entity
class SupportTicket extends Equatable {
  final String id;
  final String userId;
  final String? rideId;
  final String subject;
  final String description;
  final String category; // ride_issue, payment, account, other
  final String status; // open, in_progress, resolved, closed
  final String priority; // low, medium, high
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    this.rideId,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';

  @override
  List<Object?> get props => [id, subject, status, createdAt];
}

/// Support message in a ticket thread
class SupportMessage extends Equatable {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType; // user, support
  final String message;
  final List<String>? attachments;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.attachments,
    required this.createdAt,
  });

  bool get isFromSupport => senderType == 'support';
  bool get isFromUser => senderType == 'user';

  @override
  List<Object?> get props => [id, message, createdAt];
}

/// Support ticket categories
class SupportCategory {
  static const String rideIssue = 'ride_issue';
  static const String payment = 'payment';
  static const String account = 'account';
  static const String other = 'other';

  static const List<Map<String, String>> all = [
    {'value': rideIssue, 'label': 'Ride Issue'},
    {'value': payment, 'label': 'Payment Problem'},
    {'value': account, 'label': 'Account Issue'},
    {'value': other, 'label': 'Other'},
  ];
}
