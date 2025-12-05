import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam.dart';

class ExamService {
  final _db = FirebaseFirestore.instance;

  Future<void> addExam(Exam exam) async {
    await _db.collection('exams').add(exam.toJson());
  }

  /// SVI ispiti korisnika (i prošli i budući),
  /// sortira se po datumu na klijentu.
  Stream<List<Exam>> getExamsForUser(String userId) {
    return _db
        .collection('exams')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Exam.fromJson(d.id, d.data())).toList()
            ..sort((a, b) => a.date.compareTo(b.date)),
        );
  }

  /// Samo "upcoming" – filtriramo po datumu na klijentu
  /// da NE bismo morali da pravimo Firestore index.
  Stream<List<Exam>> getUpcomingExams(String userId) {
    final todayStart = DateTime.now();
    final startOfToday =
        DateTime(todayStart.year, todayStart.month, todayStart.day);

    return getExamsForUser(userId).map(
      (all) => all
          .where((e) =>
              e.date.isAfter(startOfToday) || _isSameDay(e.date, startOfToday))
          .toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> deleteExam(String id) async {
    await _db.collection('exams').doc(id).delete();
  }
}
