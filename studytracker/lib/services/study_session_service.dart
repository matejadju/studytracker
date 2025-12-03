import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';

class StudySessionService {
  final _db = FirebaseFirestore.instance;

  Future<void> addSession(StudySession session) async {
    await _db.collection('study_sessions').add(session.toJson());
  }

  Stream<List<StudySession>> getSessionsForSubject(
      String subjectId, String userId) {
    return _db
        .collection('study_sessions')
        .where('subjectId', isEqualTo: subjectId)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudySession.fromJson(doc.id, doc.data()))
            .toList());
  }

  Stream<List<StudySession>> getSessionsForUser(String userId) {
    return _db
        .collection('study_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudySession.fromJson(doc.id, doc.data()))
            .toList());
  }
}
