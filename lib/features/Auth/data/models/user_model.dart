import 'package:perjalanan_dinas/features/Auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return UserModel(
      uid: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': uid,
    'email': email,
    'name': name,
    'token': token,
  };
}
