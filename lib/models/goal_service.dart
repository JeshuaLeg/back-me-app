import 'package:flutter/material.dart';
import 'goal.dart';
import '../services/achievement_service.dart';

class GoalService extends ChangeNotifier {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal() {
    _initializeSampleData();
  }

  final List<Goal> _goals = [];

  List<Goal> get goals => List.unmodifiable(_goals);
  
  List<Goal> get activeGoals => _goals.where((goal) => goal.status == GoalStatus.active).toList();
  
  List<Goal> get overdueGoals => _goals.where((goal) => goal.isOverdue).toList();
  
  List<Goal> get completedGoals => _goals.where((goal) => goal.status == GoalStatus.completed).toList();

  double get totalStakesAtRisk {
    return activeGoals.fold(0.0, (sum, goal) => sum + goal.stakeAmount);
  }

  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  void updateGoal(Goal updatedGoal) {
    final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      _updateAchievements();
      notifyListeners();
    }
  }

  void deleteGoal(String goalId) {
    _goals.removeWhere((goal) => goal.id == goalId);
    notifyListeners();
  }

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateProgress(String goalId, double progress) {
    final goal = getGoalById(goalId);
    if (goal != null) {
      final updatedGoal = goal.copyWith(progress: progress.clamp(0.0, 1.0));
      if (progress >= 1.0) {
        updateGoal(updatedGoal.copyWith(status: GoalStatus.completed));
      } else {
        updateGoal(updatedGoal);
      }
    }
  }

  void markGoalCompleted(String goalId) {
    final goal = getGoalById(goalId);
    if (goal != null) {
      updateGoal(goal.copyWith(
        status: GoalStatus.completed,
        progress: 1.0,
      ));
    }
  }

  void markGoalFailed(String goalId) {
    final goal = getGoalById(goalId);
    if (goal != null) {
      updateGoal(goal.copyWith(
        status: GoalStatus.failed,
        isStakeReleased: true,
      ));
    }
  }

  void _updateAchievements() {
    final completedGoals = this.completedGoals.length;
    final totalGoals = _goals.length;
    final totalStakes = totalStakesAtRisk;
    
    // Update achievement service with current goal stats
    AchievementService().updateGoalStats(completedGoals, totalGoals, totalStakes);
  }

  void _initializeSampleData() {
    final samplePartner1 = AccountabilityPartner(
      id: 'partner1',
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      phoneNumber: '+1-555-0123',
      canSendReminders: true,
      canReceiveStakes: false,
    );

    final samplePartner2 = AccountabilityPartner(
      id: 'partner2',
      name: 'Mike Chen',
      email: 'mike@example.com',
      canSendReminders: true,
      canReceiveStakes: true,
    );

    final now = DateTime.now();
    
    _goals.addAll([
      Goal(
        id: 'goal1',
        title: 'Run 5K Every Day',
        description: 'Complete a 5K run every morning for 30 days to build endurance and establish a healthy routine.',
        category: GoalCategory.fitness,
        createdAt: now.subtract(const Duration(days: 5)),
        deadline: now.add(const Duration(days: 25)),
        stakeAmount: 100.0,
        accountabilityPartners: [samplePartner1],
        reminderTimes: ['07:00', '19:00'],
        reminderFrequency: 1,
        progress: 0.2,
        milestones: ['Complete first week', 'Complete second week', 'Complete third week', 'Complete final week'],
        milestonesCompleted: [true, false, false, false],
        notes: 'Focus on consistent pace, track progress with running app',
        color: Colors.green,
      ),
      Goal(
        id: 'goal2',
        title: 'Read 2 Books This Month',
        description: 'Read at least 2 non-fiction books to expand knowledge and improve focus.',
        category: GoalCategory.education,
        createdAt: now.subtract(const Duration(days: 10)),
        deadline: now.add(const Duration(days: 20)),
        stakeAmount: 50.0,
        accountabilityPartners: [samplePartner2],
        reminderTimes: ['20:00'],
        reminderFrequency: 3,
        progress: 0.6,
        milestones: ['Finish first book', 'Finish second book'],
        milestonesCompleted: [true, false],
        notes: 'Currently reading "Atomic Habits" and "Deep Work"',
        color: Colors.purple,
      ),
      Goal(
        id: 'goal3',
        title: 'Save \$1000 Emergency Fund',
        description: 'Build an emergency fund by saving \$250 per week for 4 weeks.',
        category: GoalCategory.finance,
        createdAt: now.subtract(const Duration(days: 3)),
        deadline: now.add(const Duration(days: 25)),
        stakeAmount: 200.0,
        accountabilityPartners: [samplePartner1, samplePartner2],
        reminderTimes: ['09:00'],
        reminderFrequency: 7,
        progress: 0.1,
        milestones: ['Save \$250', 'Save \$500', 'Save \$750', 'Save \$1000'],
        milestonesCompleted: [false, false, false, false],
        notes: 'Using automatic transfers to high-yield savings account',
        color: Colors.orange,
      ),
      Goal(
        id: 'goal4',
        title: 'Learn Spanish - 30 Days',
        description: 'Practice Spanish for 30 minutes daily using language learning apps and conversation practice.',
        category: GoalCategory.education,
        createdAt: now.subtract(const Duration(days: 15)),
        deadline: now.add(const Duration(days: 15)),
        stakeAmount: 75.0,
        accountabilityPartners: [samplePartner1],
        reminderTimes: ['12:00', '18:00'],
        reminderFrequency: 1,
        progress: 0.5,
        milestones: ['Complete basics', 'Have first conversation', 'Complete intermediate level'],
        milestonesCompleted: [true, true, false],
        notes: 'Using Duolingo and weekly conversation practice with native speaker',
        color: Colors.red,
      ),
      Goal(
        id: 'goal5',
        title: 'No Social Media for 7 Days',
        description: 'Take a complete break from all social media platforms to improve focus and mental health.',
        category: GoalCategory.habits,
        createdAt: now.subtract(const Duration(days: 8)),
        deadline: now.subtract(const Duration(days: 1)),
        stakeAmount: 25.0,
        accountabilityPartners: [samplePartner2],
        reminderTimes: ['08:00', '16:00'],
        reminderFrequency: 1,
        progress: 1.0,
        status: GoalStatus.completed,
        milestones: ['Complete day 1', 'Complete day 3', 'Complete day 5', 'Complete day 7'],
        milestonesCompleted: [true, true, true, true],
        notes: 'Removed apps from phone, used time for reading and exercise instead',
        color: Colors.blue,
      ),
    ]);
  }
} 