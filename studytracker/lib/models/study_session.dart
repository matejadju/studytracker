import 'package:cloud_firestore/cloud_firestore.dart';


class StudySession {
  final String id;
  final String subjectId;
  final String userId;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final String periodTypeId;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.userId,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.periodTypeId,
  });

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'userId': userId,
        'duration_minutes': durationMinutes,
        'startTime': startTime,
        'endTime': endTime,
        'periodTypeId': periodTypeId,
      };

  factory StudySession.fromJson(String id, Map<String, dynamic> json) => StudySession(
        id: id,
        subjectId: json['subjectId'],
        userId: json['userId'],
        durationMinutes: json['duration_minutes'],
        startTime: (json['startTime'] as Timestamp).toDate(),
        endTime: (json['endTime'] as Timestamp).toDate(),
        periodTypeId: json['periodTypeId'],
      );
}
