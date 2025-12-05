import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String userId;
  final String title;
  final String content;          // plain text (za listu, search...)
  final String? contentDelta;    // JSON iz Quill-a
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.contentDelta,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory za čitanje iz Firestore-a
  factory Note.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return Note(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      contentDelta: data['contentDelta'],
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  /// Map za upis u Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'contentDelta': contentDelta,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Factory za novu belešku (koristiš ga u editoru)
  factory Note.newNote({
    required String userId,
    required String title,
    required String content,
    String? contentDelta,
  }) {
    final now = DateTime.now();
    final id = FirebaseFirestore.instance.collection('notes').doc().id;

    return Note(
      id: id,
      userId: userId,
      title: title,
      content: content,
      contentDelta: contentDelta,
      createdAt: now,
      updatedAt: now,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    String? contentDelta,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      contentDelta: contentDelta ?? this.contentDelta,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
