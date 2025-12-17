import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phoneNumber,
    super.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
    );
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      profileImage: entity.profileImage,
    );
  }
}
