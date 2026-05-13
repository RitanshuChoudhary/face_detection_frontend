class Classroom {
  final int id;
  final String name;

  Classroom({
    required this.id,
    required this.name,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
