import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import 'subject_detail_page.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}


class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectService _subjectService = SubjectService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }
    final uid = user.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Subjects'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSubjectDialog(context: context, uid: uid),
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
        backgroundColor: const Color.fromARGB(255, 92, 170, 244),  
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
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
          final filtered = subjects
              .where((s) =>
                  s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            children: [
              
              _buildHeader(context, subjectsCount: subjects.length),

              
StreamBuilder<List<Subject>>(
  stream: _subjectService.getSubjects(uid),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox(height: 0);

    final subjects = snapshot.data!;
    final graded = subjects.where((s) => s.grade != null).toList();

    if (graded.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          "Average grade: N/A",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final avg = graded.map((s) => s.grade!).reduce((a, b) => a + b) / graded.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.star_half, size: 28),
              const SizedBox(width: 12),
              Text(
                "Average grade: ${avg.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
),


              
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search subjects',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(width: 2),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceVariant
                        : Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32.0, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_outlined,
                                  size: 56,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                subjects.isEmpty
                                    ? 'No subjects yet'
                                    : 'No results for "$_searchQuery"',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subjects.isEmpty
                                    ? 'Tap “Add subject” to create your first subject.'
                                    : 'Try a different name or clear the search.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final subject = filtered[index];
                          final initial = subject.name.isNotEmpty
                              ? subject.name.trim()[0].toUpperCase()
                              : '?';

                          return _SubjectCard(
                            subject: subject,
                            initial: initial,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubjectDetailPage(
                                    subject: subject,
                                    onToggleTheme: widget.onToggleTheme,
                                    isDarkMode: widget.isDarkMode,
                                  ),
                                ),
                              );

                            },
                            onEdit: () => _showAddEditSubjectDialog(
                              context: context,
                              uid: uid,
                              existing: subject,
                            ),
                            onDelete: () async {
                              final confirmed = await _showDeleteConfirmDialog(
                                context,
                                subject.name,
                              );
                              if (confirmed == true) {
                                await _subjectService.deleteSubject(subject.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Subject deleted.'),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required int subjectsCount}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    primary.withOpacity(0.95),
                    secondary.withOpacity(0.9),
                  ]
                : const [
                    Color(0xFF6DB8FF),
                    Color(0xFF3FA9F5),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your subjects",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subjectsCount == 0
                        ? "Start by adding a subject you study."
                        : "$subjectsCount subject${subjectsCount == 1 ? '' : 's'} tracked in StudyTracker.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(existing == null ? 'Add subject' : 'Edit subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Mathematics',
                    prefixIcon: const Icon(Icons.book_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(width: 2),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceVariant
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: opisController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional – short description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(width: 2),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceVariant
                        : Colors.white,
                  ),
                  maxLines: 3,
                  maxLength: 120,
                ),
              ],
            ),
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
        );
      },
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


class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.initial,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final String initial;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? theme.cardColor : Colors.white,
      elevation: isDark ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceVariant,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFE5F2FF), 
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.white,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.opis.isEmpty ? 'No description' : subject.opis,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
