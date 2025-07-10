import 'package:flutter/material.dart';

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