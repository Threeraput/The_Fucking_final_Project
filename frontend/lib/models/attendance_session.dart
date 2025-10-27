// lib/models/attendance_session.dart
class AttendanceSession {
  final String sessionId;
  final String classId;
  final String teacherId;
  final DateTime createdAt; // หรือ startTime ในบางสคีมา
  final DateTime? expiresAt; // ถ้ามี
  final int? radiusMeters; // ถ้ามี
  final bool isActive;

  AttendanceSession({
    required this.sessionId,
    required this.classId,
    required this.teacherId,
    required this.createdAt,
    this.expiresAt,
    this.radiusMeters,
    required this.isActive,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    bool _bool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return true;
    }

    return AttendanceSession(
      sessionId: (json['session_id'] ?? json['id'] ?? '').toString(),
      classId: (json['class_id'] ?? '').toString(),
      teacherId: (json['teacher_id'] ?? '').toString(),
      createdAt:
          _dt(json['created_at'] ?? json['start_time']) ?? DateTime.now(),
      expiresAt: _dt(json['expires_at'] ?? json['end_time']),
      radiusMeters: _int(json['radius_meters']),
      isActive: _bool(json['is_active'] ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'class_id': classId,
    'teacher_id': teacherId,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'radius_meters': radiusMeters,
    'is_active': isActive,
  };
}
