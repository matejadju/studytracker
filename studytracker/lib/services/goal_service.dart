import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import 'notification_service.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addGoal(Goal goal) async {
    // 1. Sačuvaj goal u Firestore
    final docRef = await _db.collection('goals').add(goal.toJson());
    print("GOAL SAVED: ${docRef.id}");

    // 🔹 Unikatan ID za notifikaciju (izbegavamo hashCode probleme)
    final notifId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    final reminderTime = DateTime.now().add(const Duration(seconds: 10));
    print("SCHEDULING NOTIF AT: $reminderTime, id=$notifId");

    // 2. Instant notifikacija da znamo da se addGoal pozvao
    await NotificationService().showInstantNotification(
      title: 'Goal created',
      body: 'Goal created — reminder scheduled.',
      id: notifId,
    );

    // 3. Zakazana notifikacija za 10 sekundi (test)
    await NotificationService().scheduleNotification(
      id: notifId + 1,
      title: 'Goal reminder (test)',
      body: 'This is a test reminder 10 seconds after goal creation.',
      scheduledTime: reminderTime,
    );
  }

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
