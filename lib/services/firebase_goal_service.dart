import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/firebase_goal.dart';

class FirebaseGoalService {
  static final FirebaseGoalService _instance = FirebaseGoalService._internal();
  factory FirebaseGoalService() => _instance;
  FirebaseGoalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference get _goalsCollection => _firestore.collection('goals');
  
  // Stream controllers for real-time updates
  StreamController<List<FirebaseGoal>> _goalsController = 
      StreamController<List<FirebaseGoal>>.broadcast();
  
  Stream<List<FirebaseGoal>> get goalsStream => _goalsController.stream;
  
  // Cache for goals
  List<FirebaseGoal> _cachedGoals = [];
  StreamSubscription<QuerySnapshot>? _goalsSubscription;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Initialize service and start listening to goals
  Future<void> initialize() async {
    if (currentUserId != null) {
      await _startListeningToGoals();
      
      // Check if migration has been done for this user
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'milestones_migrated_$currentUserId';
      
      if (!(prefs.getBool(migrationKey) ?? false)) {
        // Migration not done yet, perform it
        await migrateLegacyMilestones();
        await prefs.setBool(migrationKey, true);
      }
    }
  }
  
  // Re-initialize if needed (useful for debugging)
  Future<void> reinitialize() async {
    dispose();
    _goalsController = StreamController<List<FirebaseGoal>>.broadcast();
    await initialize();
  }

  // Debug method: Get goals without complex indexing
  Future<List<FirebaseGoal>> getGoalsSimple() async {
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _goalsCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      final goals = snapshot.docs
          .map((doc) => FirebaseGoal.fromFirestore(doc))
          .toList();
      
      // Sort locally instead of relying on Firestore index
      goals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      print('DEBUG: Found ${goals.length} goals for user $currentUserId');
      for (final goal in goals) {
        print('DEBUG: Goal: ${goal.title} (${goal.id})');
      }
      
      return goals;
    } catch (e) {
      print('DEBUG: Error getting goals: $e');
      return [];
    }
  }

  // Start listening to user's goals
  Future<void> _startListeningToGoals() async {
    if (currentUserId == null) return;

    _goalsSubscription?.cancel();
    _goalsSubscription = _goalsCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _cachedGoals = snapshot.docs
          .map((doc) => FirebaseGoal.fromFirestore(doc))
          .toList();
      
      // Only add to stream if controller is not closed
      if (!_goalsController.isClosed) {
        _goalsController.add(_cachedGoals);
      }
    });
  }

  // Stop listening to goals
  void dispose() {
    _goalsSubscription?.cancel();
    if (!_goalsController.isClosed) {
      _goalsController.close();
    }
  }

  // Create a new goal
  Future<FirebaseGoal> createGoal({
    required String title,
    required String description,
    required GoalCategory category,
    required DateTime startDate,
    DateTime? endDate,
    required double targetValue,
    required String unit,
    double stakeAmount = 0.0,
    List<String> partnerIds = const [],
    List<String> milestones = const [],
    Map<String, dynamic> reminderSettings = const {},
    String? imageUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final docRef = _goalsCollection.doc();
    
    // Convert milestone strings to Milestone objects
    final milestoneObjects = milestones.map((title) => Milestone(
      id: _uuid.v4(),
      title: title,
    )).toList();
    
    final goal = FirebaseGoal(
      id: docRef.id,
      userId: currentUserId!,
      title: title,
      description: description,
      category: category,
      startDate: startDate,
      endDate: endDate,
      targetValue: targetValue,
      unit: unit,
      stakeAmount: stakeAmount,
      partnerIds: partnerIds,
      milestones: milestoneObjects,
      createdAt: now,
      updatedAt: now,
      reminderSettings: reminderSettings,
      imageUrl: imageUrl,
    );

    await docRef.set(goal.toFirestore());
    return goal;
  }

  // Update a goal
  Future<FirebaseGoal> updateGoal(String goalId, {
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
    Map<String, dynamic>? reminderSettings,
    String? imageUrl,
    GoalCompletion? completion,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final goalDoc = await _goalsCollection.doc(goalId).get();
    if (!goalDoc.exists) {
      throw Exception('Goal not found');
    }

    final existingGoal = FirebaseGoal.fromFirestore(goalDoc);
    
    // Verify ownership
    if (existingGoal.userId != currentUserId) {
      throw Exception('Unauthorized: Cannot update another user\'s goal');
    }

    final updatedGoal = existingGoal.copyWith(
      title: title,
      description: description,
      category: category,
      startDate: startDate,
      endDate: endDate,
      targetValue: targetValue,
      currentProgress: currentProgress,
      unit: unit,
      stakeAmount: stakeAmount,
      status: status,
      partnerIds: partnerIds,
      milestones: milestones,
      reminderSettings: reminderSettings,
      imageUrl: imageUrl,
      completion: completion,
      updatedAt: DateTime.now(),
    );

    await _goalsCollection.doc(goalId).update(updatedGoal.toFirestore());
    return updatedGoal;
  }

  // Update goal progress
  Future<void> updateProgress(String goalId, double progress) async {
    // Use the new auto-completion method
    await updateProgressWithAutoComplete(goalId, progress);
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final goalDoc = await _goalsCollection.doc(goalId).get();
    if (!goalDoc.exists) {
      throw Exception('Goal not found');
    }

    final goal = FirebaseGoal.fromFirestore(goalDoc);
    
    // Verify ownership
    if (goal.userId != currentUserId) {
      throw Exception('Unauthorized: Cannot delete another user\'s goal');
    }

    await _goalsCollection.doc(goalId).delete();
  }

  // Get a specific goal
  Future<FirebaseGoal?> getGoal(String goalId) async {
    final doc = await _goalsCollection.doc(goalId).get();
    if (!doc.exists) return null;
    return FirebaseGoal.fromFirestore(doc);
  }

  // Get all goals for current user
  Future<List<FirebaseGoal>> getGoals() async {
    if (currentUserId == null) return [];

    final snapshot = await _goalsCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FirebaseGoal.fromFirestore(doc))
        .toList();
  }

  // Get goals shared with partners
  Future<List<FirebaseGoal>> getSharedGoals(List<String> partnerIds) async {
    if (currentUserId == null || partnerIds.isEmpty) return [];

    final snapshot = await _goalsCollection
        .where('partnerIds', arrayContainsAny: partnerIds)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FirebaseGoal.fromFirestore(doc))
        .toList();
  }

  // Add partner to goal
  Future<void> addPartnerToGoal(String goalId, String partnerId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _goalsCollection.doc(goalId).update({
      'partnerIds': FieldValue.arrayUnion([partnerId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Remove partner from goal
  Future<void> removePartnerFromGoal(String goalId, String partnerId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _goalsCollection.doc(goalId).update({
      'partnerIds': FieldValue.arrayRemove([partnerId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Mark goal as completed
  Future<void> completeGoal(String goalId) async {
    await updateGoal(goalId, 
      status: GoalStatus.completed,
      currentProgress: await getGoal(goalId).then((goal) => goal?.targetValue ?? 0)
    );
  }

  // Getters for filtered lists (from cached data)
  List<FirebaseGoal> get goals => List.unmodifiable(_cachedGoals);
  
  List<FirebaseGoal> get activeGoals => _cachedGoals
      .where((goal) => goal.status == GoalStatus.active)
      .toList();

  List<FirebaseGoal> get completedGoals => _cachedGoals
      .where((goal) => goal.status == GoalStatus.completed)
      .toList();

  List<FirebaseGoal> get overdueGoals => _cachedGoals
      .where((goal) => goal.isOverdue)
      .toList();

  List<FirebaseGoal> get pausedGoals => _cachedGoals
      .where((goal) => goal.status == GoalStatus.paused)
      .toList();

  // Get total stakes at risk
  double get totalStakesAtRisk => activeGoals
      .fold(0.0, (sum, goal) => sum + goal.stakeAmount);

  // Get goals by category
  List<FirebaseGoal> getGoalsByCategory(GoalCategory category) {
    return _cachedGoals
        .where((goal) => goal.category == category)
        .toList();
  }

  // Search goals
  List<FirebaseGoal> searchGoals(String query) {
    if (query.isEmpty) return _cachedGoals;
    
    final lowercaseQuery = query.toLowerCase();
    return _cachedGoals.where((goal) {
      return goal.title.toLowerCase().contains(lowercaseQuery) ||
             goal.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Upload photo to Firebase Storage
  Future<String?> uploadPhoto(File photoFile, String path) async {
    try {
      print('Starting photo upload to path: $path');
      print('File size: ${await photoFile.length()} bytes');
      
      // Check if file exists
      if (!await photoFile.exists()) {
        print('Error: Photo file does not exist');
        return null;
      }

      // Create storage reference
      final ref = _storage.ref().child(path);
      print('Storage reference created: ${ref.fullPath}');
      
      // Upload file
      print('Starting upload task...');
      final uploadTask = await ref.putFile(photoFile);
      print('Upload completed successfully');
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error uploading photo: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General error uploading photo: $e');
      return null;
    }
  }

  // Pick and upload photo
  Future<String?> pickAndUploadPhoto(String goalId, String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      
      final file = File(image.path);
      final fileName = '${_uuid.v4()}.jpg';
      final path = 'goals/$goalId/$type/$fileName';
      
      return await uploadPhoto(file, path);
    } catch (e) {
      print('Error picking and uploading photo: $e');
      return null;
    }
  }

  // Complete a milestone
  Future<void> completeMilestone(
    String goalId, 
    String milestoneId, {
    String? note,
    String? photoUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final goal = await getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    // Update the specific milestone
    final updatedMilestones = goal.milestones.map((milestone) {
      if (milestone.id == milestoneId) {
        return milestone.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          completionNote: note,
          completionPhotoUrl: photoUrl,
        );
      }
      return milestone;
    }).toList();

    await _goalsCollection.doc(goalId).update({
      'milestones': updatedMilestones.map((m) => m.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Complete a goal with optional photo and note
  Future<void> completeGoalWithDetails({
    required String goalId,
    String? note,
    String? photoUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final goal = await getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    final completion = GoalCompletion(
      completedAt: DateTime.now(),
      completionNote: note,
      completionPhotoUrl: photoUrl,
      finalProgress: goal.currentProgress,
    );

    await _goalsCollection.doc(goalId).update({
      'status': GoalStatus.completed.name,
      'completion': completion.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update goal progress with auto-completion check
  Future<void> updateProgressWithAutoComplete(String goalId, double progress) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final goal = await getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    // Update progress
    await _goalsCollection.doc(goalId).update({
      'currentProgress': progress,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Check for auto-completion (100% progress)
    if (goal.status == GoalStatus.active && progress >= goal.targetValue) {
      await completeGoalWithDetails(goalId: goalId);
    }
  }

  // Check and auto-complete goals that have reached 100%
  Future<void> checkAndAutoCompleteGoals() async {
    final goalsToComplete = activeGoals.where((goal) => goal.shouldAutoComplete).toList();
    
    for (final goal in goalsToComplete) {
      await completeGoalWithDetails(goalId: goal.id);
    }
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final total = _cachedGoals.length;
    final active = activeGoals.length;
    final completed = completedGoals.length;
    final overdue = overdueGoals.length;
    
    return {
      'total': total,
      'active': active,
      'completed': completed,
      'overdue': overdue,
      'completionRate': total > 0 ? (completed / total * 100).round() : 0,
      'totalStakes': totalStakesAtRisk,
    };
  }

  /// Returns smart increment based on target value:
  /// - < 50: increment by 1
  /// - < 200: increment by 5  
  /// - < 500: increment by 25
  /// - < 1000: increment by 50
  /// - >= 1000: increment by 100
  static double getSmartIncrement(double targetValue) {
    if (targetValue < 50) {
      return 1;
    } else if (targetValue < 200) {
      return 5;
    } else if (targetValue < 500) {
      return 25;
    } else if (targetValue < 1000) {
      return 50;
    } else {
      return 100;
    }
  }

  // Migration method to update old goals with new milestone format
  Future<void> migrateLegacyMilestones() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      print('Starting milestone migration...');
      
      final snapshot = await _goalsCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      int migratedCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawMilestones = data['milestones'] as List<dynamic>?;
        
        if (rawMilestones != null && rawMilestones.isNotEmpty) {
          // Check if first milestone is a string (old format)
          if (rawMilestones.first is String) {
            print('Migrating goal: ${data['title']} (${doc.id})');
            
            // Convert string milestones to Milestone objects
            final migratedMilestones = rawMilestones.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value as String;
              
              return Milestone(
                id: 'milestone_${index}_${title.hashCode}',
                title: title,
              );
            }).toList();
            
            // Update the goal with new milestone format
            await _goalsCollection.doc(doc.id).update({
              'milestones': migratedMilestones.map((m) => m.toMap()).toList(),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
            
            migratedCount++;
          }
        }
      }
      
      print('Migration completed: $migratedCount goals migrated');
    } catch (e) {
      print('Migration error: $e');
    }
  }
} 