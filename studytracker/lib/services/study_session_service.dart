import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';

class StudySessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addSession(StudySession session) async {
    await _db.collection('study_sessions').add(session.toJson());
  }

  // STREAM – sessions for specific subject
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

  // STREAM – all sessions for user
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

  // NEW – Needed for line chart: fetch **all sessions once**
  Future<List<StudySession>> getAllSessions(String userId) async {
    final snap = await _db
        .collection('study_sessions')
        .where('userId', isEqualTo: userId)
        .get();

    return snap.docs
        .map((d) => StudySession.fromJson(d.id, d.data()))
        .toList();
  }
}
