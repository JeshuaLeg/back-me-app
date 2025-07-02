import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/goal_service.dart';
import '../widgets/goal_card.dart';
import '../widgets/stats_card.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GoalService _goalService = GoalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Back Me',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Stay accountable, reach your goals',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildActiveGoalsSection(),
                    const SizedBox(height: 24),
                    _buildOverdueGoalsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final activeGoals = _goalService.activeGoals;
    final overdueGoals = _goalService.overdueGoals;
    final completedGoals = _goalService.completedGoals;
    final totalStakes = _goalService.totalStakesAtRisk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Active Goals',
                value: activeGoals.length.toString(),
                icon: Icons.track_changes,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Completed',
                value: completedGoals.length.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Stakes at Risk',
                value: '\$${totalStakes.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Overdue',
                value: overdueGoals.length.toString(),
                icon: Icons.warning,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateGoal(),
                icon: const Icon(Icons.add),
                label: const Text('New Goal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRemindersDialog(),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Reminders'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveGoalsSection() {
    final activeGoals = _goalService.activeGoals;

    if (activeGoals.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Goals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to goals tab
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeGoals.length > 3 ? 3 : activeGoals.length,
          itemBuilder: (context, index) {
            final goal = activeGoals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GoalCard(
                goal: goal,
                onTap: () => _navigateToGoalDetail(goal),
                onProgressUpdate: (progress) => _updateGoalProgress(goal.id, progress),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverdueGoalsSection() {
    final overdueGoals = _goalService.overdueGoals;

    if (overdueGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overdue Goals',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overdueGoals.length,
          itemBuilder: (context, index) {
            final goal = overdueGoals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GoalCard(
                goal: goal,
                onTap: () => _navigateToGoalDetail(goal),
                onProgressUpdate: (progress) => _updateGoalProgress(goal.id, progress),
                showOverdueBadge: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first accountability goal to get started!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateGoal(),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Goal'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateGoal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateGoalScreen(),
      ),
    ).then((_) {
      setState(() {
        // Refresh the dashboard when returning from create goal
      });
    });
  }

  void _navigateToGoalDetail(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goal: goal),
      ),
    ).then((_) {
      setState(() {
        // Refresh the dashboard when returning from goal detail
      });
    });
  }

  void _updateGoalProgress(String goalId, double progress) {
    setState(() {
      _goalService.updateProgress(goalId, progress);
    });
  }

  void _showRemindersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upcoming Reminders'),
        content: const Text('This feature will show upcoming accountability reminders and allow you to manage notification settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 