class AttendanceRecord {
  final int id;
  final int sessionId;
  final int studentId;
  final String studentName;
  final String rollNumber;
  final String status; // 'present', 'absent', 'late'
  final DateTime markedAt;
  final String markedBy; // 'face_recognition', 'manual'
  final double? confidenceScore;
  final String? faceImageUrl;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.status,
    required this.markedAt,
    required this.markedBy,
    this.confidenceScore,
    this.faceImageUrl,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'] ?? (json['student'] != null ? json['student']['name'] : 'Student ${json['student_id']}'),
      rollNumber: json['roll_number'] ?? (json['student'] != null ? json['student']['roll_number'] : ''),
      status: json['status'] ?? 'absent',
      markedAt: DateTime.parse(json['marked_at'] ?? DateTime.now().toIso8601String()),
      markedBy: json['marked_by'] ?? 'manual',
      confidenceScore: json['confidence_score'] != null ? (json['confidence_score'] as num).toDouble() : null,
      faceImageUrl: json['face_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': studentName,
      'roll_number': rollNumber,
      'status': status,
      'marked_at': markedAt.toIso8601String(),
      'marked_by': markedBy,
      'confidence_score': confidenceScore,
      'face_image_url': faceImageUrl,
    };
  }
}
