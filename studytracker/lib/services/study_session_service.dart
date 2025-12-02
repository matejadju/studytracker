import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';

class StudySessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addStudySession(StudySession session) async {
    await _db.collection('study_sessions').add(session.toJson());
  }

  Stream<List<StudySession>> getSessions(String userId, String subjectId) {
    return _db
        .collection('study_sessions')
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudySession.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> deleteStudySession(String id) async {
    await _db.collection('study_sessions').doc(id).delete();
  }
}
