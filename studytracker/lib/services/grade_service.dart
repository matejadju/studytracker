import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';

class GradeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addGrade(Grade grade) async {
    await _db.collection('grades').add(grade.toJson());
  }

  Stream<List<Grade>> getGrades(String userId, String subjectId) {
    return _db
        .collection('grades')
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Grade.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> deleteGrade(String id) async {
    await _db.collection('grades').doc(id).delete();
  }
}
