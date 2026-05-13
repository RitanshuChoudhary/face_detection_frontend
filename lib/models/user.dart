class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'admin', 'teacher', 'student'
  final int? studentId; // If student role
  final int? teacherId; // If teacher role

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.teacherId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      studentId: json['student_id'],
      teacherId: json['teacher_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'student_id': studentId,
      'teacher_id': teacherId,
    };
  }
}
