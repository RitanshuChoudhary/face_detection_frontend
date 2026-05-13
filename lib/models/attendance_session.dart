class AttendanceSession {
  final int id;
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final int teacherId;
  final String teacherName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;

  AttendanceSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.startTime,
    this.endTime,
    required this.isActive,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] ?? 0,
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? (json['class_obj'] != null ? json['class_obj']['name'] : 'Class ${json['class_id']}'),
      subjectId: json['subject_id'] ?? 0,
      subjectName: json['subject_name'] ?? (json['subject'] != null ? json['subject']['name'] : 'Subject ${json['subject_id']}'),
      teacherId: json['teacher_id'] ?? 0,
      teacherName: json['teacher_name'] ?? (json['teacher'] != null ? json['teacher']['name'] : 'Teacher ${json['teacher_id']}'),
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      isActive: json['is_active'] ?? (json['end_time'] == null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'class_name': className,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
