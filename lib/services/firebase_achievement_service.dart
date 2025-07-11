import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/achievement.dart';

class FirebaseAchievementService {
  static final FirebaseAchievementService _instance = FirebaseAchievementService._internal();
  factory FirebaseAchievementService() => _instance;
  FirebaseAchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _achievementsCollection => _firestore.collection('achievements');
  CollectionReference get _userProgressCollection => _firestore.collection('user_achievement_progress');

  // Stream controllers for real-time updates
  final StreamController<List<FirebaseAchievement>> _achievementsController = 
      StreamController<List<FirebaseAchievement>>.broadcast();
  final StreamController<List<UserAchievementProgress>> _progressController = 
      StreamController<List<UserAchievementProgress>>.broadcast();
  
  Stream<List<FirebaseAchievement>> get achievementsStream => _achievementsController.stream;
  Stream<List<UserAchievementProgress>> get progressStream => _progressController.stream;
  
  // Cache
  List<FirebaseAchievement> _cachedAchievements = [];
  List<UserAchievementProgress> _cachedProgress = [];
  StreamSubscription<QuerySnapshot>? _achievementsSubscription;
  StreamSubscription<QuerySnapshot>? _progressSubscription;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize service
  Future<void> initialize() async {
    await _startListeningToAchievements();
    if (currentUserId != null) {
      await _startListeningToUserProgress();
    }
  }

  // Start listening to achievements
  Future<void> _startListeningToAchievements() async {
    _achievementsSubscription?.cancel();
    _achievementsSubscription = _achievementsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
      _cachedAchievements = snapshot.docs
          .map((doc) => FirebaseAchievement.fromFirestore(doc))
          .toList();
      
      if (!_achievementsController.isClosed) {
        _achievementsController.add(_cachedAchievements);
      }
    });
  }

  // Start listening to user progress
  Future<void> _startListeningToUserProgress() async {
    if (currentUserId == null) return;

    _progressSubscription?.cancel();
    _progressSubscription = _userProgressCollection
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      _cachedProgress = snapshot.docs
          .map((doc) => UserAchievementProgress.fromFirestore(doc))
          .toList();
      
      if (!_progressController.isClosed) {
        _progressController.add(_cachedProgress);
      }
    });
  }

  // Get all achievements with user progress
  Future<List<Achievement>> getUserAchievements() async {
    if (_cachedAchievements.isEmpty) {
      await _loadAchievements();
    }
    
    final userProgress = await _getUserProgress();
    final progressMap = <String, UserAchievementProgress>{};
    for (final progress in userProgress) {
      progressMap[progress.achievementId] = progress;
    }

    return _cachedAchievements.map((firebaseAchievement) {
      final progress = progressMap[firebaseAchievement.id];
      return firebaseAchievement.toAchievement(
        progress: progress?.progress ?? 0.0,
        isUnlocked: progress?.isUnlocked ?? false,
        unlockedAt: progress?.unlockedAt,
      );
    }).toList();
  }

  // Load achievements from Firestore
  Future<void> _loadAchievements() async {
    final snapshot = await _achievementsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .get();
    
    _cachedAchievements = snapshot.docs
        .map((doc) => FirebaseAchievement.fromFirestore(doc))
        .toList();
  }

  // Get user progress
  Future<List<UserAchievementProgress>> _getUserProgress() async {
    if (currentUserId == null) return [];
    
    if (_cachedProgress.isEmpty) {
      final snapshot = await _userProgressCollection
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      _cachedProgress = snapshot.docs
          .map((doc) => UserAchievementProgress.fromFirestore(doc))
          .toList();
    }
    
    return _cachedProgress;
  }

  // Update user progress for an achievement
  Future<void> updateUserProgress({
    required String achievementId,
    required double progress,
    bool? forceUnlock,
  }) async {
    if (currentUserId == null) return;

    final achievement = _cachedAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => throw Exception('Achievement not found'),
    );

    final isUnlocked = forceUnlock ?? (progress >= achievement.target);
    final now = DateTime.now();
    
    final existingProgress = _cachedProgress.firstWhere(
      (p) => p.achievementId == achievementId,
      orElse: () => UserAchievementProgress(
        userId: currentUserId!,
        achievementId: achievementId,
        progress: 0.0,
        isUnlocked: false,
        updatedAt: now,
      ),
    );

    final updatedProgress = existingProgress.copyWith(
      progress: progress,
      isUnlocked: isUnlocked,
      unlockedAt: isUnlocked && !existingProgress.isUnlocked ? now : existingProgress.unlockedAt,
      updatedAt: now,
    );

    final docId = '${currentUserId}_$achievementId';
    await _userProgressCollection.doc(docId).set(updatedProgress.toFirestore());

    // Show notification if newly unlocked
    if (isUnlocked && !existingProgress.isUnlocked) {
      _showAchievementNotification(achievement);
    }
  }

  // Bulk update user stats (called from main achievement service)
  Future<void> updateUserStats({
    required int completedGoals,
    required int totalGoals,
    required int currentStreak,
    required int longestStreak,
    required double totalStakes,
    required int activePartners,
  }) async {
    if (currentUserId == null) return;

    // Update goal completion achievements
    await _updateIfExists('first_goal', completedGoals.toDouble());
    await _updateIfExists('goal_crusher', completedGoals.toDouble());
    await _updateIfExists('achievement_master', completedGoals.toDouble());
    
    // Update streak achievements
    await _updateIfExists('on_fire', longestStreak.toDouble());
    await _updateIfExists('unstoppable', longestStreak.toDouble());
    
    // Update financial achievements
    await _updateIfExists('high_roller', totalStakes);
    
    // Update social achievements
    await _updateIfExists('team_player', activePartners.toDouble());
  }

  // Helper to update achievement if it exists
  Future<void> _updateIfExists(String achievementId, double progress) async {
    try {
      await updateUserProgress(achievementId: achievementId, progress: progress);
    } catch (e) {
      // Achievement doesn't exist, ignore
      print('Achievement $achievementId not found: $e');
    }
  }

  // Show achievement notification
  void _showAchievementNotification(FirebaseAchievement achievement) {
    print('🎉 Achievement Unlocked: ${achievement.title}');
    // Here you could trigger a notification/toast in the UI
  }

  // Admin methods for managing achievements

  // Seed default achievements to Firebase
  Future<void> seedDefaultAchievements() async {
    final defaultAchievements = _getDefaultAchievements();
    
    for (final achievement in defaultAchievements) {
      final doc = await _achievementsCollection.doc(achievement.id).get();
      if (!doc.exists) {
        await _achievementsCollection.doc(achievement.id).set(achievement.toFirestore());
        print('Seeded achievement: ${achievement.title}');
      }
    }
  }

  // Create a new achievement (admin function)
  Future<FirebaseAchievement> createAchievement({
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
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final achievement = FirebaseAchievement(
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
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await _achievementsCollection.doc(id).set(achievement.toFirestore());
    return achievement;
  }

  // Update an achievement (admin function)
  Future<void> updateAchievement(String achievementId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _achievementsCollection.doc(achievementId).update(updates);
  }

  // Deactivate an achievement (admin function)
  Future<void> deactivateAchievement(String achievementId) async {
    await updateAchievement(achievementId, {'isActive': false});
  }

  // Get default achievements for seeding
  List<FirebaseAchievement> _getDefaultAchievements() {
    final now = DateTime.now();
    
    return [
      // Goal Completion Achievements
      FirebaseAchievement(
        id: 'first_goal',
        title: 'First Steps',
        description: 'Complete your first goal',
        iconName: 'flag_rounded',
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.common,
        points: 50,
        target: 1,
        colorName: 'successGreen',
        specialReward: 'Beginner Badge',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      FirebaseAchievement(
        id: 'goal_crusher',
        title: 'Goal Crusher',
        description: 'Complete 5 goals',
        iconName: 'emoji_events_rounded',
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.uncommon,
        points: 200,
        target: 5,
        colorName: 'warningAmber',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      FirebaseAchievement(
        id: 'achievement_master',
        title: 'Achievement Master',
        description: 'Complete 10 goals',
        iconName: 'workspace_premium_rounded',
        type: AchievementType.goalCompletion,
        rarity: AchievementRarity.rare,
        points: 500,
        target: 10,
        colorName: 'accentIndigo',
        specialReward: 'Master Badge + Limited Edition Sticker',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Streak Achievements
      FirebaseAchievement(
        id: 'on_fire',
        title: 'On Fire!',
        description: 'Maintain a 7-day streak',
        iconName: 'local_fire_department_rounded',
        type: AchievementType.streak,
        rarity: AchievementRarity.common,
        points: 100,
        target: 7,
        colorName: 'errorRose',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      FirebaseAchievement(
        id: 'unstoppable',
        title: 'Unstoppable',
        description: 'Maintain a 30-day streak',
        iconName: 'whatshot_rounded',
        type: AchievementType.streak,
        rarity: AchievementRarity.epic,
        points: 750,
        target: 30,
        colorName: 'orange',
        specialReward: 'Streak Champion T-Shirt',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Consistency Achievements
      FirebaseAchievement(
        id: 'consistent_performer',
        title: 'Consistent Performer',
        description: 'Complete goals 3 weeks in a row',
        iconName: 'trending_up_rounded',
        type: AchievementType.consistency,
        rarity: AchievementRarity.uncommon,
        points: 300,
        target: 3,
        colorName: 'accentIndigo',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Financial Achievements
      FirebaseAchievement(
        id: 'high_roller',
        title: 'High Roller',
        description: 'Have \$500+ in active stakes',
        iconName: 'attach_money_rounded',
        type: AchievementType.financial,
        rarity: AchievementRarity.rare,
        points: 400,
        target: 500,
        colorName: 'successGreen',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Special Achievements
      FirebaseAchievement(
        id: 'early_adopter',
        title: 'Early Adopter',
        description: 'One of the first 1000 users',
        iconName: 'star_rounded',
        type: AchievementType.special,
        rarity: AchievementRarity.legendary,
        points: 1000,
        target: 1,
        colorName: 'purple',
        specialReward: 'Exclusive Early Adopter Hoodie',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Social Achievements
      FirebaseAchievement(
        id: 'team_player',
        title: 'Team Player',
        description: 'Add 3 accountability partners',
        iconName: 'people_rounded',
        type: AchievementType.social,
        rarity: AchievementRarity.uncommon,
        points: 150,
        target: 3,
        colorName: 'primarySlate',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final achievements = await getUserAchievements();
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    final totalPoints = unlockedAchievements.fold(0, (sum, a) => sum + a.points);
    
    return {
      'totalAchievements': achievements.length,
      'unlockedAchievements': unlockedAchievements.length,
      'totalPoints': totalPoints,
      'completionRate': achievements.isNotEmpty 
          ? (unlockedAchievements.length / achievements.length * 100).round() 
          : 0,
    };
  }

  // Dispose
  void dispose() {
    _achievementsSubscription?.cancel();
    _progressSubscription?.cancel();
    if (!_achievementsController.isClosed) {
      _achievementsController.close();
    }
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }

  // Getters
  List<FirebaseAchievement> get achievements => List.unmodifiable(_cachedAchievements);
  List<UserAchievementProgress> get userProgress => List.unmodifiable(_cachedProgress);
} 