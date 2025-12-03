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
      ),
      body: StreamBuilder<List<Goal>>(
        stream: _goalService.getGoalsForSubject(uid, subject.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
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
                children: const [
                  Icon(Icons.flag_outlined, size: 52, color: Colors.grey),
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
                    'Tap "Add goal" to create your first goal.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: goals.length,
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemBuilder: (context, index) {
              final goal = goals[index];

              final periodLabel =
                  goal.periodType == 'monthly' ? 'Monthly' : 'Weekly';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  leading: Checkbox(
                    value: goal.isCompleted,
                    onChanged: (value) async {
                      if (value != null) {
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
                      }
                    },
                  ),
                  title: Text(
                    '$periodLabel – ${goal.targetMinutes} min',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'From ${goal.startDate.toLocal().toString().split(' ').first} '
                    'to ${goal.endDate.toLocal().toString().split(' ').first}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await _goalService.deleteGoal(goal.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Goal deleted.")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalBottomSheet(context, uid),
        icon: const Icon(Icons.flag),
        label: const Text('Add goal'),
      ),
    );
  }

  /// Popup za nevalidan unos (da se vidi iznad tastature).
  Future<void> _showValidationDialog(
      BuildContext context, String message) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
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
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add goal for ${subject.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // period type
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration:
                        const InputDecoration(labelText: 'Period type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedPeriod = value;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // target minutes
                  TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target minutes (e.g. 300)',
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'From ${startDate.toLocal().toString().split(' ').first} '
                    'to ${endDate.toLocal().toString().split(' ').first}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                      child: const Text('Save goal'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
