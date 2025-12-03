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

  // umesto setState, samo on menja vreme
final ValueNotifier<int> _elapsedSeconds = ValueNotifier<int>(0);

  String? _selectedSubjectId;
  DateTime? _startTime;

  List<Subject> _subjects = []; // predmeti učitani jednom

  // formatiranje vremena
  String formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    // UCITAVANJE PREDMETA SAMO JEDNOM
    final user = FirebaseAuth.instance.currentUser!;
    _subjectService.getSubjects(user.uid).listen((list) {
      setState(() {
        _subjects = list;
      });
    });
  }

  void _startTimer() {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izaberite predmet pre pokretanja timera.')),
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
    if (_elapsedSeconds.value == 0 || _startTime == null || _selectedSubjectId == null) {
      return;
    }

    _timer?.cancel();

    final endTime = DateTime.now();
    final durationMinutes = (_elapsedSeconds.value / 60).round();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Niste prijavljeni.')),
      );
      return;
    }

    final session = StudySession(
      id: '',
      subjectId: _selectedSubjectId!,
      userId: user.uid,
      durationMinutes: durationMinutes,
      startTime: _startTime!,
      endTime: endTime,
      periodTypeId: 'focus',
    );

    await _sessionService.addSession(session);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sesija uspešno sačuvana.')));

    // RESET TIMERA
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
      return const Center(child: Text('Niste prijavljeni.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DROPDOWN – stabilan, ne treperi
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Predmet',
                border: OutlineInputBorder(),
              ),
              items: _subjects.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubjectId = value;
                });
              },
            ),

            const SizedBox(height: 40),

            // TIMER – ažurira se bez rebuild-a
            Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _elapsedSeconds,
                builder: (_, seconds, __) {
                  return Text(
                    formatTime(seconds),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // DUGMIĆI – stabilni
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startTimer,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : null,
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _elapsedSeconds.value > 0 ? _finishTimer : null,
                  child: const Text('Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
