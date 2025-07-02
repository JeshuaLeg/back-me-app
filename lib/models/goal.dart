import 'package:flutter/material.dart';

enum GoalStatus {
  active,
  completed,
  failed,
  paused,
}

enum GoalCategory {
  fitness,
  health,
  career,
  education,
  finance,
  personal,
  relationships,
  habits,
  other,
}

class AccountabilityPartner {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool canSendReminders;
  final bool canReceiveStakes;

  AccountabilityPartner({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.canSendReminders = true,
    this.canReceiveStakes = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'canSendReminders': canSendReminders,
      'canReceiveStakes': canReceiveStakes,
    };
  }

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) {
    return AccountabilityPartner(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      canSendReminders: json['canSendReminders'] ?? true,
      canReceiveStakes: json['canReceiveStakes'] ?? false,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime deadline;
  final double stakeAmount;
  final List<AccountabilityPartner> accountabilityPartners;
  final List<String> reminderTimes; // Time strings like "09:00", "18:00"
  final int reminderFrequency; // Days between reminders
  final bool isStakeReleased;
  final double progress; // 0.0 to 1.0
  final List<String> milestones;
  final List<bool> milestonesCompleted;
  final String? notes;
  final Color? color;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.status = GoalStatus.active,
    required this.createdAt,
    required this.deadline,
    this.stakeAmount = 0.0,
    this.accountabilityPartners = const [],
    this.reminderTimes = const [],
    this.reminderFrequency = 1,
    this.isStakeReleased = false,
    this.progress = 0.0,
    this.milestones = const [],
    this.milestonesCompleted = const [],
    this.notes,
    this.color,
  });

  // Helper methods
  bool get isOverdue => DateTime.now().isAfter(deadline) && status == GoalStatus.active;
  
  int get daysRemaining {
    final difference = deadline.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  String get categoryDisplayName {
    switch (category) {
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.education:
        return 'Education';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.habits:
        return 'Habits';
      case GoalCategory.other:
        return 'Other';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.health:
        return Icons.health_and_safety;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.relationships:
        return Icons.favorite;
      case GoalCategory.habits:
        return Icons.repeat;
      case GoalCategory.other:
        return Icons.category;
    }
  }

  Color get statusColor {
    switch (status) {
      case GoalStatus.active:
        return isOverdue ? Colors.red : Colors.blue;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.failed:
        return Colors.red;
      case GoalStatus.paused:
        return Colors.orange;
    }
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? deadline,
    double? stakeAmount,
    List<AccountabilityPartner>? accountabilityPartners,
    List<String>? reminderTimes,
    int? reminderFrequency,
    bool? isStakeReleased,
    double? progress,
    List<String>? milestones,
    List<bool>? milestonesCompleted,
    String? notes,
    Color? color,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      stakeAmount: stakeAmount ?? this.stakeAmount,
      accountabilityPartners: accountabilityPartners ?? this.accountabilityPartners,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      isStakeReleased: isStakeReleased ?? this.isStakeReleased,
      progress: progress ?? this.progress,
      milestones: milestones ?? this.milestones,
      milestonesCompleted: milestonesCompleted ?? this.milestonesCompleted,
      notes: notes ?? this.notes,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'stakeAmount': stakeAmount,
      'accountabilityPartners': accountabilityPartners.map((p) => p.toJson()).toList(),
      'reminderTimes': reminderTimes,
      'reminderFrequency': reminderFrequency,
      'isStakeReleased': isStakeReleased,
      'progress': progress,
      'milestones': milestones,
      'milestonesCompleted': milestonesCompleted,
      'notes': notes,
      'color': color?.value,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: GoalCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => GoalCategory.other,
      ),
      status: GoalStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      deadline: DateTime.parse(json['deadline']),
      stakeAmount: json['stakeAmount']?.toDouble() ?? 0.0,
      accountabilityPartners: (json['accountabilityPartners'] as List?)
          ?.map((p) => AccountabilityPartner.fromJson(p))
          .toList() ?? [],
      reminderTimes: List<String>.from(json['reminderTimes'] ?? []),
      reminderFrequency: json['reminderFrequency'] ?? 1,
      isStakeReleased: json['isStakeReleased'] ?? false,
      progress: json['progress']?.toDouble() ?? 0.0,
      milestones: List<String>.from(json['milestones'] ?? []),
      milestonesCompleted: List<bool>.from(json['milestonesCompleted'] ?? []),
      notes: json['notes'],
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
} 