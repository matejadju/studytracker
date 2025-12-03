import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addGoal(Goal goal) async {
    await _db.collection('goals').add(goal.toJson());
  }

  // ostavi ako ti treba
  Stream<List<Goal>> getGoalsForUser(String userId) {
    return _db
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Goal.fromJson(doc.id, doc.data())).toList());
  }

  Stream<List<Goal>> getGoalsForSubject(String userId, String subjectId) {
    return _db
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Goal.fromJson(doc.id, doc.data())).toList());
  }

  Future<void> updateGoalCompletion(String id, bool value) async {
    await _db.collection('goals').doc(id).update({'isCompleted': value});
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('goals').doc(id).delete();
  }
}
