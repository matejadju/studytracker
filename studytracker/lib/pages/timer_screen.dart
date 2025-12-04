import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../models/subject.dart';
import '../services/study_session_service.dart';
import '../services/subject_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final StudySessionService _sessionService = StudySessionService();
  final SubjectService _subjectService = SubjectService();

  Timer? _timer;
  bool _isRunning = false;

  final ValueNotifier<int> _elapsedSeconds = ValueNotifier<int>(0);

  String? _selectedSubjectId;
  DateTime? _startTime;

  List<Subject> _subjects = [];
  bool _loadingSubjects = true;

  String formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    return '${h.toString().padLeft(2, '0')} : '
        '${m.toString().padLeft(2, '0')} : '
        '${s.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}."
        "${dt.month.toString().padLeft(2, '0')}."
        "${dt.year}  "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser!;
    _subjectService.getSubjectsOnce(user.uid).then((list) {
      if (!mounted) return;
      setState(() {
        _subjects = list;
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first.id;
        }
        _loadingSubjects = false;
      });
    });
  }

  void _startTimer() {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first.')),
      );
      return;
    }

    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _startTime ??= DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds.value++;
      if (mounted) {}
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _finishTimer() async {
    if (_elapsedSeconds.value == 0 ||
        _startTime == null ||
        _selectedSubjectId == null) {
      return;
    }

    _timer?.cancel();

    final endTime = DateTime.now();
    final durationMinutes = (_elapsedSeconds.value / 60).ceil();
    final user = FirebaseAuth.instance.currentUser;

    final session = StudySession(
      id: '',
      subjectId: _selectedSubjectId!,
      userId: user!.uid,
      durationMinutes: durationMinutes,
      startTime: _startTime!,
      endTime: endTime,
      periodTypeId: 'weekly',
    );

    await _sessionService.addSession(session);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Study session saved successfully.')),
    );

    setState(() {
      _timer = null;
      _isRunning = false;
      _startTime = null;
      _elapsedSeconds.value = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedSeconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in.')),
      );
    }

    if (_loadingSubjects) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Focus timer'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // SUBJECT + INFO CARD
              _SubjectCard(
                subjects: _subjects,
                selectedSubjectId: _selectedSubjectId,
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // TIMER CARD (lepši izgled)
              _TimerCard(
                elapsedSeconds: _elapsedSeconds,
                isRunning: _isRunning,
                onStart: _startTimer,
                onPause: _pauseTimer,
                onFinish: _elapsedSeconds.value > 0 ? _finishTimer : null,
              ),

              const SizedBox(height: 16),

              // HISTORY
              Expanded(
                child: _selectedSubjectId == null
                    ? const Center(
                        child: Text(
                          "Select a subject to see your study sessions.",
                        ),
                      )
                    : _SessionsHistory(
                        subjectId: _selectedSubjectId!,
                        userId: user.uid,
                        formatDate: formatDate,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------
// UI WIDGETI
// ---------------------

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subjects,
    required this.selectedSubjectId,
    required this.onChanged,
  });

  final List<Subject> subjects;
  final String? selectedSubjectId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Subject",
                border: InputBorder.none,
                isDense: true,
              ),
              isExpanded: true,
              value: selectedSubjectId,
              items: subjects.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.elapsedSeconds,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onFinish,
  });

  final ValueNotifier<int> elapsedSeconds;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final Future<void> Function()? onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Focus session",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: elapsedSeconds,
            builder: (_, seconds, __) {
              final h = seconds ~/ 3600;
              final m = (seconds % 3600) ~/ 60;
              final s = seconds % 60;

              return Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${h.toString().padLeft(2, '0')} : '
                  '${m.toString().padLeft(2, '0')} : '
                  '${s.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimerActionButton(
                icon: Icons.play_arrow_rounded,
                label: "Start",
                onPressed: isRunning ? null : onStart,
                background: Colors.white,
                foreground: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              _TimerActionButton(
                icon: Icons.pause_rounded,
                label: "Pause",
                onPressed: isRunning ? onPause : null,
                background: Colors.white.withOpacity(0.12),
                foreground: Colors.white,
              ),
              const SizedBox(width: 12),
              _TimerActionButton(
                icon: Icons.check_rounded,
                label: "Finish",
                onPressed: (elapsedSeconds.value > 0 && onFinish != null)
                    ? () {
                        onFinish!(); // pozovemo async funkciju, ali ne vraćamo ništa
                      }
                    : null,
                background: Colors.white.withOpacity(0.12),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isRunning ? "Timer is running..." : "Tap Start to begin studying.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerActionButton extends StatelessWidget {
  const _TimerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? background : background.withOpacity(0.6),
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withOpacity(0.4),
        disabledBackgroundColor: background.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: isEnabled ? 2 : 0,
      ),
    );
  }
}

class _SessionsHistory extends StatelessWidget {
  const _SessionsHistory({
    required this.subjectId,
    required this.userId,
    required this.formatDate,
  });

  final String subjectId;
  final String userId;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final sessionService = StudySessionService();

    return StreamBuilder<List<StudySession>>(
      stream: sessionService.getSessionsForSubject(subjectId, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No saved sessions for this subject yet."),
          );
        }

        final sessions = snapshot.data!;
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, s) => sum + s.durationMinutes,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Study history",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "Total time: $totalMinutes minutes",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.timer_outlined),
                      ),
                      title: Text("${s.durationMinutes} minutes"),
                      subtitle: Text(
                        "${formatDate(s.startTime)} → ${formatDate(s.endTime)}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
