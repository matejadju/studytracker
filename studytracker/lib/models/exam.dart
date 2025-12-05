import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final DateTime date;
  final String? note;

  Exam({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'subjectId': subjectId,
        'title': title,
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  factory Exam.fromJson(String id, Map<String, dynamic> json) {
    return Exam(
      id: id,
      userId: json['userId'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      date: (json['date'] as Timestamp).toDate(),
      note: json['note'] as String?,
    );
  }
}
