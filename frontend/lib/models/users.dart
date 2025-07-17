class User {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? studentId;
  final String? teacherId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? lastLoginAt;
  final List<String> roles;

  User({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.studentId,
    this.teacherId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      studentId: json['student_id'],
      teacherId: json['teacher_id'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lastLoginAt: json['last_login_at'],
      roles: List<String>.from(json['roles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'student_id': studentId,
      'teacher_id': teacherId,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
      'roles': roles,
    };
  }
}
