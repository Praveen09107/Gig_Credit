import 'user_model.dart';

class AuthSessionModel {
  final UserModel user;
  final String token;
  final DateTime expiresAt;

  const AuthSessionModel({
    required this.user,
    required this.token,
    required this.expiresAt,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) => AuthSessionModel(
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    token: json['token'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
    'expiresAt': expiresAt.toIso8601String(),
  };
}
