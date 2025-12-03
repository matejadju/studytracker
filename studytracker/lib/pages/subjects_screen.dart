import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import 'subject_detail_page.dart';

class SubjectsScreen extends StatelessWidget {
  SubjectsScreen({super.key});

  final SubjectService _subjectService = SubjectService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Subject>>(
        stream: _subjectService.getSubjects(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading subjects'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data!;
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.school, size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No subjects yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to add your first subject.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.school,
                      color: Colors.blue.shade700,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    subject.opis.isEmpty ? 'No description' : subject.opis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailPage(subject: subject),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showAddEditSubjectDialog(
                          context: context,
                          uid: uid,
                          existing: subject,
                        );
                      } else if (value == 'delete') {
                        final confirmed = await _showDeleteConfirmDialog(
                          context,
                          subject.name,
                        );
                        if (confirmed == true) {
                          await _subjectService.deleteSubject(subject.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subject deleted.'),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSubjectDialog(context: context, uid: uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Popup za nevalidan Name
  Future<void> _showNameValidationDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Invalid input'),
        content: const Text('Name is required.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditSubjectDialog({
    required BuildContext context,
    required String uid,
    Subject? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final opisController = TextEditingController(text: existing?.opis ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(existing == null ? 'Add subject' : 'Edit subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Mathematics',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: opisController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional – short description',
              ),
              maxLines: 3,
              maxLength: 120,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final opis = opisController.text.trim();

              if (name.isEmpty) {
                await _showNameValidationDialog(context);
                return;
              }

              if (existing == null) {
                final s = Subject(
                  id: '',
                  name: name,
                  opis: opis,
                  userId: uid,
                );
                await _subjectService.addSubject(s);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject added.')),
                );
              } else {
                final s = Subject(
                  id: existing.id,
                  name: name,
                  opis: opis,
                  userId: uid,
                );
                await _subjectService.updateSubject(existing.id, s);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject updated.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    String subjectName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Delete subject'),
        content: Text(
          'Are you sure you want to delete "$subjectName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
