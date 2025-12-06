import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../models/subject.dart';
import '../services/study_session_service.dart';
import '../services/subject_service.dart';

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  final _sessionService = StudySessionService();
  final _subjectService = SubjectService();

  bool _isGenerating = false;
  String? _adviceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Coach'),
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<List<StudySession>>(
        stream: _sessionService.getSessionsForUser(uid),
        builder: (context, sessionSnap) {
          if (sessionSnap.connectionState == ConnectionState.waiting &&
              !sessionSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = sessionSnap.data ?? [];

          return FutureBuilder<List<Subject>>(
            future: _subjectService.getSubjectsOnce(uid),
            builder: (context, subjectSnap) {
              if (subjectSnap.connectionState == ConnectionState.waiting &&
                  !subjectSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final subjects = subjectSnap.data ?? [];
              final subjectMap = {for (final s in subjects) s.id: s};

              final stats = _computeStats(sessions, subjectMap);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryHeader(stats: stats),
                    const SizedBox(height: 16),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 16),
                    _BestTimesCard(stats: stats),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isGenerating
                          ? null
                          : () async {
                              setState(() {
                                _isGenerating = true;
                              });

                              await Future.delayed(
                                  const Duration(milliseconds: 400));

                              final advice =
                                  _buildAdviceFromStats(stats, subjects);

                              if (!mounted) return;
                              setState(() {
                                _adviceText = advice;
                                _isGenerating = false;
                              });
                            },
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        _isGenerating
                            ? 'Analyzing your data...'
                            : 'Ask AI coach',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_adviceText != null)
                      _AdviceBubble(text: _adviceText!)
                    else
                      const Text(
                        "Tap \"Ask AI coach\" to get a personalized suggestion based on your recent study sessions. (Simulated offline coach 🧠)",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  _CoachStats _computeStats(
    List<StudySession> sessions,
    Map<String, Subject> subjectMap,
  ) {
    if (sessions.isEmpty) {
      return const _CoachStats.empty();
    }

    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));

    int totalMinutes = 0;
    int totalSessions = sessions.length;
    int todayMinutes = 0;
    int last7DaysMinutes = 0;

    final Map<String, int> minutesBySubject = {};

    final List<int> minutesByWeekday = List.filled(7, 0);

    int morningMin = 0;
    int afternoonMin = 0;
    int eveningMin = 0;
    int nightMin = 0;

    for (final s in sessions) {
      totalMinutes += s.durationMinutes;

      final start = s.startTime;
      final dayKey = DateTime(start.year, start.month, start.day);

      if (dayKey == todayKey) {
        todayMinutes += s.durationMinutes;
      }

      if (start.isAfter(weekAgo)) {
        last7DaysMinutes += s.durationMinutes;
      }

      minutesBySubject.update(
        s.subjectId,
        (old) => old + s.durationMinutes,
        ifAbsent: () => s.durationMinutes,
      );

      final weekdayIndex = start.weekday % 7;
      minutesByWeekday[weekdayIndex] += s.durationMinutes;

      final h = start.hour;
      if (h >= 5 && h <= 11) {
        morningMin += s.durationMinutes;
      } else if (h >= 12 && h <= 17) {
        afternoonMin += s.durationMinutes;
      } else if (h >= 18 && h <= 23) {
        eveningMin += s.durationMinutes;
      } else {
        nightMin += s.durationMinutes;
      }
    }

    final double avgSessionMinutes =
        totalSessions == 0 ? 0 : totalMinutes / totalSessions;

    String? topSubjectId;
    int topSubjectMinutes = 0;
    minutesBySubject.forEach((id, mins) {
      if (mins > topSubjectMinutes) {
        topSubjectMinutes = mins;
        topSubjectId = id;
      }
    });
    final topSubjectName = topSubjectId != null
        ? (subjectMap[topSubjectId]?.name ?? 'Subject')
        : null;

    int bestWeekdayIndex = 0;
    int bestWeekdayMinutes = 0;
    for (int i = 0; i < minutesByWeekday.length; i++) {
      if (minutesByWeekday[i] > bestWeekdayMinutes) {
        bestWeekdayMinutes = minutesByWeekday[i];
        bestWeekdayIndex = i;
      }
    }

    final parts = {
      'Morning': morningMin,
      'Afternoon': afternoonMin,
      'Evening': eveningMin,
      'Night': nightMin,
    };
    String topDayPart = 'Evening';
    int topDayPartMin = 0;
    parts.forEach((label, mins) {
      if (mins > topDayPartMin) {
        topDayPartMin = mins;
        topDayPart = label;
      }
    });

    return _CoachStats(
      totalMinutes: totalMinutes,
      totalSessions: totalSessions,
      avgSessionMinutes: avgSessionMinutes,
      todayMinutes: todayMinutes,
      last7DaysMinutes: last7DaysMinutes,
      topSubjectName: topSubjectName,
      minutesBySubject: minutesBySubject,
      bestWeekdayIndex: bestWeekdayIndex,
      bestWeekdayMinutes: bestWeekdayMinutes,
      topDayPartLabel: topDayPart,
    );
  }

  String _buildAdviceFromStats(
    _CoachStats stats,
    List<Subject> subjects,
  ) {
    if (stats.totalMinutes == 0) {
      return "I don’t see any study sessions yet. Start tracking even short sessions – once you have some data, I’ll give you a personalized study strategy. 📊";
    }

    String moodLine;
    if (stats.last7DaysMinutes >= 600) {
      moodLine =
          "Your last 7 days look really strong. You’re putting in serious effort – nice work. 💪";
    } else if (stats.last7DaysMinutes >= 300) {
      moodLine =
          "You’re building a solid habit. There’s a clear base to improve from. 👍";
    } else {
      moodLine =
          "Your last week was a bit light. No problem – it’s a good moment to restart with a simple, realistic plan. 🌱";
    }

    String sessionLine;
    if (stats.avgSessionMinutes >= 60) {
      sessionLine =
          "Your average session is quite long. Make sure you take short breaks so you don’t burn out.";
    } else if (stats.avgSessionMinutes >= 30) {
      sessionLine =
          "Your sessions are in a healthy range. You could experiment with one slightly longer ‘deep focus’ block a few times per week.";
    } else {
      sessionLine =
          "Your sessions are short. Try one 30–45 minute deep focus block per day where you silence notifications and focus on a single subject.";
    }

    final weekdayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final bestDayName = weekdayNames[stats.bestWeekdayIndex];

    final bestDayLine = stats.bestWeekdayMinutes > 0
        ? "You seem to be most productive on **$bestDayName**. Try to lock that day as your main study day every week."
        : "Your study days are still very spread out – that’s okay, but choosing 2–3 ‘main’ study days will help you build rhythm.";

    final dayPartLine =
        "You concentrate best in the **${stats.topDayPartLabel.toLowerCase()}**. If possible, schedule your hardest subjects in that time window.";

    String subjectLine;
    if (stats.topSubjectName != null) {
      subjectLine =
          "You spend the most time on **${stats.topSubjectName}**. That’s your ‘focus subject’ – but don’t forget to schedule at least one focused block for your weaker subjects too.";
    } else {
      subjectLine =
          "Your time is spread across subjects pretty evenly. That’s fine, but you can choose 1–2 ‘priority’ subjects for the upcoming week.";
    }

    final dailyTarget = math.max(30, (stats.last7DaysMinutes / 7).round());
    final planLine =
        "For the next 7 days, I recommend a daily target of about **$dailyTarget minutes**. If you consistently hit that, we can slowly move it up.";

    return """
Here’s a quick look at your recent study pattern:

- Total study time so far: **${stats.totalMinutes} minutes**
- Last 7 days: **${stats.last7DaysMinutes} minutes**
- Average session length: **${stats.avgSessionMinutes.round()} minutes**

$moodLine

$sessionLine

$bestDayLine

$dayPartLine

$subjectLine

$planLine

This is a simulated AI coach based on your data inside the app — no real online AI is used here. 🚀
""";
  }
}

/* ───────────── MODEL ZA STATISTIKU ───────────── */

class _CoachStats {
  final int totalMinutes;
  final int totalSessions;
  final double avgSessionMinutes;
  final int todayMinutes;
  final int last7DaysMinutes;

  final String? topSubjectName;
  final Map<String, int> minutesBySubject;

  final int bestWeekdayIndex;
  final int bestWeekdayMinutes;

  final String topDayPartLabel;

  const _CoachStats({
    required this.totalMinutes,
    required this.totalSessions,
    required this.avgSessionMinutes,
    required this.todayMinutes,
    required this.last7DaysMinutes,
    required this.topSubjectName,
    required this.minutesBySubject,
    required this.bestWeekdayIndex,
    required this.bestWeekdayMinutes,
    required this.topDayPartLabel,
  });

  const _CoachStats.empty()
      : totalMinutes = 0,
        totalSessions = 0,
        avgSessionMinutes = 0,
        todayMinutes = 0,
        last7DaysMinutes = 0,
        topSubjectName = null,
        minutesBySubject = const {},
        bestWeekdayIndex = 0,
        bestWeekdayMinutes = 0,
        topDayPartLabel = 'Evening';
}

/* ───────────── UI WIDGETI ───────────── */

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.stats});

  final _CoachStats stats;

  @override
  Widget build(BuildContext context) {
    final hours = (stats.totalMinutes / 60).toStringAsFixed(1);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade600, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI study coach",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You've studied $hours h in total.\nTap below to get a personalized suggestion.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _CoachStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _smallStatCard(
            icon: Icons.access_time,
            label: "Total minutes",
            value: stats.totalMinutes.toString(),
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _smallStatCard(
            icon: Icons.calendar_today_outlined,
            label: "Last 7 days",
            value: "${stats.last7DaysMinutes} min",
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _smallStatCard(
            icon: Icons.timer_outlined,
            label: "Avg session",
            value: "${stats.avgSessionMinutes.round()} min",
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 1 : 2,
      color: isDark ? const Color(0xFF18191D) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestTimesCard extends StatelessWidget {
  const _BestTimesCard({required this.stats});

  final _CoachStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekdayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final bestDayName = weekdayNames[stats.bestWeekdayIndex];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: isDark ? 1 : 2,
      color: isDark ? const Color(0xFF18191D) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "When you study best",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "• Most active day: $bestDayName\n"
              "• Best time of day: ${stats.topDayPartLabel}",
              style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Use this to schedule your hardest subjects where your brain naturally performs better.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceBubble extends StatelessWidget {
  const _AdviceBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18191D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.smart_toy_outlined, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              height: 1.4,
            ),
            ),
          ),
        ],
      ),
    );
  }
}
