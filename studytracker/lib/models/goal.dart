import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String subjectId;
  final String userId;
  final String periodType;
  final int targetMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.subjectId,
    required this.userId, 
    required this.periodType,
    required this.targetMinutes,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'userId': userId,  
        'periodType': periodType,
        'targetMinutes': targetMinutes,
        'startDate': startDate,
        'endDate': endDate,
        'isCompleted': isCompleted,
      };

  factory Goal.fromJson(String id, Map<String, dynamic> json) => Goal(
      id: id,
      subjectId: (json['subjectId'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      periodType: (json['periodType'] ?? 'weekly') as String,
      targetMinutes: (json['targetMinutes'] ?? 0) as int,
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : (json['startDate'] as DateTime? ?? DateTime.now()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : (json['endDate'] as DateTime? ?? DateTime.now()),
      isCompleted: (json['isCompleted'] ?? false) as bool,
    );

}
