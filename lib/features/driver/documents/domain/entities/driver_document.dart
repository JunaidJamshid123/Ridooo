import 'package:equatable/equatable.dart';

/// Driver document entity
class DriverDocument extends Equatable {
  final String id;
  final String driverId;
  final String documentType;
  final String documentUrl;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverDocument({
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get displayName {
    switch (documentType) {
      case 'license_front':
        return 'Driving License (Front)';
      case 'license_back':
        return 'Driving License (Back)';
      case 'vehicle_registration':
        return 'Vehicle Registration';
      case 'insurance':
        return 'Vehicle Insurance';
      case 'profile_photo':
        return 'Profile Photo';
      case 'cnic_front':
        return 'CNIC (Front)';
      case 'cnic_back':
        return 'CNIC (Back)';
      default:
        return documentType;
    }
  }

  @override
  List<Object?> get props => [id, documentType, status];
}

/// Required document types for driver verification
class DriverDocumentTypes {
  static const List<String> required = [
    'profile_photo',
    'cnic_front',
    'cnic_back',
    'license_front',
    'license_back',
    'vehicle_registration',
  ];

  static const List<String> optional = [
    'insurance',
  ];
}
