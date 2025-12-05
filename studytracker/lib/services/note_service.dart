import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final _db = FirebaseFirestore.instance;

  /// stream svih beleški za datog usera
  Stream<List<Note>> listenNotes(String userId) {
    return _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        // privremeno bez orderBy da ne traži indeks
        //.orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Note.fromDoc(d)).toList());
  }

  /// jednokratno branje
  Future<List<Note>> getNotesOnce(String userId) async {
    final snap = await _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        // opet bez orderBy dok indeks ne bude 100% ready
        //.orderBy('updatedAt', descending: true)
        .get();

    return snap.docs.map((d) => Note.fromDoc(d)).toList();
  }

  /// dodavanje nove beleške
  Future<void> addNote(Note note) async {
    await _db.collection('notes').doc(note.id).set(note.toMap());
  }

  /// update postojeće
  Future<void> updateNote(Note note) async {
    await _db.collection('notes').doc(note.id).update(note.toMap());
  }

  /// brisanje
  Future<void> deleteNote(String userId, String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }
}
