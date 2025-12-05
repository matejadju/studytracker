// lib/pages/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// PDF export
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note.dart';
import '../services/note_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.userId,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final String userId;

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Your notes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: widget.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add note'),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.listenNotes(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error while loading notes.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 56,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No notes yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap “Add note” to write your first study note.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              final subtitle = note.content.trim().isEmpty
                  ? '(No content)'
                  : note.content.trim().split('\n').first;

              return Card(
                color: isDark ? theme.cardColor : Colors.white,
                elevation: isDark ? 1 : 3,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => _openNoteEditor(context, existing: note),
                  title: Text(
                    note.title.isEmpty ? '(Untitled note)' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        tooltip: 'Export this note to PDF',
                        onPressed: () => _exportNoteToPdf(note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(note),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Delete note'),
        content: const Text('Are you sure you want to delete this note?'),
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

    if (confirmed == true) {
      await _noteService.deleteNote(note.userId, note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted.')),
      );
    }
  }

  void _openNoteEditor(BuildContext context, {Note? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          userId: widget.userId,
          existing: existing,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Note created.' : 'Note updated.',
          ),
        ),
      );
    }
  }

  /// -------- PDF EXPORT ZA JEDNU BELEŠKU --------
  Future<void> _exportNoteToPdf(Note note) async {
    final doc = pw.Document();

    final title = note.title.isEmpty ? 'Untitled note' : note.title.trim();
    final content =
        note.content.isEmpty ? '(No content)' : note.content.trim();

    String created = '';
    String updated = '';
    try {
      created = DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt);
      updated = DateFormat('dd.MM.yyyy HH:mm').format(note.updatedAt);
    } catch (_) {}

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'StudyTracker Notes',
              style: pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 16),

          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          if (created.isNotEmpty)
            pw.Text(
              'Created: $created',
              style: pw.TextStyle(
                fontSize: 10,
              ),
            ),
          if (updated.isNotEmpty)
            pw.Text(
              'Last updated: $updated',
              style: pw.TextStyle(
                fontSize: 10,
              ),
            ),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),

          pw.Text(
            content,
            style: pw.TextStyle(
              fontSize: 14,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }
}

// ----------------- EDITOR -----------------

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    required this.userId,
    this.existing,
  });

  final String userId;
  final Note? existing;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final NoteService _noteService = NoteService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _contentController =
        TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title or some content.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.existing == null) {
        final note = Note.newNote(
          userId: widget.userId,
          title: title,
          content: content,
        );
        await _noteService.addNote(note);
      } else {
        final updated = widget.existing!.copyWith(
          title: title,
          content: content,
          updatedAt: DateTime.now(),
        );
        await _noteService.updateNote(updated);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New note' : 'Edit note'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _saveNote,
            tooltip: 'Save note',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Card(
              color: isDark ? theme.cardColor : Colors.white,
              elevation: isDark ? 1 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'Write your note here...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
