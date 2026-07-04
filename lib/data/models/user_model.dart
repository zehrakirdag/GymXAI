class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
    );
  }
}