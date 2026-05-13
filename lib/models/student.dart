class Student {
  final int id;
  final String name;
  final String email;
  final String rollNumber;
  final int classId;
  final String? className;
  final bool hasFaceRegistered;
  final List<String> faceImages;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.classId,
    this.className,
    required this.hasFaceRegistered,
    required this.faceImages,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    var faceList = json['face_images'];
    List<String> list = [];
    if (faceList != null) {
      list = List<String>.from(faceList);
    }
    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      rollNumber: json['roll_number'] ?? '',
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? (json['class_obj'] != null ? json['class_obj']['name'] : null),
      hasFaceRegistered: json['has_face_registered'] ?? (list.isNotEmpty),
      faceImages: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roll_number': rollNumber,
      'class_id': classId,
      'class_name': className,
      'has_face_registered': hasFaceRegistered,
      'face_images': faceImages,
    };
  }
}
