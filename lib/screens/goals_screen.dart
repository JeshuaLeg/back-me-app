import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/goal_service.dart';
import '../widgets/goal_card.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  final GoalService _goalService = GoalService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Overdue'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _navigateToCreateGoal(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsList(_goalService.activeGoals),
          _buildGoalsList(_goalService.completedGoals),
          _buildGoalsList(_goalService.overdueGoals),
          _buildGoalsList(_goalService.goals),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals) {
    if (goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GoalCard(
            goal: goal,
            onTap: () => _navigateToGoalDetail(goal),
            onProgressUpdate: (progress) => _updateGoalProgress(goal.id, progress),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Goals Here',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a goal to get started with accountability!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateGoal(),
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
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
        // Refresh when returning from create goal
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
        // Refresh when returning from goal detail
      });
    });
  }

  void _updateGoalProgress(String goalId, double progress) {
    setState(() {
      _goalService.updateProgress(goalId, progress);
    });
  }
} 