import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

class ReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addReminder(Reminder reminder) async {
    await _db.collection('reminders').add(reminder.toJson());
  }

  Stream<List<Reminder>> getReminders(String userId, String subjectId) {
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reminder.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> setReminderCompleted(String id, bool value) async {
    await _db.collection('reminders').doc(id).update({'isCompleted': value});
  }

  Future<void> deleteReminder(String id) async {
    await _db.collection('reminders').doc(id).delete();
  }
}
