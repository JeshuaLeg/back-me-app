import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/firebase_goal.dart';
import '../models/firebase_partner.dart';
import '../main.dart';
import 'firebase_achievement_service.dart';
import 'firebase_goal_service.dart';
import 'firebase_partner_service.dart';

class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal() {
    _initializeFirebaseService();
  }

  final FirebaseAchievementService _firebaseService = FirebaseAchievementService();
  final FirebaseGoalService _goalService = FirebaseGoalService();
  final FirebasePartnerService _partnerService = FirebasePartnerService();

  List<Achievement> _achievements = [];
  final List<UserBadge> _userBadges = [];
  final List<Reward> _rewards = [];
  int _totalPoints = 0;
  int _currentLevel = 1;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _goalsCompleted = 0;
  int _totalGoalsCreated = 0;
  bool _isInitialized = false;

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
  bool get isInitialized => _isInitialized;

  // Initialize Firebase service and load achievements
  Future<void> _initializeFirebaseService() async {
    try {
      // Initialize Firebase achievement service
      await _firebaseService.initialize();
      
      // Seed achievements if this is the first time
      await _firebaseService.seedDefaultAchievements();
      
      // Load achievements and user progress
      await _loadAchievementsFromFirebase();
      
      // Initialize rewards (still local for now)
      _initializeRewards();
      
      // Listen to achievement updates
      _firebaseService.achievementsStream.listen((_) async {
        await _loadAchievementsFromFirebase();
      });
      
      _firebaseService.progressStream.listen((_) async {
        await _loadAchievementsFromFirebase();
      });
      
      _isInitialized = true;
      notifyListeners();
      print('Achievement service initialized successfully');
    } catch (e) {
      print('Error initializing achievement service: $e');
      // Fallback to hardcoded achievements if Firebase fails
      _initializeFallbackAchievements();
      _initializeRewards();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Load achievements from Firebase
  Future<void> _loadAchievementsFromFirebase() async {
    try {
      _achievements = await _firebaseService.getUserAchievements();
      _calculateTotalPoints();
      _updateLevel();
      notifyListeners();
    } catch (e) {
      print('Error loading achievements from Firebase: $e');
    }
  }

  // Calculate total points from unlocked achievements
  void _calculateTotalPoints() {
    _totalPoints = unlockedAchievements.fold(0, (sum, achievement) => sum + achievement.points);
  }

  // Fallback achievements if Firebase is unavailable
  void _initializeFallbackAchievements() {
    _achievements = [
      // Basic fallback achievement
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
    ];
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

  // Update goal statistics and sync with Firebase
  Future<void> updateGoalStats(int completedGoals, int totalGoals, double totalStakes) async {
    _goalsCompleted = completedGoals;
    _totalGoalsCreated = totalGoals;
    
    // Get partner count
    final activePartners = _partnerService.activePartnerships.length;
    
    // Update Firebase achievements
    try {
      await _firebaseService.updateUserStats(
        completedGoals: completedGoals,
        totalGoals: totalGoals,
        currentStreak: _currentStreak,
        longestStreak: _longestStreak,
        totalStakes: totalStakes,
        activePartners: activePartners,
      );
    } catch (e) {
      print('Error updating goal stats in Firebase: $e');
      // Fallback to local updates
      _updateLocalAchievementProgress('first_goal', completedGoals.toDouble());
      _updateLocalAchievementProgress('goal_crusher', completedGoals.toDouble());
      _updateLocalAchievementProgress('achievement_master', completedGoals.toDouble());
      _updateLocalAchievementProgress('high_roller', totalStakes);
    }
    
    notifyListeners();
  }

  // Update streak and sync with Firebase
  Future<void> updateStreak(int currentStreak, int longestStreak) async {
    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
    
    // Update Firebase achievements
    try {
      await _firebaseService.updateUserStats(
        completedGoals: _goalsCompleted,
        totalGoals: _totalGoalsCreated,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalStakes: _goalService.totalStakesAtRisk,
        activePartners: _partnerService.activePartnerships.length,
      );
    } catch (e) {
      print('Error updating streak in Firebase: $e');
      // Fallback to local updates
      _updateLocalAchievementProgress('on_fire', longestStreak.toDouble());
      _updateLocalAchievementProgress('unstoppable', longestStreak.toDouble());
    }
    
    notifyListeners();
  }

  // Fallback method for local achievement updates
  void _updateLocalAchievementProgress(String achievementId, double progress) {
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

  // Initialize with goal data and sync with Firebase
  Future<void> initializeWithGoalData(List<FirebaseGoal> goals) async {
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;
    final totalStakes = goals.where((g) => g.status == GoalStatus.active)
        .fold(0.0, (sum, goal) => sum + goal.stakeAmount);
    
    await updateGoalStats(completedGoals, goals.length, totalStakes);
    
    // Award early adopter achievement
    try {
      await _firebaseService.updateUserProgress(
        achievementId: 'early_adopter',
        progress: 1.0,
        forceUnlock: true,
      );
    } catch (e) {
      print('Error unlocking early adopter achievement: $e');
    }
  }

  // Refresh achievements from Firebase
  Future<void> refreshAchievements() async {
    if (_isInitialized) {
      await _loadAchievementsFromFirebase();
    }
  }

  // Force sync all data with Firebase
  Future<void> syncWithFirebase() async {
    try {
      final goals = _goalService.goals;
      final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;
      final totalStakes = goals.where((g) => g.status == GoalStatus.active)
          .fold(0.0, (sum, goal) => sum + goal.stakeAmount);
      final activePartners = _partnerService.activePartnerships.length;
      
      await _firebaseService.updateUserStats(
        completedGoals: completedGoals,
        totalGoals: goals.length,
        currentStreak: _currentStreak,
        longestStreak: _longestStreak,
        totalStakes: totalStakes,
        activePartners: activePartners,
      );
      
      await _loadAchievementsFromFirebase();
    } catch (e) {
      print('Error syncing with Firebase: $e');
    }
  }

  // Admin functions (expose Firebase methods)
  Future<void> seedAchievements() async {
    await _firebaseService.seedDefaultAchievements();
    await _loadAchievementsFromFirebase();
  }

  Future<void> createCustomAchievement({
    required String id,
    required String title,
    required String description,
    required String iconName,
    required AchievementType type,
    required AchievementRarity rarity,
    required int points,
    required int target,
    required String colorName,
    String? specialReward,
  }) async {
    await _firebaseService.createAchievement(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      type: type,
      rarity: rarity,
      points: points,
      target: target,
      colorName: colorName,
      specialReward: specialReward,
    );
    await _loadAchievementsFromFirebase();
  }

  // Get statistics including Firebase data
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _firebaseService.getUserStatistics();
    } catch (e) {
      print('Error getting Firebase statistics: $e');
      // Fallback to local statistics
      final unlockedCount = unlockedAchievements.length;
      return {
        'totalAchievements': achievements.length,
        'unlockedAchievements': unlockedCount,
        'totalPoints': totalPoints,
        'completionRate': achievements.isNotEmpty 
            ? (unlockedCount / achievements.length * 100).round() 
            : 0,
      };
    }
  }

  @override
  void dispose() {
    _firebaseService.dispose();
    super.dispose();
  }
} 