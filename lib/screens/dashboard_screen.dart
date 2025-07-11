import 'package:flutter/material.dart';
import '../models/firebase_goal.dart';
import '../services/firebase_goal_service.dart';
import '../services/firebase_reminder_service.dart';
import '../widgets/goal_card.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../main.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';
import 'achievements_screen.dart';
import 'reminders_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabSwitch;
  
  const DashboardScreen({super.key, this.onTabSwitch});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseGoalService _goalService = FirebaseGoalService();
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  final AuthService _authService = AuthService();
  final AchievementService _achievementService = AchievementService();
  late AnimationController _fabAnimation;
  late AnimationController _headerAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  
  // State for expanding/collapsing active goals
  bool _areGoalsExpanded = false;
  List<FirebaseGoal> _currentGoals = [];

  @override
  void initState() {
    super.initState();
    _fabAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimation,
      curve: Curves.easeOutCubic,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimation,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _fabAnimation.forward();
    _headerAnimation.forward();
    
    // Initialize Firebase goal service
    _goalService.initialize();
    
    // Listen to goals stream to update achievement service
    _goalService.goalsStream.listen((goals) {
      _currentGoals = goals;
      // Update achievement service to work with FirebaseGoal
      _achievementService.initializeWithGoalData(goals);
    });
  }

  @override
  void dispose() {
    _fabAnimation.dispose();
    _headerAnimation.dispose();
    super.dispose();
  }

  // Helper method to convert FirebaseGoals to old Goal format for AchievementService
  // TODO: Update AchievementService to use FirebaseGoal directly
  List<dynamic> _convertToOldGoals(List<FirebaseGoal> firebaseGoals) {
    // For now, return empty list to avoid errors
    // The AchievementService should be updated to work with FirebaseGoal
    return [];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalMessage(List<FirebaseGoal> goals) {
    final activeGoals = goals.where((goal) => goal.status == GoalStatus.active).length;
    final completedGoals = goals.where((goal) => goal.status == GoalStatus.completed).length;
    
    if (activeGoals == 0) {
      return "Ready to start your journey?";
    } else if (activeGoals > completedGoals) {
      return "You're making great progress!";
    } else {
      return "Keep up the momentum!";
    }
  }

  String _getUserInitials() {
    final name = _authService.userDisplayName;
    if (name.isEmpty) return 'U';
    
    final words = name.split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primarySlate.withValues(alpha: 0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: StreamBuilder<List<FirebaseGoal>>(
          stream: _goalService.goalsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading goals: ${snapshot.error}'),
              );
            }

            final goals = snapshot.data ?? [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernHeader(goals),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), // Increased bottom spacing for nav clearance
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildStatsSection(goals),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        _buildActiveGoalsSection(goals),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader(List<FirebaseGoal> goals) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlideAnimation.value),
            child: Opacity(
              opacity: _headerFadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), // Top padding for status bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile row - balanced layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App logo/name on the left for balance
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentIndigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: AppTheme.accentIndigo,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'BackMe',
                              style: TextStyle(
                                color: AppTheme.lightText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        // Achievements button on the right
                        GestureDetector(
                          onTap: () => _navigateToAchievements(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.warningGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.warningAmber.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Greeting and motivational message
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, ${_authService.userDisplayName}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightText,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getMotivationalMessage(goals),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Weekly overview card
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                      builder: (context, value, child) {
                        final activeGoals = goals.where((goal) => goal.status == GoalStatus.active).length;
                        final completedGoals = goals.where((goal) => goal.status == GoalStatus.completed).length;

                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: AppTheme.darkAccentGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.trending_up_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Weekly Progress',
                                          style: TextStyle(
                                            color: AppTheme.lightText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$activeGoals active goals • $completedGoals done',
                                          style: TextStyle(
                                            color: AppTheme.mutedText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '🔥 ${(completedGoals * 2.5).toInt()}%',
                                      style: TextStyle(
                                        color: AppTheme.successGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(List<FirebaseGoal> goals) {
    final activeGoals = goals.where((goal) => goal.status == GoalStatus.active).toList();
    final overdueGoals = goals.where((goal) => goal.isOverdue).toList();
    final completedGoals = goals.where((goal) => goal.status == GoalStatus.completed).toList();
    final totalStakes = activeGoals.fold(0.0, (sum, goal) => sum + goal.stakeAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentIndigo.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with trend indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.darkAccentGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Track your progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: AppTheme.successGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildCompactStatsCard(
                  'Active',
                  activeGoals.length.toString(),
                  Icons.radio_button_checked_rounded,
                  AppTheme.accentIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatsCard(
                  'Done',
                  completedGoals.length.toString(),
                  Icons.check_circle_rounded,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatsCard(
                  'Stakes',
                  '\$${totalStakes.toStringAsFixed(0)}',
                  Icons.attach_money_rounded,
                  AppTheme.warningAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatsCard(
                  'Overdue',
                  overdueGoals.length.toString(),
                  Icons.schedule_rounded,
                  AppTheme.errorRose,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Goal Achievement',
                      style: TextStyle(
                        color: AppTheme.lightText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${goals.isNotEmpty ? (completedGoals.length / goals.length * 100).toInt() : 0}%',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goals.isNotEmpty ? (completedGoals.length / goals.length) : 0.0,
                    backgroundColor: AppTheme.mutedText.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.darkAccentGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // First row of actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Create Goal',
                subtitle: 'Start your journey',
                icon: Icons.add_circle_outline_rounded,
                gradient: AppTheme.darkAccentGradient,
                onTap: () => _navigateToCreateGoal(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'View Progress',
                subtitle: 'Track goals',
                icon: Icons.trending_up_rounded,
                gradient: AppTheme.darkSuccessGradient,
                onTap: () => _navigateToGoals(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Second row of actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Set Reminders',
                subtitle: 'Stay on track',
                icon: Icons.notifications_rounded,
                gradient: AppTheme.warningGradient,
                onTap: () => _navigateToReminders(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Find Partners',
                subtitle: 'Get support',
                icon: Icons.people_rounded,
                gradient: AppTheme.primaryGradient,
                onTap: () => _navigateToPartners(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGoalsSection(List<FirebaseGoal> allGoals) {
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active).toList();

    if (activeGoals.isEmpty) {
      return _buildEmptyState();
    }

    // Determine how many goals to show
    final goalsToShow = _areGoalsExpanded ? activeGoals : activeGoals.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.darkSuccessGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${activeGoals.length} in progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToGoals(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.successGreen,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Goal cards with smooth expand/collapse animation
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: Column(
              children: [
                ...goalsToShow.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GoalCard(
                    goal: goal,
                    onTap: () => _navigateToGoalDetail(goal),
                    onProgressUpdate: (progress) => _updateGoalProgress(goal.id, progress),
                  ),
                )),
              ],
            ),
          ),
          
          // Show expand/collapse button only if there are more than 2 goals
          if (activeGoals.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _areGoalsExpanded = !_areGoalsExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _areGoalsExpanded 
                          ? AppTheme.successGreen.withValues(alpha: 0.1)
                          : AppTheme.darkSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _areGoalsExpanded
                            ? AppTheme.successGreen.withValues(alpha: 0.3)
                            : AppTheme.mutedText.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _areGoalsExpanded 
                              ? 'Show less' 
                              : '+${activeGoals.length - 2} more goals',
                          style: TextStyle(
                            color: _areGoalsExpanded 
                                ? AppTheme.successGreen
                                : AppTheme.mutedText,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _areGoalsExpanded ? 0.5 : 0.0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _areGoalsExpanded 
                                ? AppTheme.successGreen
                                : AppTheme.mutedText,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.accentIndigo.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
            TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.darkAccentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.track_changes_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      Text(
                        'Ready to Start?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your first accountability goal\nand begin your journey to success!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.darkAccentGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentIndigo.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToCreateGoal(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Create Your First Goal',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToCreateGoal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateGoalScreen(),
      ),
    ).then((_) {
      setState(() {
        // Refresh the dashboard when returning from create goal
      });
    });
  }

  void _navigateToGoalDetail(FirebaseGoal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goal: goal),
      ),
    ).then((_) {
      setState(() {
        // Refresh the dashboard when returning from goal detail
      });
    });
  }

  void _navigateToGoals() {
    // Switch to Goals tab (index 1) using parent HomeScreen callback
    if (widget.onTabSwitch != null) {
      widget.onTabSwitch!(1);
    }
  }

  void _navigateToPartners() {
    // Switch to Partners tab (index 2) using parent HomeScreen callback
    if (widget.onTabSwitch != null) {
      widget.onTabSwitch!(2);
    }
  }

  void _navigateToReminders() {
    // Navigate to dedicated RemindersScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RemindersScreen(),
      ),
    );
  }

  void _navigateToAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  void _updateGoalProgress(String goalId, double progress) async {
    try {
      await _goalService.updateProgress(goalId, progress);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating progress: $e')),
        );
      }
    }
  }
} 