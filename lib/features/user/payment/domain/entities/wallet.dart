import 'package:equatable/equatable.dart';

/// Wallet entity
class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, balance];
}

/// Wallet transaction entity
class WalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final String type; // credit, debit
  final double amount;
  final double balanceAfter;
  final String? description;
  final String? referenceId;
  final String? referenceType; // ride, top_up, withdrawal, refund
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  @override
  List<Object?> get props => [id, type, amount];
}

/// Payment method entity
class PaymentMethod extends Equatable {
  final String id;
  final String type; // card, upi, wallet
  final String? cardLast4;
  final String? cardBrand; // visa, mastercard, etc.
  final String? upiId;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.cardLast4,
    this.cardBrand,
    this.upiId,
    this.isDefault = false,
  });

  String get displayName {
    switch (type) {
      case 'card':
        return '${cardBrand ?? 'Card'} •••• $cardLast4';
      case 'upi':
        return 'UPI: $upiId';
      case 'wallet':
        return 'Ridooo Wallet';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [id, type];
}
