import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/firebase_achievement_service.dart';
import '../services/achievement_service.dart';

/// Admin utility for managing Firebase achievements
/// This is useful for testing and adding new achievements dynamically
class AchievementAdmin {
  static final FirebaseAchievementService _firebaseService = FirebaseAchievementService();
  static final AchievementService _achievementService = AchievementService();

  /// Seed default achievements to Firebase
  /// Call this once to populate Firebase with the initial achievements
  static Future<void> seedDefaultAchievements() async {
    try {
      await _firebaseService.seedDefaultAchievements();
      print('✅ Default achievements seeded successfully');
    } catch (e) {
      print('❌ Error seeding achievements: $e');
    }
  }

  /// Create a new custom achievement
  static Future<void> createCustomAchievement({
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
    try {
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
      print('✅ Created achievement: $title');
    } catch (e) {
      print('❌ Error creating achievement: $e');
    }
  }

  /// Create some example custom achievements
  static Future<void> createExampleAchievements() async {
    final achievements = [
      {
        'id': 'perfectionist',
        'title': 'Perfectionist',
        'description': 'Complete 3 goals with 100% milestone completion',
        'iconName': 'workspace_premium_rounded',
        'type': AchievementType.goalCompletion,
        'rarity': AchievementRarity.rare,
        'points': 300,
        'target': 3,
        'colorName': 'accentIndigo',
        'specialReward': 'Perfectionist Badge',
      },
      {
        'id': 'early_bird',
        'title': 'Early Bird',
        'description': 'Complete 5 goals before their deadline',
        'iconName': 'trending_up_rounded',
        'type': AchievementType.consistency,
        'rarity': AchievementRarity.uncommon,
        'points': 150,
        'target': 5,
        'colorName': 'successGreen',
      },
      {
        'id': 'social_butterfly',
        'title': 'Social Butterfly',
        'description': 'Share 10 goal completions with partners',
        'iconName': 'people_rounded',
        'type': AchievementType.social,
        'rarity': AchievementRarity.uncommon,
        'points': 200,
        'target': 10,
        'colorName': 'primarySlate',
      },
      {
        'id': 'marathon_runner',
        'title': 'Marathon Runner',
        'description': 'Maintain a 100-day streak',
        'iconName': 'local_fire_department_rounded',
        'type': AchievementType.streak,
        'rarity': AchievementRarity.legendary,
        'points': 2000,
        'target': 100,
        'colorName': 'errorRose',
        'specialReward': 'Legendary Streak Champion Trophy',
      },
    ];

    for (final achievementData in achievements) {
      await createCustomAchievement(
        id: achievementData['id'] as String,
        title: achievementData['title'] as String,
        description: achievementData['description'] as String,
        iconName: achievementData['iconName'] as String,
        type: achievementData['type'] as AchievementType,
        rarity: achievementData['rarity'] as AchievementRarity,
        points: achievementData['points'] as int,
        target: achievementData['target'] as int,
        colorName: achievementData['colorName'] as String,
        specialReward: achievementData['specialReward'] as String?,
      );
    }
  }

  /// Force unlock an achievement for the current user (for testing)
  static Future<void> forceUnlockAchievement(String achievementId) async {
    try {
      await _firebaseService.updateUserProgress(
        achievementId: achievementId,
        progress: 1.0,
        forceUnlock: true,
      );
      print('✅ Force unlocked achievement: $achievementId');
    } catch (e) {
      print('❌ Error force unlocking achievement: $e');
    }
  }

  /// Get current achievement statistics
  static Future<void> printAchievementStats() async {
    try {
      final stats = await _firebaseService.getUserStatistics();
      print('📊 Achievement Statistics:');
      print('   Total Achievements: ${stats['totalAchievements']}');
      print('   Unlocked: ${stats['unlockedAchievements']}');
      print('   Total Points: ${stats['totalPoints']}');
      print('   Completion Rate: ${stats['completionRate']}%');
    } catch (e) {
      print('❌ Error getting statistics: $e');
    }
  }

  /// List all available achievements
  static Future<void> listAllAchievements() async {
    try {
      final achievements = await _firebaseService.getUserAchievements();
      print('🏆 All Achievements:');
      for (final achievement in achievements) {
        final status = achievement.isUnlocked ? '✅' : '⏳';
        final progress = achievement.isUnlocked 
            ? 'UNLOCKED' 
            : '${achievement.progress.toInt()}/${achievement.target}';
        print('   $status ${achievement.title} - $progress (${achievement.points} pts)');
      }
    } catch (e) {
      print('❌ Error listing achievements: $e');
    }
  }

  /// Deactivate an achievement (admin function)
  static Future<void> deactivateAchievement(String achievementId) async {
    try {
      await _firebaseService.deactivateAchievement(achievementId);
      print('✅ Deactivated achievement: $achievementId');
    } catch (e) {
      print('❌ Error deactivating achievement: $e');
    }
  }

  /// Full reset and re-seed (use with caution!)
  static Future<void> resetAndReseed() async {
    print('🔄 Resetting and re-seeding achievements...');
    
    // Note: In a production app, you might want to add confirmation dialogs
    // and proper error handling before doing destructive operations
    
    await seedDefaultAchievements();
    await createExampleAchievements();
    
    print('✅ Reset and re-seed completed');
  }

  /// Sync local achievement service with Firebase
  static Future<void> syncAchievementService() async {
    try {
      await _achievementService.syncWithFirebase();
      print('✅ Achievement service synced with Firebase');
    } catch (e) {
      print('❌ Error syncing achievement service: $e');
    }
  }
}

/// Debug widget for testing achievements in development
class AchievementDebugPanel extends StatelessWidget {
  const AchievementDebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Admin'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Achievement Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.seedDefaultAchievements(),
            child: const Text('Seed Default Achievements'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.createExampleAchievements(),
            child: const Text('Create Example Achievements'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.listAllAchievements(),
            child: const Text('List All Achievements'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.printAchievementStats(),
            child: const Text('Print Statistics'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.syncAchievementService(),
            child: const Text('Sync with Firebase'),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Quick Unlock (Testing)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.forceUnlockAchievement('first_goal'),
            child: const Text('Unlock: First Steps'),
          ),
          const SizedBox(height: 4),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.forceUnlockAchievement('early_adopter'),
            child: const Text('Unlock: Early Adopter'),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: () => AchievementAdmin.resetAndReseed(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset & Re-seed All'),
          ),
        ],
      ),
    );
  }
} 