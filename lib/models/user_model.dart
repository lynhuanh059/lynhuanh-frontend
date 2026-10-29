class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role; // "Admin", "Lecturer", "Student"

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Student',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role,
  };
}
