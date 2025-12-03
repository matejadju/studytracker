import 'package:cloud_firestore/cloud_firestore.dart';

class Grade {
  final String id;
  final String subjectId;
  final String userId;        
  final int value;
  final DateTime dateReceived;

  Grade({
    required this.id,
    required this.subjectId,
    required this.userId,     
    required this.value,
    required this.dateReceived,
  });

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'userId': userId,          
        'value': value,
        'dateReceived': dateReceived,
      };

  factory Grade.fromJson(String id, Map<String, dynamic> json) => Grade(
        id: id,
        subjectId: json['subjectId'],
        userId: json['userId'],    
        value: json['value'],
        dateReceived: (json['dateReceived'] as Timestamp).toDate(),
      );
}
