import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class SubjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addSubject(Subject subject) async {
    await _db.collection('subjects').add(subject.toJson());
  }

  Stream<List<Subject>> getSubjects(String userId) {
    return _db
        .collection('subjects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Subject.fromJson(doc.id, doc.data())).toList());
  }

  Future<void> updateSubject(String id, Subject subject) async {
    await _db.collection('subjects').doc(id).update(subject.toJson());
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  Future<List<Subject>> getSubjectsOnce(String userId) async {
  final snap = await _db
      .collection('subjects')
      .where('userId', isEqualTo: userId)
      .get();

  return snap.docs
      .map((doc) => Subject.fromJson(doc.id, doc.data()))
      .toList();
}
}
