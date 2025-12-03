import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String subjectId;
  final String userId;       
  final int targetMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.subjectId,
    required this.userId,    
    required this.targetMinutes,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'userId': userId,          
        'targetMinutes': targetMinutes,
        'startDate': startDate,
        'endDate': endDate,
        'isCompleted': isCompleted,
      };

  factory Goal.fromJson(String id, Map<String, dynamic> json) => Goal(
        id: id,
        subjectId: json['subjectId'],
        userId: json['userId'],    
        targetMinutes: json['targetMinutes'],
        startDate: (json['startDate'] as Timestamp).toDate(),
        endDate: (json['endDate'] as Timestamp).toDate(),
        isCompleted: json['isCompleted'],
      );
}
