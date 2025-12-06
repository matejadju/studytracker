import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/study_session.dart';
import '../models/subject.dart';
import '../services/study_session_service.dart';
import '../services/subject_service.dart';

enum StatsPeriod { weekly, monthly }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StudySessionService _sessionService = StudySessionService();
  final SubjectService _subjectService = SubjectService();

  List<Subject> _subjects = [];
  String? _selectedSubjectId;
  bool _loadingSubjects = true;

  StatsPeriod _selectedPeriod = StatsPeriod.weekly;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingSubjects = false);
      return;
    }

    final list = await _subjectService.getSubjectsOnce(user.uid);

    if (!mounted) return;
    setState(() {
      _subjects = list;
      if (_subjects.isNotEmpty) {
        _selectedSubjectId = _subjects.first.id;
      }
      _loadingSubjects = false;
    });
  }

  String _formatMinutes(int m) {
    final h = m ~/ 60;
    final rest = m % 60;
    if (h > 0) {
      return '${h}h ${rest}m';
    } else {
      return '${rest}m';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in.'));
    }
    final uid = user.uid;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loadingSubjects) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_subjects.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No subjects yet. Add a subject first.'),
        ),
      );
    }

    if (_selectedSubjectId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Select a subject.'),
        ),
      );
    }

    final selectedSubject = _subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => _subjects.first,
    );

    return Scaffold(
      backgroundColor:
          isDark ? theme.colorScheme.surface : Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),

          // -----------------------------------------------
          //    ✔ CELA STRANICA JE SAD SCROLLABLE (LISTVIEW)
          // -----------------------------------------------
          child: ListView(
            children: [
              // HEADER
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Study insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Check how much you studied for each subject.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------
              // GLOBAL YEAR FILTER + BAR CHART
              // -------------------------------------------------------
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progress by year",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // YEAR DROPDOWN
                    DropdownButtonFormField<int?>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: "Select year",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All years"),
                        ),
                        ...[1, 2, 3, 4, 5].map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text("Year $y"),
                          ),
                        )
                      ],
                      onChanged: (value) {
                        setState(() => _selectedYear = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // BAR CHART BUILDER
                    FutureBuilder<List<StudySession>>(
                      future: _sessionService.getAllSessions(uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final allSessions = snapshot.data!;

                        // FILTER BY YEAR
                        final filtered = _selectedYear == null
                            ? allSessions
                            : allSessions.where((s) {
                                final subject = _subjects.firstWhere(
                                  (sub) => sub.id == s.subjectId,
                                  orElse: () => Subject(
                                    id: "",
                                    name: "",
                                    opis: "",
                                    userId: "",
                                    year: 1,
                                  ),
                                );
                                return subject.year == _selectedYear;
                              }).toList();

                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("No study data for selected year."),
                          );
                        }

                        // GROUP BY MONTH
                        Map<int, int> monthlyMinutes = {
                          for (int i = 1; i <= 12; i++) i: 0
                        };

                        for (final s in filtered) {
                          monthlyMinutes[s.startTime.month] =
                              monthlyMinutes[s.startTime.month]! +
                                  s.durationMinutes;
                        }

                        // BAR CHART
                        return SizedBox(
                          height: 240,
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: theme.textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 26,
                                    getTitlesWidget: (value, meta) {
                                      const months = [
                                        "",
                                        "Jan",
                                        "Feb",
                                        "Mar",
                                        "Apr",
                                        "May",
                                        "Jun",
                                        "Jul",
                                        "Aug",
                                        "Sep",
                                        "Oct",
                                        "Nov",
                                        "Dec",
                                      ];
                                      if (value < 1 || value > 12) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          months[value.toInt()],
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups:
                                  monthlyMinutes.entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.toDouble(),
                                      width: 18,
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SUBJECT DROPDOWN + WEEKLY/MONTHLY TOGGLE
              Row(
                children: [
                  Expanded(
                    child: _SectionCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Subject',
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: _subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSubjectId = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PeriodToggle(
                    period: _selectedPeriod,
                    onChanged: (p) =>
                        setState(() => _selectedPeriod = p),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------
              //  STREAMBUILDER — počinje ovde (KRAJ DEO 1)
              // -------------------------------------------------------

              StreamBuilder<List<StudySession>>(
                stream: _sessionService.getSessionsForSubject(
                  _selectedSubjectId!,
                  uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading sessions: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allSessions = snapshot.data!;
                  if (allSessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No sessions yet for "${selectedSubject.name}".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final from = _selectedPeriod == StatsPeriod.weekly
                      ? now.subtract(const Duration(days: 7))
                      : now.subtract(const Duration(days: 30));

                  final sessions = allSessions
                      .where((s) => s.endTime.isAfter(from))
                      .toList();

                  if (sessions.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedPeriod == StatsPeriod.weekly
                            ? 'No sessions in the last 7 days.'
                            : 'No sessions in the last 30 days.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final totalMinutes =
                      sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                  final avgMinutes =
                      (totalMinutes / sessions.length).round().clamp(1, 100000);
                  final longest = sessions.reduce(
                    (a, b) =>
                        a.durationMinutes >= b.durationMinutes ? a : b,
                  );

                  final List<int> minutesPerWeekday =
                      List<int>.filled(7, 0, growable: false);
                  for (final s in sessions) {
                    final index = s.startTime.weekday - 1;
                    minutesPerWeekday[index] += s.durationMinutes;
                  }

                  const weekdayLabels = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];

                  final totalWeekdayMinutes =
                      minutesPerWeekday.fold<int>(0, (a, b) => a + b);

                  final List<Color> pieColors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.teal,
                    Colors.brown,
                  ];

                  return Column(
                    children: [
                      // SUMMARY CARD
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics for ${selectedSubject.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPeriod == StatsPeriod.weekly
                                  ? 'Last 7 days'
                                  : 'Last 30 days',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label: 'Total time',
                                  value: _formatMinutes(totalMinutes),
                                ),
                                _SummaryItem(
                                  label: 'Sessions',
                                  value: '${sessions.length}',
                                ),
                                _SummaryItem(
                                  label: 'Avg per session',
                                  value: _formatMinutes(avgMinutes),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Longest session: ${_formatMinutes(longest.durationMinutes)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // BAR CHART — WEEKDAY DISTRIBUTION
                      _SectionCard(
                        child: SizedBox(
                          height: 240,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPeriod == StatsPeriod.weekly
                                    ? 'Weekly overview'
                                    : 'Monthly overview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Minutes per weekday',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      checkToShowHorizontalLine: (value) =>
                                          value % 10 == 0,
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 24,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 || index > 6) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                weekdayLabels[index],
                                                style: theme
                                                    .textTheme.bodySmall,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: List.generate(7, (index) {
                                      final minutes =
                                          minutesPerWeekday[index];
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: minutes.toDouble(),
                                            width: 14,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // PIE CHART — WEEKDAY PERCENTAGES
                      if (totalWeekdayMinutes > 0)
                        _SectionCard(
                          child: SizedBox(
                            height: 240,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPeriod == StatsPeriod.weekly
                                      ? 'Distribution by weekday'
                                      : 'Monthly distribution',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share of total study time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 32,
                                      sections: List.generate(7, (index) {
                                        final minutes =
                                            minutesPerWeekday[index];
                                        if (minutes == 0) {
                                          return PieChartSectionData(
                                            value: 0,
                                            color: Colors.transparent,
                                          );
                                        }
                                        final percentage = (minutes /
                                                totalWeekdayMinutes) *
                                            100;
                                        return PieChartSectionData(
                                          value: minutes.toDouble(),
                                          color: pieColors[index],
                                          title:
                                              '${weekdayLabels[index]} ${percentage.toStringAsFixed(0)}%',
                                          radius: 62,
                                          titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // SESSION HISTORY
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session history',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: sessions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final s = sessions[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading:
                                      const Icon(Icons.timer_outlined),
                                  title: Text(
                                    '${s.durationMinutes} minutes',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_formatDateTime(s.startTime)} → ${_formatDateTime(s.endTime)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// HELPERS (CARDS, SUMMARY ITEMS, TOGGLES) — OSTAVIO SAM ISTO
// -------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? theme.colorScheme.surfaceVariant : Colors.white,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.period,
    required this.onChanged,
  });

  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeekly = period == StatsPeriod.weekly;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Row(
        children: [
          _PeriodChip(
            text: 'Weekly',
            selected: isWeekly,
            onTap: () => onChanged(StatsPeriod.weekly),
          ),
          _PeriodChip(
            text: 'Monthly',
            selected: !isWeekly,
            onTap: () => onChanged(StatsPeriod.monthly),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
