import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/support_ticket.dart';

/// Support repository interface
abstract class SupportRepository {
  /// Get all support tickets for current user
  Future<Either<Failure, List<SupportTicket>>> getTickets({
    String? status,
    int limit = 20,
    int offset = 0,
  });

  /// Get ticket by ID with messages
  Future<Either<Failure, SupportTicket>> getTicketById(String ticketId);

  /// Get messages for a ticket
  Future<Either<Failure, List<SupportMessage>>> getTicketMessages(String ticketId);

  /// Create a new support ticket
  Future<Either<Failure, SupportTicket>> createTicket({
    required String subject,
    required String description,
    required String category,
    String? rideId,
    List<String>? attachments,
  });

  /// Reply to a ticket
  Future<Either<Failure, SupportMessage>> replyToTicket({
    required String ticketId,
    required String message,
    List<String>? attachments,
  });

  /// Close a ticket
  Future<Either<Failure, void>> closeTicket(String ticketId);

  /// Get FAQs
  Future<Either<Failure, List<FAQ>>> getFAQs({String? category});

  /// Search FAQs
  Future<Either<Failure, List<FAQ>>> searchFAQs(String query);
}

/// FAQ entity
class FAQ extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
  });

  @override
  List<Object?> get props => [id, question];
}
