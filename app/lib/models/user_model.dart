class UserModel {
  final String id;
  final String mobile;
  final String? name;
  final bool isVerified;
  
  const UserModel({
    required this.id,
    required this.mobile,
    this.name,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    mobile: json['mobile'] as String,
    name: json['name'] as String?,
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mobile': mobile,
    'name': name,
    'isVerified': isVerified,
  };
}
