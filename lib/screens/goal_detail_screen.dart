import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/goal_service.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalService _goalService = GoalService();
  late Goal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.title),
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'complete',
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark Complete'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'fail',
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Mark Failed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Goal'),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(value),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildGoalHeader(),
          const SizedBox(height: 24),
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
          const SizedBox(height: 24),
          _buildAccountabilitySection(),
          const SizedBox(height: 24),
          _buildMilestonesSection(),
        ],
      ),
    );
  }

  Widget _buildGoalHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _goal.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _goal.categoryIcon,
                    color: _goal.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _goal.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _goal.categoryDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _goal.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_goal.stakeAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '\$${_goal.stakeAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'at stake',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _goal.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_goal.progress * 100).toStringAsFixed(0)}% Complete',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_goal.daysRemaining} days left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _goal.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _goal.progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(_goal.statusColor),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _goal.progress,
              onChanged: (value) => _updateProgress(value),
              activeColor: _goal.statusColor,
              divisions: 10,
              label: '${(_goal.progress * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Created', _formatDate(_goal.createdAt)),
            _buildDetailRow(Icons.event, 'Deadline', _formatDate(_goal.deadline)),
            _buildDetailRow(Icons.notifications, 'Reminders', '${_goal.reminderTimes.length} set'),
            if (_goal.notes != null)
              _buildDetailRow(Icons.note, 'Notes', _goal.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accountability Partners',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_goal.accountabilityPartners.isEmpty)
              const Text('No accountability partners added yet.')
            else
              ..._goal.accountabilityPartners.map((partner) => ListTile(
                leading: CircleAvatar(
                  child: Text(partner.name[0].toUpperCase()),
                ),
                title: Text(partner.name),
                subtitle: Text(partner.email),
                trailing: Icon(
                  partner.canSendReminders ? Icons.notifications_active : Icons.notifications_off,
                  color: partner.canSendReminders ? Colors.green : Colors.grey,
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection() {
    if (_goal.milestones.isEmpty) return const SizedBox.shrink();
    
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
            const SizedBox(height: 16),
            ...List.generate(_goal.milestones.length, (index) {
              final milestone = _goal.milestones[index];
              final isCompleted = index < _goal.milestonesCompleted.length && _goal.milestonesCompleted[index];
              
              return ListTile(
                leading: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                title: Text(
                  milestone,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                onTap: () => _toggleMilestone(index),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _updateProgress(double progress) {
    setState(() {
      _goal = _goal.copyWith(progress: progress);
      _goalService.updateProgress(_goal.id, progress);
    });
  }

  void _toggleMilestone(int index) {
    final completed = List<bool>.from(_goal.milestonesCompleted);
    if (index >= completed.length) {
      completed.addAll(List.filled(index - completed.length + 1, false));
    }
    completed[index] = !completed[index];
    
    setState(() {
      _goal = _goal.copyWith(milestonesCompleted: completed);
      _goalService.updateGoal(_goal);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'complete':
        _goalService.markGoalCompleted(_goal.id);
        Navigator.of(context).pop();
        break;
      case 'fail':
        _goalService.markGoalFailed(_goal.id);
        Navigator.of(context).pop();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showEditDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit goal feature coming soon!')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _goalService.deleteGoal(_goal.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close goal detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 