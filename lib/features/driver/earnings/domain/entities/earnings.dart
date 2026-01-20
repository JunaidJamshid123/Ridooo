import 'package:equatable/equatable.dart';

/// Driver earnings entity
class Earnings extends Equatable {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double totalEarnings;
  final int todayRides;
  final int weeklyRides;
  final int monthlyRides;
  final double averageRating;
  final double acceptanceRate;
  final double cancellationRate;

  const Earnings({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalEarnings,
    required this.todayRides,
    required this.weeklyRides,
    required this.monthlyRides,
    required this.averageRating,
    required this.acceptanceRate,
    required this.cancellationRate,
  });

  @override
  List<Object?> get props => [todayEarnings, weeklyEarnings, monthlyEarnings];
}

/// Daily earning breakdown
class DailyEarning extends Equatable {
  final DateTime date;
  final double earnings;
  final int rides;
  final double cashCollected;
  final double walletEarnings;
  final double tips;
  final double incentives;
  final double deductions;

  const DailyEarning({
    required this.date,
    required this.earnings,
    required this.rides,
    required this.cashCollected,
    required this.walletEarnings,
    this.tips = 0,
    this.incentives = 0,
    this.deductions = 0,
  });

  double get netEarnings => earnings + tips + incentives - deductions;

  @override
  List<Object?> get props => [date, earnings, rides];
}
