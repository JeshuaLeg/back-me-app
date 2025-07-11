import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, completed, paused, cancelled }
enum GoalCategory { health, finance, career, education, personal, other }

extension GoalCategoryExtension on GoalCategory {
  Color get color {
    switch (this) {
      case GoalCategory.health:
        return const Color(0xFF4CAF50);
      case GoalCategory.finance:
        return const Color(0xFF2196F3);
      case GoalCategory.career:
        return const Color(0xFF9C27B0);
      case GoalCategory.education:
        return const Color(0xFFFF9800);
      case GoalCategory.personal:
        return const Color(0xFFE91E63);
      case GoalCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.other:
        return Icons.star;
    }
  }

  String get displayName {
    switch (this) {
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.education:
        return 'Education';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.other:
        return 'Other';
    }
  }
}

class Milestone {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completionNote;
  final String? completionPhotoUrl;

  Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.completionNote,
    this.completionPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNote': completionNote,
      'completionPhotoUrl': completionPhotoUrl,
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      completionNote: map['completionNote'],
      completionPhotoUrl: map['completionPhotoUrl'],
    );
  }

  Milestone copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    String? completionNote,
    String? completionPhotoUrl,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completionNote: completionNote ?? this.completionNote,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
    );
  }
}

class GoalCompletion {
  final DateTime completedAt;
  final String? completionNote;
  final String? completionPhotoUrl;
  final double finalProgress;

  GoalCompletion({
    required this.completedAt,
    this.completionNote,
    this.completionPhotoUrl,
    required this.finalProgress,
  });

  Map<String, dynamic> toMap() {
    return {
      'completedAt': Timestamp.fromDate(completedAt),
      'completionNote': completionNote,
      'completionPhotoUrl': completionPhotoUrl,
      'finalProgress': finalProgress,
    };
  }

  factory GoalCompletion.fromMap(Map<String, dynamic> map) {
    return GoalCompletion(
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      completionNote: map['completionNote'],
      completionPhotoUrl: map['completionPhotoUrl'],
      finalProgress: (map['finalProgress'] ?? 0.0).toDouble(),
    );
  }
}

class FirebaseGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final GoalCategory category;
  final DateTime startDate;
  final DateTime? endDate;
  final double targetValue;
  final double currentProgress;
  final String unit;
  final double stakeAmount;
  final GoalStatus status;
  final List<String> partnerIds;
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> reminderSettings;
  final String? imageUrl;
  final GoalCompletion? completion;

  FirebaseGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    this.endDate,
    required this.targetValue,
    this.currentProgress = 0.0,
    required this.unit,
    this.stakeAmount = 0.0,
    this.status = GoalStatus.active,
    this.partnerIds = const [],
    this.milestones = const [],
    required this.createdAt,
    required this.updatedAt,
    this.reminderSettings = const {},
    this.imageUrl,
    this.completion,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'unit': unit,
      'stakeAmount': stakeAmount,
      'status': status.name,
      'partnerIds': partnerIds,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reminderSettings': reminderSettings,
      'imageUrl': imageUrl,
      'completion': completion?.toMap(),
    };
  }

  // Create from Firestore document
  factory FirebaseGoal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseGoal(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: GoalCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => GoalCategory.other,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      targetValue: (data['targetValue'] ?? 0.0).toDouble(),
      currentProgress: (data['currentProgress'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      stakeAmount: (data['stakeAmount'] ?? 0.0).toDouble(),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GoalStatus.active,
      ),
      partnerIds: List<String>.from(data['partnerIds'] ?? []),
      milestones: _parseMilestones(data['milestones']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      reminderSettings: Map<String, dynamic>.from(data['reminderSettings'] ?? {}),
      imageUrl: data['imageUrl'],
      completion: data['completion'] != null ? GoalCompletion.fromMap(data['completion'] as Map<String, dynamic>) : null,
    );
  }

  // Helper method to parse milestones with backward compatibility
  static List<Milestone> _parseMilestones(dynamic milestonesData) {
    if (milestonesData == null) return [];
    
    final List<dynamic> rawMilestones = milestonesData as List<dynamic>;
    final List<Milestone> milestones = [];
    
    for (int i = 0; i < rawMilestones.length; i++) {
      final dynamic item = rawMilestones[i];
      
      if (item is String) {
        // Old format: milestone is just a string title
        milestones.add(Milestone(
          id: 'milestone_${i}_${item.hashCode}', // Generate stable ID
          title: item,
        ));
      } else if (item is Map<String, dynamic>) {
        // New format: milestone is a complete object
        try {
          milestones.add(Milestone.fromMap(item));
        } catch (e) {
          // If parsing fails, fall back to treating it as a string
          milestones.add(Milestone(
            id: 'milestone_${i}_fallback',
            title: item['title']?.toString() ?? 'Milestone ${i + 1}',
          ));
        }
      } else {
        // Unknown format, create a default milestone
        milestones.add(Milestone(
          id: 'milestone_${i}_default',
          title: 'Milestone ${i + 1}',
        ));
      }
    }
    
    return milestones;
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  // Check if goal should be auto-completed (reached 100% progress)
  bool get shouldAutoComplete {
    return status == GoalStatus.active && progressPercentage >= 1.0;
  }

  // Check if goal is overdue
  bool get isOverdue {
    if (endDate == null || status != GoalStatus.active) return false;
    return DateTime.now().isAfter(endDate!);
  }

  // Get remaining days
  int get daysRemaining {
    if (endDate == null) return -1;
    return endDate!.difference(DateTime.now()).inDays;
  }

  // Get completed milestones count
  int get completedMilestonesCount {
    return milestones.where((m) => m.isCompleted).length;
  }

  // Get milestone completion percentage
  double get milestoneCompletionPercentage {
    if (milestones.isEmpty) return 0.0;
    return completedMilestonesCount / milestones.length;
  }

  // Check if all milestones are completed
  bool get allMilestonesCompleted {
    return milestones.isNotEmpty && milestones.every((m) => m.isCompleted);
  }

  // Get goal color based on category
  Color get categoryColor {
    switch (category) {
      case GoalCategory.health:
        return const Color(0xFF4CAF50);
      case GoalCategory.finance:
        return const Color(0xFF2196F3);
      case GoalCategory.career:
        return const Color(0xFF9C27B0);
      case GoalCategory.education:
        return const Color(0xFFFF9800);
      case GoalCategory.personal:
        return const Color(0xFFE91E63);
      case GoalCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  // Get category icon
  IconData get categoryIcon {
    switch (category) {
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.other:
        return Icons.star;
    }
  }

  // Copy with method for updates
  FirebaseGoal copyWith({
    String? title,
    String? description,
    GoalCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    double? targetValue,
    double? currentProgress,
    String? unit,
    double? stakeAmount,
    GoalStatus? status,
    List<String>? partnerIds,
    List<Milestone>? milestones,
    DateTime? updatedAt,
    Map<String, dynamic>? reminderSettings,
    String? imageUrl,
    GoalCompletion? completion,
  }) {
    return FirebaseGoal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      unit: unit ?? this.unit,
      stakeAmount: stakeAmount ?? this.stakeAmount,
      status: status ?? this.status,
      partnerIds: partnerIds ?? this.partnerIds,
      milestones: milestones ?? this.milestones,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reminderSettings: reminderSettings ?? this.reminderSettings,
      imageUrl: imageUrl ?? this.imageUrl,
      completion: completion ?? this.completion,
    );
  }

  @override
  String toString() {
    return 'FirebaseGoal(id: $id, title: $title, progress: ${progressPercentage * 100}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirebaseGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 