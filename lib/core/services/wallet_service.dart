import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';

/// Service for handling wallet and payment operations with Supabase
class WalletService {
  final SupabaseClient _supabase;

  WalletService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  // ==================== Wallet Operations ====================

  /// Get user's wallet
  Future<Map<String, dynamic>?> getWallet(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.walletsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting wallet: $e');
      rethrow;
    }
  }

  /// Create wallet for user if it doesn't exist
  Future<Map<String, dynamic>> getOrCreateWallet(String userId) async {
    try {
      // Check if wallet exists
      var wallet = await getWallet(userId);
      
      if (wallet == null) {
        // Create new wallet
        wallet = await _supabase
            .from(ApiConstants.walletsTable)
            .insert({
              'user_id': userId,
              'balance': 0.00,
              'currency': 'PKR',
              'is_active': true,
            })
            .select()
            .single();
      }

      return wallet;
    } catch (e) {
      print('Error getting/creating wallet: $e');
      rethrow;
    }
  }

  /// Get wallet balance
  Future<double> getWalletBalance(String userId) async {
    final wallet = await getWallet(userId);
    return (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Add money to wallet (top up)
  Future<Map<String, dynamic>> addMoney({
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      final wallet = await getOrCreateWallet(userId);
      final walletId = wallet['id'] as String;
      final currentBalance = (wallet['balance'] as num).toDouble();
      final newBalance = currentBalance + amount;

      // Update wallet balance
      await _supabase
          .from(ApiConstants.walletsTable)
          .update({'balance': newBalance})
          .eq('id', walletId);

      // Create transaction record
      final transaction = await _supabase
          .from(ApiConstants.walletTransactionsTable)
          .insert({
            'wallet_id': walletId,
            'type': 'credit',
            'amount': amount,
            'balance_after': newBalance,
            'description': description ?? 'Wallet top-up',
            'reference_type': 'top_up',
          })
          .select()
          .single();

      return transaction;
    } catch (e) {
      print('Error adding money: $e');
      rethrow;
    }
  }


  /// Deduct money from wallet (for ride payment)
  Future<Map<String, dynamic>> deductMoney({
    required String userId,
    required double amount,
    required String rideId,
    String? description,
  }) async {
    try {
      final wallet = await getOrCreateWallet(userId);
      final walletId = wallet['id'] as String;
      final currentBalance = (wallet['balance'] as num).toDouble();
      
      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final newBalance = currentBalance - amount;

      // Update wallet balance
      await _supabase
          .from(ApiConstants.walletsTable)
          .update({'balance': newBalance})
          .eq('id', walletId);

      // Create transaction record
      final transaction = await _supabase
          .from(ApiConstants.walletTransactionsTable)
          .insert({
            'wallet_id': walletId,
            'type': 'debit',
            'amount': amount,
            'balance_after': newBalance,
            'description': description ?? 'Ride payment',
            'reference_type': 'ride_payment',
            'reference_id': rideId,
          })
          .select()
          .single();

      return transaction;
    } catch (e) {
      print('Error deducting money: $e');
      rethrow;
    }
  }

  /// Get wallet transactions
  Future<List<Map<String, dynamic>>> getTransactions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) return [];

      final walletId = wallet['id'] as String;

      final response = await _supabase
          .from(ApiConstants.walletTransactionsTable)
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting transactions: $e');
      rethrow;
    }
  }

  // ==================== Payment Operations ====================

  /// Create a payment record for a ride
  Future<Map<String, dynamic>> createPayment({
    required String rideId,
    required String userId,
    required String driverId,
    required double amount,
    double tipAmount = 0,
    required String paymentMethod, // 'cash', 'wallet', 'card', 'upi'
  }) async {
    try {
      final totalAmount = amount + tipAmount;

      final payment = await _supabase
          .from(ApiConstants.paymentsTable)
          .insert({
            'ride_id': rideId,
            'user_id': userId,
            'driver_id': driverId,
            'amount': amount,
            'tip_amount': tipAmount,
            'total_amount': totalAmount,
            'payment_method': paymentMethod,
            'status': 'pending',
          })
          .select()
          .single();

      return payment;
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  /// Process payment (wallet payment)
  Future<Map<String, dynamic>> processWalletPayment({
    required String rideId,
    required String userId,
    required String driverId,
    required double amount,
    double tipAmount = 0,
  }) async {
    try {
      final totalAmount = amount + tipAmount;

      // Check wallet balance
      final balance = await getWalletBalance(userId);
      if (balance < totalAmount) {
        throw Exception('Insufficient wallet balance');
      }

      // Deduct from user wallet
      await deductMoney(
        userId: userId,
        amount: totalAmount,
        rideId: rideId,
        description: 'Payment for ride',
      );

      // Create payment record
      final payment = await createPayment(
        rideId: rideId,
        userId: userId,
        driverId: driverId,
        amount: amount,
        tipAmount: tipAmount,
        paymentMethod: 'wallet',
      );

      // Update payment status to completed
      await _supabase
          .from(ApiConstants.paymentsTable)
          .update({
            'status': 'completed',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payment['id']);

      // Credit driver wallet
      await addMoney(
        userId: driverId,
        amount: totalAmount,
        description: 'Payment received for ride',
      );

      return payment;
    } catch (e) {
      print('Error processing wallet payment: $e');
      rethrow;
    }
  }

  /// Mark cash payment as completed
  Future<void> completeCashPayment(String rideId) async {
    try {
      await _supabase
          .from(ApiConstants.paymentsTable)
          .update({
            'status': 'completed',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('ride_id', rideId);
    } catch (e) {
      print('Error completing cash payment: $e');
      rethrow;
    }
  }

  /// Get payment for a ride
  Future<Map<String, dynamic>?> getRidePayment(String rideId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.paymentsTable)
          .select()
          .eq('ride_id', rideId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting ride payment: $e');
      return null;
    }
  }

  /// Add tip to an existing payment
  Future<void> addTip({
    required String paymentId,
    required double tipAmount,
    required String driverId,
  }) async {
    try {
      // Get current payment
      final payment = await _supabase
          .from(ApiConstants.paymentsTable)
          .select()
          .eq('id', paymentId)
          .single();

      final currentTip = (payment['tip_amount'] as num?)?.toDouble() ?? 0;
      final currentTotal = (payment['total_amount'] as num).toDouble();
      
      final newTip = currentTip + tipAmount;
      final newTotal = currentTotal + tipAmount;

      // Update payment
      await _supabase
          .from(ApiConstants.paymentsTable)
          .update({
            'tip_amount': newTip,
            'total_amount': newTotal,
          })
          .eq('id', paymentId);

      // Credit tip to driver
      await addMoney(
        userId: driverId,
        amount: tipAmount,
        description: 'Tip received',
      );
    } catch (e) {
      print('Error adding tip: $e');
      rethrow;
    }
  }

  /// Request refund
  Future<void> requestRefund({
    required String paymentId,
    required String userId,
    required double amount,
    required String reason,
  }) async {
    try {
      // Update payment status
      await _supabase
          .from(ApiConstants.paymentsTable)
          .update({'status': 'refunded'})
          .eq('id', paymentId);

      // Credit back to user wallet
      await addMoney(
        userId: userId,
        amount: amount,
        description: 'Refund: $reason',
      );
    } catch (e) {
      print('Error processing refund: $e');
      rethrow;
    }
  }
}
