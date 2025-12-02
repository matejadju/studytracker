import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String subjectId;
  final String title;
  final DateTime dueDateTime;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.dueDateTime,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'title': title,
        'dueDateTime': dueDateTime,
        'isCompleted': isCompleted,
      };

  factory Reminder.fromJson(String id, Map<String, dynamic> json) => Reminder(
        id: id,
        subjectId: json['subjectId'],
        title: json['title'],
        dueDateTime: (json['dueDateTime'] as Timestamp).toDate(),
        isCompleted: json['isCompleted'],
      );
}
