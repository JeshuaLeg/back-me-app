import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  goalCompletion,
  streak,
  consistency,
  improvement,
  social,
  financial,
  special,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementType type;
  final AchievementRarity rarity;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;
  final int target;
  final Color color;
  final String? specialReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.points,
    required this.isUnlocked,
    required this.progress,
    required this.target,
    required this.color,
    this.unlockedAt,
    this.specialReward,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    AchievementType? type,
    AchievementRarity? rarity,
    int? points,
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
    int? target,
    Color? color,
    String? specialReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      color: color ?? this.color,
      specialReward: specialReward ?? this.specialReward,
    );
  }

  double get progressPercentage => progress / target;
  bool get isCompleted => progress >= target;
}

// Firebase-compatible Achievement model
class FirebaseAchievement {
  final String id;
  final String title;
  final String description;
  final String iconName; // Store as string reference
  final AchievementType type;
  final AchievementRarity rarity;
  final int points;
  final int target;
  final String colorName; // Store as string reference
  final String? specialReward;
  final bool isActive; // Whether this achievement is currently active/enabled
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirebaseAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    required this.rarity,
    required this.points,
    required this.target,
    required this.colorName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.specialReward,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'type': type.name,
      'rarity': rarity.name,
      'points': points,
      'target': target,
      'colorName': colorName,
      'specialReward': specialReward,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory FirebaseAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseAchievement(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'star',
      type: AchievementType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AchievementType.special,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      points: data['points'] ?? 0,
      target: data['target'] ?? 1,
      colorName: data['colorName'] ?? 'successGreen',
      specialReward: data['specialReward'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  FirebaseAchievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    AchievementType? type,
    AchievementRarity? rarity,
    int? points,
    int? target,
    String? colorName,
    String? specialReward,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirebaseAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      target: target ?? this.target,
      colorName: colorName ?? this.colorName,
      specialReward: specialReward ?? this.specialReward,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to local Achievement model with user progress
  Achievement toAchievement({
    required double progress,
    required bool isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: _getIconFromName(iconName),
      type: type,
      rarity: rarity,
      points: points,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
      progress: progress,
      target: target,
      color: _getColorFromName(colorName),
      specialReward: specialReward,
    );
  }

  // Icon name to IconData mapping
  static IconData _getIconFromName(String iconName) {
    const iconMap = {
      'flag_rounded': Icons.flag_rounded,
      'emoji_events_rounded': Icons.emoji_events_rounded,
      'workspace_premium_rounded': Icons.workspace_premium_rounded,
      'local_fire_department_rounded': Icons.local_fire_department_rounded,
      'whatshot_rounded': Icons.whatshot_rounded,
      'trending_up_rounded': Icons.trending_up_rounded,
      'attach_money_rounded': Icons.attach_money_rounded,
      'star_rounded': Icons.star_rounded,
      'people_rounded': Icons.people_rounded,
      'badge_rounded': Icons.badge_rounded,
      'collections_bookmark_rounded': Icons.collections_bookmark_rounded,
      'sports_bar_rounded': Icons.sports_bar_rounded,
      'checkroom_rounded': Icons.checkroom_rounded,
      'dry_cleaning_rounded': Icons.dry_cleaning_rounded,
      'palette_rounded': Icons.palette_rounded,
    };
    return iconMap[iconName] ?? Icons.star_rounded;
  }

  // Color name to Color mapping
  static Color _getColorFromName(String colorName) {
    final colorMap = {
      'successGreen': Color(0xFF10B981),
      'warningAmber': Color(0xFFF59E0B),
      'accentIndigo': Color(0xFF6366F1),
      'errorRose': Color(0xFFF43F5E),
      'primarySlate': Color(0xFF475569),
      'orange': Colors.orange,
      'purple': Colors.purple,
      'blue': Colors.blue,
      'mutedText': Color(0xFF9CA3AF),
    };
    return colorMap[colorName] ?? const Color(0xFF10B981);
  }

  // Helper to get icon name from IconData
  static String getIconName(IconData icon) {
    final iconMap = {
      Icons.flag_rounded: 'flag_rounded',
      Icons.emoji_events_rounded: 'emoji_events_rounded',
      Icons.workspace_premium_rounded: 'workspace_premium_rounded',
      Icons.local_fire_department_rounded: 'local_fire_department_rounded',
      Icons.whatshot_rounded: 'whatshot_rounded',
      Icons.trending_up_rounded: 'trending_up_rounded',
      Icons.attach_money_rounded: 'attach_money_rounded',
      Icons.star_rounded: 'star_rounded',
      Icons.people_rounded: 'people_rounded',
      Icons.badge_rounded: 'badge_rounded',
      Icons.collections_bookmark_rounded: 'collections_bookmark_rounded',
      Icons.sports_bar_rounded: 'sports_bar_rounded',
      Icons.checkroom_rounded: 'checkroom_rounded',
      Icons.dry_cleaning_rounded: 'dry_cleaning_rounded',
      Icons.palette_rounded: 'palette_rounded',
    };
    return iconMap[icon] ?? 'star_rounded';
  }

  // Helper to get color name from Color
  static String getColorName(Color color) {
    final colorMap = {
      Color(0xFF10B981): 'successGreen',
      Color(0xFFF59E0B): 'warningAmber',
      Color(0xFF6366F1): 'accentIndigo',
      Color(0xFFF43F5E): 'errorRose',
      Color(0xFF475569): 'primarySlate',
      Colors.orange: 'orange',
      Colors.purple: 'purple',
      Colors.blue: 'blue',
      Color(0xFF9CA3AF): 'mutedText',
    };
    return colorMap[color] ?? 'successGreen';
  }
}

// User Achievement Progress - stored per user
class UserAchievementProgress {
  final String userId;
  final String achievementId;
  final double progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime updatedAt;

  const UserAchievementProgress({
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.isUnlocked,
    required this.updatedAt,
    this.unlockedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'progress': progress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserAchievementProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAchievementProgress(
      userId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      progress: (data['progress'] ?? 0.0).toDouble(),
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserAchievementProgress copyWith({
    String? userId,
    String? achievementId,
    double? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? updatedAt,
  }) {
    return UserAchievementProgress(
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime earnedAt;
  final bool isSpecial;

  const UserBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
    this.isSpecial = false,
  });
}

class Reward {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int pointsRequired;
  final String category;
  final bool isAvailable;
  final bool isUnlocked;
  final String? imageUrl;
  final Color color;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    required this.category,
    required this.isAvailable,
    required this.isUnlocked,
    required this.color,
    this.imageUrl,
  });
}

class UserLevel {
  final int level;
  final String title;
  final String description;
  final int pointsRequired;
  final int currentPoints;
  final Color color;
  final List<String> perks;

  const UserLevel({
    required this.level,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.currentPoints,
    required this.color,
    required this.perks,
  });

  double get progressToNext => currentPoints / pointsRequired;
  bool get isUnlocked => currentPoints >= pointsRequired;
} 