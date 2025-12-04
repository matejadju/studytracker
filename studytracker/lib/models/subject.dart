class Subject {
  final String id;
  final String name;
  final String opis;
  final String userId;
  final int? grade;

  Subject({
    required this.id,
    required this.name,
    required this.opis,
    required this.userId,
    this.grade,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'opis': opis,
        'userId': userId,
        'grade': grade,
      };

  factory Subject.fromJson(String id, Map<String, dynamic> json) => Subject(
        id: id,
        name: (json['name'] ?? '') as String,
        opis: (json['opis'] ?? '') as String,
        userId: (json['userId'] ?? '') as String,
        grade: json['grade'],
      );
}
