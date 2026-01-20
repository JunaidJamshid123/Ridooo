import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phoneNumber,
    super.profileImage,
    required super.role,
    super.licenseNumber,
    super.vehicleModel,
    super.vehiclePlate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      profileImage: json['profile_image'] as String?,
      role: json['role'] == 'driver' ? UserRole.driver : UserRole.user,
      licenseNumber: json['license_number'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'role': role == UserRole.driver ? 'driver' : 'user',
      'license_number': licenseNumber,
      'vehicle_model': vehicleModel,
      'vehicle_plate': vehiclePlate,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
      role: role,
      licenseNumber: licenseNumber,
      vehicleModel: vehicleModel,
      vehiclePlate: vehiclePlate,
    );
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      profileImage: entity.profileImage,
      role: entity.role,
      licenseNumber: entity.licenseNumber,
      vehicleModel: entity.vehicleModel,
      vehiclePlate: entity.vehiclePlate,
    );
  }
}
