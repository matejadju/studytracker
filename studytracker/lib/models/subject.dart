class Subject {
  final String id;
  final String name;
  final String opis;
  final String userId;

  Subject({required this.id, required this.name, required this.opis, required this.userId});

  Map<String, dynamic> toJson() => {
        'name': name,
        'opis': opis,
        'userId': userId,
      };

  factory Subject.fromJson(String id, Map<String, dynamic> json) => Subject(
        id: id,
        name: json['name'],
        opis: json['opis'],
        userId: json['userId'],
      );
}
