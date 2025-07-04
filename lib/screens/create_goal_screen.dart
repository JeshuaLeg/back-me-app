import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/goal_service.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stakeAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  GoalCategory _selectedCategory = GoalCategory.personal;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  List<String> _milestones = [];
  List<String> _reminderTimes = ['09:00'];
  int _reminderFrequency = 1;
  final _milestoneController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stakeAmountController.dispose();
    _notesController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Goal'),
        actions: [
          TextButton(
            onPressed: _saveGoal,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildCategorySection(),
            const SizedBox(height: 24),
            _buildDeadlineSection(),
            const SizedBox(height: 24),
            _buildStakeSection(),
            const SizedBox(height: 24),
            _buildMilestonesSection(),
            const SizedBox(height: 24),
            _buildRemindersSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title *',
                hintText: 'e.g., Run 5K every day for 30 days',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your goal in detail...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GoalCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: isSelected ? Colors.white : null,
                      ),
                      const SizedBox(width: 4),
                      Text(_getCategoryDisplayName(category)),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deadline',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text('Due Date'),
              subtitle: Text('${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDeadline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Stake',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Put money on the line to increase accountability. If you don\'t reach your goal, this amount will be forfeited.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stakeAmountController,
              decoration: const InputDecoration(
                labelText: 'Stake Amount (\$)',
                hintText: '0',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Research shows financial stakes increase goal completion rates by 60%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Break your goal into smaller, achievable milestones.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:                   TextFormField(
                    controller: _milestoneController,
                    decoration: const InputDecoration(
                      labelText: 'Add Milestone',
                      hintText: 'e.g., Complete first week',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addMilestone(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMilestone,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_milestones.isNotEmpty) ...[
              ...List.generate(_milestones.length, (index) {
                return ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(_milestones[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeMilestone(index),
                  ),
                );
              }),
            ] else
              Text(
                'No milestones added yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Reminder Times'),
              subtitle: Text(_reminderTimes.join(', ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectReminderTimes,
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Frequency'),
              subtitle: Text('Every $_reminderFrequency day${_reminderFrequency != 1 ? 's' : ''}'),
              trailing: DropdownButton<int>(
                value: _reminderFrequency,
                items: List.generate(7, (index) => index + 1)
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text('$day day${day != 1 ? 's' : ''}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _reminderFrequency = value ?? 1;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any additional details, strategies, or motivation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveGoal,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Create Goal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _selectReminderTimes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Times'),
        content: const Text('Reminder time management feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addMilestone() {
    if (_milestoneController.text.isNotEmpty) {
      setState(() {
        _milestones.add(_milestoneController.text);
        _milestoneController.clear();
      });
    }
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        deadline: _selectedDeadline,
        stakeAmount: double.tryParse(_stakeAmountController.text) ?? 0.0,
        reminderTimes: _reminderTimes,
        reminderFrequency: _reminderFrequency,
        milestones: _milestones,
        milestonesCompleted: List.filled(_milestones.length, false),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      GoalService().addGoal(goal);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    }
  }

  IconData _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.health:
        return Icons.health_and_safety;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.relationships:
        return Icons.favorite;
      case GoalCategory.habits:
        return Icons.repeat;
      case GoalCategory.other:
        return Icons.category;
    }
  }

  String _getCategoryDisplayName(GoalCategory category) {
    switch (category) {
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.education:
        return 'Education';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.habits:
        return 'Habits';
      case GoalCategory.other:
        return 'Other';
    }
  }
} 