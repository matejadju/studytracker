import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subject.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../services/subject_service.dart';

class SubjectDetailPage extends StatelessWidget {
  SubjectDetailPage({
    super.key,
    required this.subject,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final Subject subject;
  final GoalService _goalService = GoalService();

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.colorScheme.surface : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(subject.name),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: onToggleTheme,
          ),
        ],
      ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(useMaterial3: false),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddGoalBottomSheet(context, uid),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Add goal'),
          backgroundColor:
              isDark ? theme.colorScheme.primary : const Color(0xFF6DB8FF),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // --- HEADER CARD ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: isDark ? 1 : 3,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        Icons.school_outlined,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.opis.isEmpty
                                ? 'No description provided.'
                                : subject.opis,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- GRADE CARD ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: isDark ? 1 : 3,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.grade_outlined, size: 28),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        subject.grade == null
                            ? "No grade set"
                            : "Grade: ${subject.grade}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () => _showAddGradeSheet(context),
                      child: Text(subject.grade == null ? "Add" : "Edit"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- GOALS LIST ---
          Expanded(
            child: StreamBuilder<List<Goal>>(
              stream: _goalService.getGoalsForSubject(uid, subject.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Error while loading goals:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final goals = snapshot.data!;
                if (goals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 52,
                            color: theme.iconTheme.color?.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No goals yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 96, left: 16, right: 16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];

                    final periodLabel =
                        goal.periodType == 'monthly' ? 'Monthly' : 'Weekly';

                    final dateRange =
                        'From ${goal.startDate.toLocal().toString().split(' ').first} '
                        'to ${goal.endDate.toLocal().toString().split(' ').first}';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isDark ? 1 : 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Checkbox(
                              value: goal.isCompleted,
                              onChanged: (value) async {
                                if (value == null) return;
                                await _goalService.updateGoalCompletion(
                                    goal.id, value);
                              },
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${goal.targetMinutes} min',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (periodLabel == 'Weekly'
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .colorScheme.secondary)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          periodLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: periodLabel == 'Weekly'
                                                ? theme.colorScheme.primary
                                                : theme
                                                    .colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateRange,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme.textTheme.bodySmall
                                                ?.color
                                                ?.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- ADD GRADE BOTTOMSHEET -----------------

  void _showAddGradeSheet(BuildContext context) {
    int selected = subject.grade ?? 6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Text(
                    "Set grade for ${subject.name}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: selected,
                    decoration: const InputDecoration(
                      labelText: "Grade",
                      border: OutlineInputBorder(),
                    ),
                    items: [6, 7, 8, 9, 10].map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text("$g"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selected = value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await SubjectService()
                            .updateGrade(subject.id, selected);

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Grade updated")),
                        );
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  // -------- bottom sheet za dodavanje goal-a (dark friendly) --------

  Future<void> _showValidationDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Invalid input'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalBottomSheet(BuildContext context, String uid) {
    final minutesController = TextEditingController();
    String selectedPeriod = 'weekly';
    DateTime startDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        DateTime computeEndDate(String period) {
          if (period == 'monthly') {
            return startDate.add(const Duration(days: 30));
          }
          return startDate.add(const Duration(days: 7));
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final endDate = computeEndDate(selectedPeriod);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surface
                      : theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                      color: Colors.black.withOpacity(0.25),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Text(
                      'Add goal for ${subject.name}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Period type',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Weekly'),
                            selected: selectedPeriod == 'weekly',
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.15),
                            onSelected: (_) {
                              setState(() => selectedPeriod = 'weekly');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Monthly'),
                            selected: selectedPeriod == 'monthly',
                            selectedColor:
                                theme.colorScheme.secondary.withOpacity(0.15),
                            onSelected: (_) {
                              setState(() => selectedPeriod = 'monthly');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target minutes (e.g. 300)',
                        prefixIcon: const Icon(Icons.timer_outlined),
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
                            : Colors.grey.shade100,
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'From ${startDate.toLocal().toString().split(' ').first} '
                        'to ${endDate.toLocal().toString().split(' ').first}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final minutes =
                              int.tryParse(minutesController.text.trim());

                          if (minutes == null || minutes <= 0) {
                            await _showValidationDialog(
                              context,
                              'Target minutes is required and must be greater than 0.',
                            );
                            return;
                          }

                          if (minutes < 30) {
                            await _showValidationDialog(
                              context,
                              'Goal must be at least 30 minutes (e.g. 300 for weekly).',
                            );
                            return;
                          }

                          final goal = Goal(
                            id: '',
                            subjectId: subject.id,
                            userId: uid,
                            periodType: selectedPeriod,
                            targetMinutes: minutes,
                            startDate: startDate,
                            endDate: computeEndDate(selectedPeriod),
                            isCompleted: false,
                          );

                          await _goalService.addGoal(goal);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Goal added successfully!"),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save goal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
