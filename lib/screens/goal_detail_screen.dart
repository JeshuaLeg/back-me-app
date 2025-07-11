import 'package:flutter/material.dart';
import '../models/firebase_goal.dart';
import '../services/firebase_goal_service.dart';
import '../widgets/completion_dialog.dart';
import '../utils/date_formatter.dart';

class GoalDetailScreen extends StatefulWidget {
  final FirebaseGoal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final FirebaseGoalService _goalService = FirebaseGoalService();
  late FirebaseGoal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _goalService.initialize();
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
              // Complete option (only for active goals)
              if (_goal.status == GoalStatus.active)
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
              
              // Pause/Resume option based on current status
              if (_goal.status == GoalStatus.active)
                PopupMenuItem(
                  value: 'pause',
                  child: const Row(
                    children: [
                      Icon(Icons.pause_circle, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Pause Goal'),
                    ],
                  ),
                )
              else if (_goal.status == GoalStatus.paused)
                PopupMenuItem(
                  value: 'resume',
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Resume Goal'),
                    ],
                  ),
                ),
              
              // Delete option (always available except for completed goals)
              if (_goal.status != GoalStatus.completed)
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
                    color: _goal.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _goal.categoryIcon,
                    color: _goal.categoryColor,
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
                        _goal.category.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _goal.categoryColor,
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
                      color: Colors.orange.withValues(alpha: 0.1),
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
                  '${(_goal.progressPercentage * 100).toStringAsFixed(0)}% Complete',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _goal.endDate != null 
                    ? '${_goal.daysRemaining} days left'
                    : 'No deadline set',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _goal.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _goal.progressPercentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(_goal.categoryColor),
            ),
            
            // Auto-completion indicator
            if (_goal.shouldAutoComplete)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Goal completed! Ready to mark as complete with optional photo and note.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _markComplete(),
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStatCard(
                    'Current',
                    '${_goal.currentProgress.toStringAsFixed(1)} ${_goal.unit}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressStatCard(
                    'Target',
                    '${_goal.targetValue.toStringAsFixed(1)} ${_goal.unit}',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Paused goal indicator
            if (_goal.status == GoalStatus.paused)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Goal is paused. Resume to continue tracking progress.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goal.status == GoalStatus.active 
                        ? () => _showProgressUpdateDialog()
                        : null,
                    icon: const Icon(Icons.add),
                    label: Text(
                      _goal.status == GoalStatus.paused 
                          ? 'Resume to Update Progress'
                          : 'Update Progress'
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
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
            _buildDetailRow('Status', _goal.status.name.toUpperCase()),
            _buildDetailRow('Category', _goal.category.name.toUpperCase()),
            _buildDetailRow('Created', _formatDate(_goal.createdAt)),
            if (_goal.endDate != null)
              _buildDetailRow('Deadline', _formatDate(_goal.endDate!)),
            if (_goal.stakeAmount > 0)
              _buildDetailRow('Stakes', '\$${_goal.stakeAmount.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    if (_goal.milestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_goal.milestones.isNotEmpty)
                  Text(
                    '${_goal.completedMilestonesCount}/${_goal.milestones.length} completed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_goal.milestones.length, (index) {
              final milestone = _goal.milestones[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: milestone.isCompleted 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: milestone.isCompleted 
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      milestone.isCompleted 
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: milestone.isCompleted 
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: milestone.isCompleted 
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: milestone.isCompleted 
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                                  : null,
                            ),
                          ),
                          if (milestone.isCompleted && milestone.completedAt != null)
                            Text(
                              'Completed on ${_formatDate(milestone.completedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          if (milestone.isCompleted && milestone.completionNote != null)
                            Text(
                              milestone.completionNote!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!milestone.isCompleted && _goal.status == GoalStatus.active)
                      TextButton(
                        onPressed: () => _completeMilestone(milestone),
                        child: const Text('Complete'),
                      ),
                    if (milestone.isCompleted && milestone.completionPhotoUrl != null)
                      IconButton(
                        onPressed: () => _showCompletionPhoto(milestone.completionPhotoUrl!),
                        icon: const Icon(Icons.photo),
                        tooltip: 'View completion photo',
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: const Text('Edit functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProgressUpdateDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${_goal.currentProgress.toStringAsFixed(1)} ${_goal.unit}'),
            Text('Target: ${_goal.targetValue.toStringAsFixed(1)} ${_goal.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Progress (${_goal.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _updateProgress(controller.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(String value) async {
    final progress = double.tryParse(value);
    if (progress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid progress value')),
      );
      return;
    }

    try {
      await _goalService.updateGoal(_goal.id, currentProgress: progress);
      setState(() {
        _goal = _goal.copyWith(currentProgress: progress);
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating progress: $e')),
      );
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'complete':
        await _markComplete();
        break;
      case 'pause':
        await _pauseGoal();
        break;
      case 'resume':
        await _resumeGoal();
        break;
      case 'delete':
        await _deleteGoal();
        break;
    }
  }

  Future<void> _markComplete() async {
    // Use the completion dialog instead of simple completion
    showCompletionDialog(
      context,
      goalId: _goal.id,
      title: _goal.title,
      onCompleted: () async {
        // Refresh the goal data
        final updatedGoal = await _goalService.getGoal(_goal.id);
        if (updatedGoal != null) {
          setState(() {
            _goal = updatedGoal;
          });
        }
      },
    );
  }

  Future<void> _completeMilestone(Milestone milestone) async {
    showCompletionDialog(
      context,
      goalId: _goal.id,
      milestoneId: milestone.id,
      title: milestone.title,
      onCompleted: () async {
        // Refresh the goal data
        final updatedGoal = await _goalService.getGoal(_goal.id);
        if (updatedGoal != null) {
          setState(() {
            _goal = updatedGoal;
          });
        }
      },
    );
  }

  void _showCompletionPhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Completion Photo'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Failed to load photo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pauseGoal() async {
    try {
      await _goalService.updateGoal(_goal.id, status: GoalStatus.paused);
      setState(() {
        _goal = _goal.copyWith(status: GoalStatus.paused);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal paused')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing goal: $e')),
      );
    }
  }

  Future<void> _resumeGoal() async {
    try {
      await _goalService.updateGoal(_goal.id, status: GoalStatus.active);
      setState(() {
        _goal = _goal.copyWith(status: GoalStatus.active);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal resumed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resuming goal: $e')),
      );
    }
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _goalService.deleteGoal(_goal.id);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting goal: $e')),
        );
      }
    }
  }
} 