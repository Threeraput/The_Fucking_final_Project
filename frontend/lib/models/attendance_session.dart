import 'dart:convert';

class AttendanceSession {
  final String sessionId;
  final String classId;
  final String teacherId;
  final DateTime openedAt;
  final DateTime? expiresAt;
  final double anchorLat;
  final double anchorLon;
  final double radiusMeters;
  final bool isClosed;

  AttendanceSession({
    required this.sessionId,
    required this.classId,
    required this.teacherId,
    required this.openedAt,
    required this.expiresAt,
    required this.anchorLat,
    required this.anchorLon,
    required this.radiusMeters,
    required this.isClosed,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> j) {
    return AttendanceSession(
      sessionId: j['session_id'] as String,
      classId: j['class_id'] as String,
      teacherId: j['teacher_id'] as String,
      openedAt: DateTime.parse(j['opened_at'] as String),
      expiresAt: j['expires_at'] != null
          ? DateTime.parse(j['expires_at'])
          : null,
      anchorLat: (j['anchor_lat'] as num).toDouble(),
      anchorLon: (j['anchor_lon'] as num).toDouble(),
      radiusMeters: (j['radius_meters'] as num).toDouble(),
      isClosed: j['is_closed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'class_id': classId,
    'teacher_id': teacherId,
    'opened_at': openedAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'anchor_lat': anchorLat,
    'anchor_lon': anchorLon,
    'radius_meters': radiusMeters,
    'is_closed': isClosed,
  };
}
