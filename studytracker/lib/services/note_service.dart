import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final _db = FirebaseFirestore.instance;

  
  Stream<List<Note>> listenNotes(String userId) {
    return _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        
        
        .snapshots()
        .map((snap) => snap.docs.map((d) => Note.fromDoc(d)).toList());
  }

  
  Future<List<Note>> getNotesOnce(String userId) async {
    final snap = await _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        
        
        .get();

    return snap.docs.map((d) => Note.fromDoc(d)).toList();
  }

  
  Future<void> addNote(Note note) async {
    await _db.collection('notes').doc(note.id).set(note.toMap());
  }

  
  Future<void> updateNote(Note note) async {
    await _db.collection('notes').doc(note.id).update(note.toMap());
  }

  
  Future<void> deleteNote(String userId, String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }
}
