import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/goal.dart';
import '../main.dart';

class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal() {
    _initializeAchievements();
    _initializeRewards();
  }

  final List<Achievement> _achievements = [];
  final List<UserBadge> _userBadges = [];
  final List<Reward> _rewards = [];
  int _totalPoints = 0;
  int _currentLevel = 1;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _goalsCompleted = 0;
  int _totalGoalsCreated = 0;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Achievement> get unlockedAchievements => 
      _achievements.where((achievement) => achievement.isUnlocked).toList();
  List<UserBadge> get userBadges => List.unmodifiable(_userBadges);
  List<Reward> get rewards => List.unmodifiable(_rewards);
  List<Reward> get availableRewards => 
      _rewards.where((reward) => reward.isAvailable && !reward.isUnlocked).toList();
  List<Reward> get unlockedRewards => 
      _rewards.where((reward) => reward.isUnlocked).toList();
  
  int get totalPoints => _totalPoints;
  int get currentLevel => _currentLevel;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get goalsCompleted => _goalsCompleted;
  int get totalGoalsCreated => _totalGoalsCreated;

  String get userTitle => _getUserTitle();
  Color get userTitleColor => _getUserTitleColor();
  UserLevel get currentUserLevel => _getCurrentUserLevel();

  void _initializeAchievements() {
    _achievements.addAll([
      // Goal Completion Achievements
      Achievement(
        id: 'first_goal',
        title: 'First Steps',
        description: 'Complete your first goal',
        icon: Icons.flag_rounded,
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.common,
        points: 50,
        isUnlocked: _goalsCompleted >= 1,
        progress: _goalsCompleted.toDouble(),
        target: 1,
        color: AppTheme.successGreen,
        specialReward: 'Beginner Badge',
      ),
      Achievement(
        id: 'goal_crusher',
        title: 'Goal Crusher',
        description: 'Complete 5 goals',
        icon: Icons.emoji_events_rounded,
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.uncommon,
        points: 200,
        isUnlocked: _goalsCompleted >= 5,
        progress: _goalsCompleted.toDouble(),
        target: 5,
        color: AppTheme.warningAmber,
      ),
      Achievement(
        id: 'achievement_master',
        title: 'Achievement Master',
        description: 'Complete 10 goals',
        icon: Icons.workspace_premium_rounded,
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.rare,
        points: 500,
        isUnlocked: _goalsCompleted >= 10,
        progress: _goalsCompleted.toDouble(),
        target: 10,
        color: AppTheme.accentIndigo,
        specialReward: 'Master Badge + Limited Edition Sticker',
      ),
      
      // Streak Achievements
      Achievement(
        id: 'on_fire',
        title: 'On Fire!',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department_rounded,
        type: AchievementType.streak,
        rarity: AchievementRarity.common,
        points: 100,
        isUnlocked: _longestStreak >= 7,
        progress: _longestStreak.toDouble(),
        target: 7,
        color: AppTheme.errorRose,
      ),
      Achievement(
        id: 'unstoppable',
        title: 'Unstoppable',
        description: 'Maintain a 30-day streak',
        icon: Icons.whatshot_rounded,
        type: AchievementType.streak,
        rarity: AchievementRarity.epic,
        points: 750,
        isUnlocked: _longestStreak >= 30,
        progress: _longestStreak.toDouble(),
        target: 30,
        color: Colors.orange,
        specialReward: 'Streak Champion T-Shirt',
      ),
      
      // Consistency Achievements
      Achievement(
        id: 'consistent_performer',
        title: 'Consistent Performer',
        description: 'Complete goals 3 weeks in a row',
        icon: Icons.trending_up_rounded,
        type: AchievementType.consistency,
        rarity: AchievementRarity.uncommon,
        points: 300,
        isUnlocked: false,
        progress: 0,
        target: 3,
        color: AppTheme.accentIndigo,
      ),
      
      // Financial Achievements
      Achievement(
        id: 'high_roller',
        title: 'High Roller',
        description: 'Have \$500+ in active stakes',
        icon: Icons.attach_money_rounded,
        type: AchievementType.financial,
        rarity: AchievementRarity.rare,
        points: 400,
        isUnlocked: false,
        progress: 0,
        target: 500,
        color: AppTheme.successGreen,
      ),
      
      // Special Achievements
      Achievement(
        id: 'early_adopter',
        title: 'Early Adopter',
        description: 'One of the first 1000 users',
        icon: Icons.star_rounded,
        type: AchievementType.special,
        rarity: AchievementRarity.legendary,
        points: 1000,
        isUnlocked: true,
        progress: 1,
        target: 1,
        color: Colors.purple,
        specialReward: 'Exclusive Early Adopter Hoodie',
      ),
      
      // Social Achievements
      Achievement(
        id: 'team_player',
        title: 'Team Player',
        description: 'Add 3 accountability partners',
        icon: Icons.people_rounded,
        type: AchievementType.social,
        rarity: AchievementRarity.uncommon,
        points: 150,
        isUnlocked: false,
        progress: 0,
        target: 3,
        color: AppTheme.primarySlate,
      ),
    ]);
  }

  void _initializeRewards() {
    _rewards.addAll([
      // Digital Rewards
      Reward(
        id: 'profile_badge',
        title: 'Custom Profile Badge',
        description: 'Show off your achievements with a custom badge',
        icon: Icons.badge_rounded,
        pointsRequired: 100,
        category: 'Digital',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.accentIndigo,
      ),
      Reward(
        id: 'premium_themes',
        title: 'Premium Themes',
        description: 'Unlock exclusive app themes and colors',
        icon: Icons.palette_rounded,
        pointsRequired: 250,
        category: 'Digital',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.successGreen,
      ),
      
      // Physical Rewards
      Reward(
        id: 'sticker_pack',
        title: 'BackMe Sticker Pack',
        description: 'Exclusive stickers shipped to your door',
        icon: Icons.collections_bookmark_rounded,
        pointsRequired: 500,
        category: 'Merch',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.warningAmber,
      ),
      Reward(
        id: 'water_bottle',
        title: 'BackMe Water Bottle',
        description: 'Premium insulated water bottle',
        icon: Icons.sports_bar_rounded,
        pointsRequired: 750,
        category: 'Merch',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.accentIndigo,
      ),
      Reward(
        id: 'tshirt',
        title: 'BackMe T-Shirt',
        description: 'Soft cotton tee with BackMe logo',
        icon: Icons.checkroom_rounded,
        pointsRequired: 1000,
        category: 'Merch',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.errorRose,
      ),
      Reward(
        id: 'hoodie',
        title: 'BackMe Hoodie',
        description: 'Premium zip-up hoodie',
        icon: Icons.dry_cleaning_rounded,
        pointsRequired: 1500,
        category: 'Merch',
        isAvailable: true,
        isUnlocked: false,
        color: AppTheme.primarySlate,
      ),
      
      // Exclusive Rewards
      Reward(
        id: 'founders_edition',
        title: 'Founders Edition Package',
        description: 'Exclusive founders package with signed items',
        icon: Icons.workspace_premium_rounded,
        pointsRequired: 2500,
        category: 'Exclusive',
        isAvailable: true,
        isUnlocked: false,
        color: Colors.purple,
      ),
    ]);
  }

  void updateGoalStats(int completedGoals, int totalGoals, double totalStakes) {
    _goalsCompleted = completedGoals;
    _totalGoalsCreated = totalGoals;
    
    // Update achievement progress
    _updateAchievementProgress('first_goal', completedGoals.toDouble());
    _updateAchievementProgress('goal_crusher', completedGoals.toDouble());
    _updateAchievementProgress('achievement_master', completedGoals.toDouble());
    _updateAchievementProgress('high_roller', totalStakes);
    
    notifyListeners();
  }

  void updateStreak(int currentStreak, int longestStreak) {
    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
    
    _updateAchievementProgress('on_fire', longestStreak.toDouble());
    _updateAchievementProgress('unstoppable', longestStreak.toDouble());
    
    notifyListeners();
  }

  void _updateAchievementProgress(String achievementId, double progress) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index != -1) {
      final achievement = _achievements[index];
      final updatedAchievement = achievement.copyWith(
        progress: progress,
        isUnlocked: progress >= achievement.target,
        unlockedAt: progress >= achievement.target && !achievement.isUnlocked 
            ? DateTime.now() : achievement.unlockedAt,
      );
      
      _achievements[index] = updatedAchievement;
      
      // Award points for new achievements
      if (updatedAchievement.isUnlocked && !achievement.isUnlocked) {
        _awardPoints(updatedAchievement.points);
        _showAchievementNotification(updatedAchievement);
      }
    }
  }

  void _awardPoints(int points) {
    _totalPoints += points;
    _updateLevel();
  }

  void _updateLevel() {
    final levels = [
      100, 250, 500, 1000, 2000, 3500, 5000, 7500, 10000, 15000
    ];
    
    for (int i = 0; i < levels.length; i++) {
      if (_totalPoints >= levels[i]) {
        _currentLevel = i + 2; // Start at level 1
      }
    }
  }

  void _showAchievementNotification(Achievement achievement) {
    // This would show a notification/toast in a real app
    print('🎉 Achievement Unlocked: ${achievement.title}');
  }

  String _getUserTitle() {
    if (_currentLevel >= 10) return 'Legend';
    if (_currentLevel >= 8) return 'Master';
    if (_currentLevel >= 6) return 'Expert';
    if (_currentLevel >= 4) return 'Advanced';
    if (_currentLevel >= 2) return 'Motivated';
    return 'Beginner';
  }

  Color _getUserTitleColor() {
    if (_currentLevel >= 10) return Colors.purple;
    if (_currentLevel >= 8) return Colors.orange;
    if (_currentLevel >= 6) return AppTheme.accentIndigo;
    if (_currentLevel >= 4) return AppTheme.successGreen;
    if (_currentLevel >= 2) return AppTheme.warningAmber;
    return AppTheme.mutedText;
  }

  UserLevel _getCurrentUserLevel() {
    final levels = [
      UserLevel(level: 1, title: 'Beginner', description: 'Just getting started', pointsRequired: 100, currentPoints: _totalPoints, color: AppTheme.mutedText, perks: ['Basic features']),
      UserLevel(level: 2, title: 'Motivated', description: 'Making progress', pointsRequired: 250, currentPoints: _totalPoints, color: AppTheme.warningAmber, perks: ['Progress tracking', 'Basic rewards']),
      UserLevel(level: 3, title: 'Committed', description: 'Staying consistent', pointsRequired: 500, currentPoints: _totalPoints, color: AppTheme.successGreen, perks: ['Custom themes', 'Priority support']),
      UserLevel(level: 4, title: 'Advanced', description: 'Achieving goals regularly', pointsRequired: 1000, currentPoints: _totalPoints, color: AppTheme.accentIndigo, perks: ['Premium features', 'Exclusive content']),
      UserLevel(level: 5, title: 'Expert', description: 'Consistency master', pointsRequired: 2000, currentPoints: _totalPoints, color: Colors.blue, perks: ['Advanced analytics', 'Custom badges']),
      UserLevel(level: 6, title: 'Master', description: 'Goal achievement expert', pointsRequired: 3500, currentPoints: _totalPoints, color: Colors.orange, perks: ['Mentor status', 'Exclusive merch']),
      UserLevel(level: 7, title: 'Legend', description: 'Inspiring others', pointsRequired: 5000, currentPoints: _totalPoints, color: Colors.purple, perks: ['Legend status', 'All rewards', 'Special recognition']),
    ];
    
    for (int i = levels.length - 1; i >= 0; i--) {
      if (_totalPoints >= levels[i].pointsRequired || i == 0) {
        return levels[i];
      }
    }
    return levels[0];
  }

  bool claimReward(String rewardId) {
    final index = _rewards.indexWhere((r) => r.id == rewardId);
    if (index != -1) {
      final reward = _rewards[index];
      if (_totalPoints >= reward.pointsRequired && !reward.isUnlocked) {
        _totalPoints -= reward.pointsRequired;
        _rewards[index] = Reward(
          id: reward.id,
          title: reward.title,
          description: reward.description,
          icon: reward.icon,
          pointsRequired: reward.pointsRequired,
          category: reward.category,
          isAvailable: reward.isAvailable,
          isUnlocked: true,
          color: reward.color,
          imageUrl: reward.imageUrl,
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void initializeWithGoalData(List<Goal> goals) {
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;
    final totalStakes = goals.where((g) => g.status == GoalStatus.active)
        .fold(0.0, (sum, goal) => sum + goal.stakeAmount);
    
    updateGoalStats(completedGoals, goals.length, totalStakes);
    
    // Award points for early adopter
    if (!_achievements.firstWhere((a) => a.id == 'early_adopter').isUnlocked) {
      _awardPoints(1000);
    }
  }
} 