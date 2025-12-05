import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/achievement.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../services/exam_service.dart';
import '../services/study_session_service.dart';
import '../services/subject_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPage extends StatelessWidget {
  ProgressPage({super.key});

  final StudySessionService _sessionService = StudySessionService();
  final ExamService _examService = ExamService();
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<StudySession>>(
        stream: _sessionService.getSessionsForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          final totalMinutes =
              sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
          final xp = totalMinutes;

          final daysWithSessions = sessions
              .map((s) => DateTime(
                    s.startTime.year,
                    s.startTime.month,
                    s.startTime.day,
                  ))
              .toList();

          final streaks = _computeStreaks(daysWithSessions);
          final currentStreak = streaks.current;
          final bestStreak = streaks.best;

          final achievements = buildAchievements(
            totalMinutes: totalMinutes,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            sessions: sessions,
          );

          final dailyChallenge = _buildDailyChallenge(sessions);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GamificationCard(
                  totalMinutes: totalMinutes,
                  xp: xp,
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                ),
                const SizedBox(height: 16),
                _DailyChallengeCard(challenge: dailyChallenge),
                const SizedBox(height: 16),
                AchievementsSection(totalMinutes: totalMinutes),
                const SizedBox(height: 16),
                _StudyCalendarCard(sessions: sessions),
                const SizedBox(height: 16),
                _UpcomingExamsSection(
                  examService: _examService,
                  subjectService: _subjectService,
                  sessionService: _sessionService,
                  userId: uid,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _StreakResult _computeStreaks(List<DateTime> days) {
    if (days.isEmpty) return const _StreakResult(current: 0, best: 0);
    days.sort();

    final uniqueDays = <DateTime>[];
    DateTime? last;
    for (final d in days) {
      final day = DateTime(d.year, d.month, d.day);
      if (last == null || !isSameDay(last, day)) {
        uniqueDays.add(day);
        last = day;
      }
    }

    int best = 1;
    int temp = 1;
    for (int i = 1; i < uniqueDays.length; i++) {
      final prev = uniqueDays[i - 1];
      final cur = uniqueDays[i];
      if (cur.difference(prev).inDays == 1) {
        temp++;
      } else {
        if (temp > best) best = temp;
        temp = 1;
      }
    }
    if (temp > best) best = temp;

    final today = DateTime.now();
    int current = 0;
    DateTime cursor = DateTime(today.year, today.month, today.day);
    final set = uniqueDays.toSet();

    while (set.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return _StreakResult(current: current, best: best);
  }

  _DailyChallenge _buildDailyChallenge(List<StudySession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayMinutes = 0;
    int last7Minutes = 0;

    final from7 = today.subtract(const Duration(days: 7));

    for (final s in sessions) {
      final day =
          DateTime(s.startTime.year, s.startTime.month, s.startTime.day);

      if (!s.startTime.isBefore(from7)) {
        last7Minutes += s.durationMinutes;
      }

      if (day == today) {
        todayMinutes += s.durationMinutes;
      }
    }

    final avgPerDay = last7Minutes / 7.0;

    int target = avgPerDay.round();

    if (last7Minutes == 0) {
      target = 30;
    } else {
      if (target < 30) target = 30;
      if (target > 90) target = 90;
    }

    return _DailyChallenge(
      title: "Today's challenge",
      description: 'Study at least $target minutes today.',
      targetMinutes: target,
      currentMinutes: todayMinutes,
    );
  }
}

class _StreakResult {
  final int current;
  final int best;
  const _StreakResult({required this.current, required this.best});
}


class _DailyChallenge {
  final String title;
  final String description;
  final int targetMinutes;
  final int currentMinutes;

  const _DailyChallenge({
    required this.title,
    required this.description,
    required this.targetMinutes,
    required this.currentMinutes,
  });

  bool get completed => currentMinutes >= targetMinutes;

  double get progress {
    if (targetMinutes <= 0) return 0;
    final p = currentMinutes / targetMinutes;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }
}

List<Achievement> buildAchievements({
  required int totalMinutes,
  required int currentStreak,
  required int bestStreak,
  required List<StudySession> sessions,
}) {
  final maxSessionMinutes = sessions.isEmpty
      ? 0
      : sessions.map((s) => s.durationMinutes).reduce((a, b) => math.max(a, b));

  final List<Achievement> list = [];

  void addTimeAchievement({
    required String id,
    required String title,
    required String description,
    required int targetMinutes,
  }) {
    final unlocked = totalMinutes >= targetMinutes;
    list.add(
      Achievement(
        id: id,
        title: title,
        description: description,
        progress: totalMinutes.clamp(0, targetMinutes),
        target: targetMinutes,
        unlocked: unlocked,
        type: 'time',
        icon: 'star',
      ),
    );
  }

  addTimeAchievement(
    id: 'time_60',
    title: 'Getting started',
    description: 'Study at least 60 minutes in total.',
    targetMinutes: 60,
  );

  addTimeAchievement(
    id: 'time_300',
    title: '5-hour club',
    description: 'Study for 5 hours (300 minutes) in total.',
    targetMinutes: 300,
  );

  addTimeAchievement(
    id: 'time_1200',
    title: 'Study marathon',
    description: 'Study for 20 hours (1200 minutes) in total.',
    targetMinutes: 1200,
  );

  void addLongSessionAchievement({
    required String id,
    required String title,
    required String description,
    required int targetMinutes,
  }) {
    final unlocked = maxSessionMinutes >= targetMinutes;
    list.add(
      Achievement(
        id: id,
        title: title,
        description: description,
        progress: maxSessionMinutes.clamp(0, targetMinutes),
        target: targetMinutes,
        unlocked: unlocked,
        type: 'session',
        icon: 'bolt',
      ),
    );
  }

  addLongSessionAchievement(
    id: 'session_45',
    title: 'Deep focus',
    description: 'Finish a session of at least 45 minutes.',
    targetMinutes: 45,
  );

  addLongSessionAchievement(
    id: 'session_90',
    title: 'Power focus',
    description: 'Finish a session of at least 90 minutes.',
    targetMinutes: 90,
  );

  void addStreakAchievement({
    required String id,
    required String title,
    required String description,
    required int targetDays,
  }) {
    final unlocked = bestStreak >= targetDays;
    list.add(
      Achievement(
        id: id,
        title: title,
        description: description,
        progress: currentStreak.clamp(0, targetDays),
        target: targetDays,
        unlocked: unlocked,
        type: 'streak',
        icon: 'fire',
      ),
    );
  }

  addStreakAchievement(
    id: 'streak_3',
    title: '3-day streak',
    description: 'Study at least 3 days in a row.',
    targetDays: 3,
  );

  addStreakAchievement(
    id: 'streak_7',
    title: '7-day streak',
    description: 'Keep a 7-day study streak.',
    targetDays: 7,
  );

  return list;
}

/* ───────────── GAMIFICATION CARD ───────────── */

class _GamificationCard extends StatelessWidget {
  const _GamificationCard({
    required this.totalMinutes,
    required this.xp,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int totalMinutes;
  final int xp;
  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final hours = (totalMinutes / 60).toStringAsFixed(1);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade600,
              Colors.blue.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$hours h studied • $xp XP",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _pill(
                        label: "Current streak",
                        value:
                            "$currentStreak day${currentStreak == 1 ? '' : 's'}",
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        label: "Best streak",
                        value: "$bestStreak day${bestStreak == 1 ? '' : 's'}",
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _pill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────── DAILY CHALLENGE CARD ───────────── */

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final _DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = challenge.progress;
    final completed = challenge.completed;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: completed
                    ? Colors.green.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                completed ? Icons.check_circle : Icons.flag_outlined,
                color: completed ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${challenge.currentMinutes} / ${challenge.targetMinutes} min',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      if (completed)
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed ? Colors.green : Colors.blue,
                      ),
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
}

/* ───────────── STUDY CALENDAR CARD ───────────── */

class _StudyCalendarCard extends StatefulWidget {
  const _StudyCalendarCard({required this.sessions});

  final List<StudySession> sessions;

  @override
  State<_StudyCalendarCard> createState() => _StudyCalendarCardState();
}

class _StudyCalendarCardState extends State<_StudyCalendarCard> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.twoWeeks;

  late Map<DateTime, List<StudySession>> _byDay;

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _dayOnly(_focusedDay);
    _buildMap();
  }

  @override
  void didUpdateWidget(covariant _StudyCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions) {
      _buildMap();
    }
  }

  void _buildMap() {
    _byDay = {};
    for (final s in widget.sessions) {
      final d = _dayOnly(s.startTime);
      _byDay.putIfAbsent(d, () => []).add(s);
    }
  }

  List<StudySession> _eventsForDay(DateTime day) {
    return _byDay[_dayOnly(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSessions = _eventsForDay(_selectedDay);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  "Study calendar",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text("2 weeks"),
                  selected: _format == CalendarFormat.twoWeeks,
                  onSelected: (_) {
                    setState(() => _format = CalendarFormat.twoWeeks);
                  },
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Month"),
                  selected: _format == CalendarFormat.month,
                  onSelected: (_) {
                    setState(() => _format = CalendarFormat.month);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar<StudySession>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              availableCalendarFormats: const {
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.month: 'Month',
              },
              selectedDayPredicate: (day) =>
                  isSameDay(_dayOnly(day), _selectedDay),
              eventLoader: _eventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = _dayOnly(selectedDay);
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                outsideDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();

                  final totalMinutes = (events as List<StudySession>).fold<int>(
                    0,
                    (sum, s) => sum + s.durationMinutes,
                  );

                  
                  double t =
                      (totalMinutes / 120.0).clamp(0.2, 1.0); 
                  final color = Color.lerp(
                    Colors.blue.shade200,
                    Colors.blue.shade900,
                    t,
                  )!;

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 22,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (selectedSessions.isEmpty)
              Text(
                'No sessions on this day.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: selectedSessions.map((s) {
                  String _time(DateTime dt) =>
                      '${dt.hour.toString().padLeft(2, '0')}:' +
                      '${dt.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer_outlined),
                    title: Text('${s.durationMinutes} minutes'),
                    subtitle:
                        Text('${_time(s.startTime)} → ${_time(s.endTime)}'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────────── ACHIEVEMENTS ───────────── */

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({
    super.key,
    required this.totalMinutes,
  });

  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Achievements",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AchievementCard(
                    title: "Getting started",
                    description: "Study at least 60 minutes in total.",
                    current: totalMinutes.toDouble(),
                    target: 60,
                    
                    isPrimary: totalMinutes >= 60,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AchievementCard(
                    title: "5-hour club",
                    description: "Study for 5 hours (300 minutes) in total.",
                    current: totalMinutes.toDouble(),
                    target: 300,
                    isPrimary: totalMinutes >= 300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    this.isPrimary = false,
  });

  final String title;
  final String description;
  final double current;
  final double target;
  final bool isPrimary;

  double get _progress {
    if (target <= 0) return 0;
    final p = current / target;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progress;

    final bool completed = progress >= 1.0;

    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.star : Icons.star_border,
                size: 18,
                color: completed ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? Colors.blue : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────── UPCOMING EXAMS ───────────── */

class _UpcomingExamsSection extends StatelessWidget {
  const _UpcomingExamsSection({
    required this.examService,
    required this.subjectService,
    required this.sessionService,
    required this.userId,
  });

  final ExamService examService;
  final SubjectService subjectService;
  final StudySessionService sessionService;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Exam>>(
      stream: examService.getUpcomingExams(userId),
      builder: (context, examSnap) {
        if (examSnap.connectionState == ConnectionState.waiting &&
            !examSnap.hasData) {
          return _cardWrapper(
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (examSnap.hasError) {
          return _cardWrapper(
            child: Text(
              "Error loading exams: ${examSnap.error}",
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        final exams = examSnap.data ?? [];

        if (exams.isEmpty) {
          return _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      "Upcoming exams",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddExamDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "No upcoming exams yet.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Subject>>(
          future: subjectService.getSubjectsOnce(userId),
          builder: (context, subjSnap) {
            if (subjSnap.connectionState == ConnectionState.waiting &&
                !subjSnap.hasData) {
              return _cardWrapper(
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final subjects = subjSnap.data ?? [];
            final subjectMap = {
              for (final s in subjects) s.id: s,
            };

            exams.sort((a, b) => a.date.compareTo(b.date));

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final upcoming = exams
                .where((e) => !DateTime(e.date.year, e.date.month, e.date.day)
                    .isBefore(today))
                .toList();

            final Exam? nextExam = upcoming.isNotEmpty ? upcoming.first : null;

            return _cardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Upcoming exams",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showAddExamDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add"),
                      ),
                    ],
                  ),
                  if (nextExam != null) ...[
                    const SizedBox(height: 8),
                    _NextExamCountdownCard(
                      exam: nextExam,
                      subjectName:
                          subjectMap[nextExam.subjectId]?.name ?? "Subject",
                      sessionService: sessionService,
                      userId: userId,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                  ],
                  const SizedBox(height: 8),
                  ...exams.map((e) {
                    final d = DateTime(e.date.year, e.date.month, e.date.day);
                    final diffDays = d.difference(today).inDays.clamp(0, 9999);
                    final subtitle =
                        "${d.day}.${d.month}.${d.year}. • $diffDays day${diffDays == 1 ? '' : 's'} left";

                    final color = diffDays <= 3
                        ? Colors.red
                        : (diffDays <= 7 ? Colors.orange : Colors.green);

                    final subjName = subjectMap[e.subjectId]?.name ?? "Subject";

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(Icons.book_outlined, color: color),
                      ),
                      title: Text(
                        e.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "$subjName • $subtitle",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await examService.deleteExam(e.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Exam deleted."),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _cardWrapper({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    );
  }

  Future<void> _showAddExamDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? selectedDate;
    Subject? selectedSubject;

    final subjects = await subjectService.getSubjectsOnce(userId);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Add exam'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Subject>(
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem<Subject>(
                            value: s,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => selectedSubject = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Exam name',
                      hintText: 'e.g. Midterm, Final exam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select date'
                              : '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: now,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Pick date'),
                      ),
                    ],
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
                  final title = titleController.text.trim();

                  if (selectedSubject == null ||
                      title.isEmpty ||
                      selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields.'),
                      ),
                    );
                    return;
                  }

                  final exam = Exam(
                    id: '',
                    userId: userId,
                    subjectId: selectedSubject!.id,
                    title: title,
                    date: selectedDate!,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );

                  await examService.addExam(exam);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exam added.'),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextExamCountdownCard extends StatelessWidget {
  const _NextExamCountdownCard({
    required this.exam,
    required this.subjectName,
    required this.sessionService,
    required this.userId,
  });

  final Exam exam;
  final String subjectName;
  final StudySessionService sessionService;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final examDate = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final diff = examDate.difference(now);

    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours.remainder(24);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade500,
            Colors.indigo.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Next exam",
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exam.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subjectName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _countdownBox(
                label: "Days",
                value: daysLeft.clamp(0, 999).toString(),
              ),
              const SizedBox(width: 8),
              _countdownBox(
                label: "Hours",
                value: hoursLeft.clamp(0, 23).toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<StudySession>>(
            stream: sessionService.getSessionsForSubject(
              exam.subjectId,
              userId,
            ),
            builder: (context, snap) {
              int minutesLast7Days = 0;
              if (snap.hasData) {
                final from = now.subtract(const Duration(days: 7));
                for (final s in snap.data!) {
                  if (s.startTime.isAfter(from)) {
                    minutesLast7Days += s.durationMinutes;
                  }
                }
              }

              final prepRatio =
                  (minutesLast7Days / 300).clamp(0.0, 1.0) as double;
              final prepPercent = (prepRatio * 100).round();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Preparation",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$prepPercent%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: prepRatio,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightGreenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$minutesLast7Days min studied in last 7 days",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _countdownBox({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
