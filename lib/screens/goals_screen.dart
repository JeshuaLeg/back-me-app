import 'package:flutter/material.dart';
import '../models/firebase_goal.dart';
import '../services/firebase_goal_service.dart';
import '../widgets/goal_card.dart';
import '../utils/smooth_transitions.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';
import '../main.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  final FirebaseGoalService _goalService = FirebaseGoalService();
  late TabController _tabController;
  bool _useDebugMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _goalService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            onPressed: () => _toggleDebugMode(),
            icon: Icon(_useDebugMode ? Icons.refresh : Icons.bug_report),
            tooltip: _useDebugMode ? 'Refresh Goals' : 'Debug Mode',
          ),
          IconButton(
            onPressed: () => _navigateToCreateGoal(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primarySlate.withValues(alpha: 0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: _useDebugMode ? _buildDebugView() : _buildStreamView(),
      ),
    );
  }

  Widget _buildStreamView() {
    return StreamBuilder<List<FirebaseGoal>>(
      stream: _goalService.goalsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Stream Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _toggleDebugMode(),
                  child: const Text('Try Debug Mode'),
                ),
              ],
            ),
          );
        }

        final allGoals = snapshot.data ?? [];

        return TabBarView(
          controller: _tabController,
          children: [
            _buildGoalsList(allGoals.where((goal) => goal.status == GoalStatus.active).toList()),
            _buildGoalsList(allGoals.where((goal) => goal.status == GoalStatus.completed).toList()),
            _buildGoalsList(allGoals.where((goal) => goal.isOverdue).toList()),
            _buildGoalsList(allGoals),
          ],
        );
      },
    );
  }

  Widget _buildDebugView() {
    return FutureBuilder<List<FirebaseGoal>>(
      future: _goalService.getGoalsSimple(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Debug Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allGoals = snapshot.data ?? [];

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withValues(alpha: 0.2),
              child: Text(
                'DEBUG MODE: Found ${allGoals.length} goals in database',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGoalsList(allGoals.where((goal) => goal.status == GoalStatus.active).toList()),
                  _buildGoalsList(allGoals.where((goal) => goal.status == GoalStatus.completed).toList()),
                  _buildGoalsList(allGoals.where((goal) => goal.isOverdue).toList()),
                  _buildGoalsList(allGoals),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalsList(List<FirebaseGoal> goals) {
    if (goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Increased bottom spacing for nav clearance
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Increased bottom spacing for nav clearance
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Goals Here',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a goal to get started with accountability!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
      ),
    );
  }

  void _navigateToCreateGoal() {
    context.pushSmooth(const CreateGoalScreen()).then((_) {
      setState(() {
        // Refresh when returning from create goal
      });
    });
  }

  void _navigateToGoalDetail(FirebaseGoal goal) {
    context.pushSmooth(GoalDetailScreen(goal: goal)).then((_) {
      setState(() {
        // Refresh when returning from goal detail
      });
    });
  }

  void _updateGoalProgress(String goalId, double progress) async {
    try {
      await _goalService.updateProgress(goalId, progress);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating progress: $e')),
        );
      }
    }
  }

  void _toggleDebugMode() {
    setState(() {
      _useDebugMode = !_useDebugMode;
    });
  }
} 