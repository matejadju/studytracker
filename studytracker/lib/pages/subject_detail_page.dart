import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subject.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class SubjectDetailPage extends StatelessWidget {
  SubjectDetailPage({super.key, required this.subject});

  final Subject subject;
  final GoalService _goalService = GoalService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(subject.name),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalBottomSheet(context, uid),
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Add goal'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // HEADER CARD – subject info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 3,
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
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        Icons.school_outlined,
                        color: Colors.blue.shade700,
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
                            style: const TextStyle(
                              fontSize: 18,
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
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
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

          // GOALS LIST
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
                        style: const TextStyle(fontSize: 13),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.flag_outlined,
                              size: 52, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No goals yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the "Add goal" button to create your first goal for this subject.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final newValue = !goal.isCompleted;
                          await _goalService.updateGoalCompletion(
                              goal.id, newValue);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newValue
                                    ? "Goal marked as completed."
                                    : "Goal marked as incomplete.",
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // checkbox
                              Checkbox(
                                value: goal.isCompleted,
                                onChanged: (value) async {
                                  if (value == null) return;
                                  await _goalService.updateGoalCompletion(
                                      goal.id, value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? "Goal marked as completed."
                                            : "Goal marked as incomplete.",
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),

                              // main text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${goal.targetMinutes} min',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: periodLabel == 'Weekly'
                                                ? Colors.blue.shade50
                                                : Colors.deepPurple.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            periodLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: periodLabel == 'Weekly'
                                                  ? Colors.blue.shade700
                                                  : Colors.deepPurple.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateRange,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // delete icon
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 22,
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete goal'),
                                      content: const Text(
                                        'Are you sure you want to delete this goal?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await _goalService.deleteGoal(goal.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Goal deleted.")),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
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

  /// Popup za nevalidan unos (da se vidi iznad tastature).
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
    String selectedPeriod = 'weekly'; // default
    DateTime startDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, -4),
                      color: Colors.black12,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Text(
                      'Add goal for ${subject.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Period type – segmented buttons
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Period type',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
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
                            onSelected: (_) {
                              setState(() => selectedPeriod = 'monthly');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // target minutes
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
                        fillColor: Colors.grey.shade100,
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'From ${startDate.toLocal().toString().split(' ').first} '
                        'to ${endDate.toLocal().toString().split(' ').first}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
