class Subject {
  final String id;
  final String name;
  final String opis;
  final String userId;
  final int year;
  final int? grade;

  Subject({
    required this.id,
    required this.name,
    required this.opis,
    required this.userId,
    required this.year,
    this.grade,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'opis': opis,
        'userId': userId,
        'year': year,
        'grade': grade,
      };

  factory Subject.fromJson(String id, Map<String, dynamic> json) => Subject(
        id: id,
        name: (json['name'] ?? '') as String,
        opis: (json['opis'] ?? '') as String,
        userId: (json['userId'] ?? '') as String,
        year: json['year'] ?? 1,
        grade: json['grade'],
      );
}
