import 'package:equatable/equatable.dart';

/// Saved place entity
class SavedPlace extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String type; // home, work, other
  final String address;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const SavedPlace({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  bool get isHome => type == 'home';
  bool get isWork => type == 'work';

  IconType get iconType {
    switch (type) {
      case 'home':
        return IconType.home;
      case 'work':
        return IconType.work;
      default:
        return IconType.place;
    }
  }

  @override
  List<Object?> get props => [id, name, type];
}

enum IconType { home, work, place }
