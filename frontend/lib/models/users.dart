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

  // สำหรับ API ล่าสุด (รองรับ full_name จาก backend, ถ้ามี)
  final String? fullName;

  User({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.studentId,
    this.teacherId,
    this.fullName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      studentId: json['student_id']?.toString(),
      teacherId: json['teacher_id']?.toString(),
      fullName: json['full_name']
          ?.toString(), // เพิ่มสำหรับ API รายชื่อ friends
      isActive: json['is_active'] is bool
          ? json['is_active']
          : (json['is_active'] == true || json['is_active'] == 'true'),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      lastLoginAt: json['last_login_at']?.toString(),
      roles: (json['roles'] is List)
          ? List<String>.from(json['roles'] as List)
          : <String>[],
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
      'full_name': fullName,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
      'roles': roles,
    };
  }

  /// ใช้เพื่อแสดงชื่อที่เหมาะสม เช่น บนหน้า People
  String get displayName {
    if ((fullName ?? '').trim().isNotEmpty) return fullName!.trim();
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty)
      return [fn, ln].where((s) => s.isNotEmpty).join(' ');
    if (username.isNotEmpty) return username;
    if ((email ?? '').isNotEmpty) return email!;
    return userId;
  }
}
