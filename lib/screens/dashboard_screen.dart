import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/goal_service.dart';
import '../models/reminder_service.dart';
import '../widgets/goal_card.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../main.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';
import 'achievements_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final GoalService _goalService = GoalService();
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  final AchievementService _achievementService = AchievementService();
  late AnimationController _fabAnimation;
  late AnimationController _headerAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

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
    
    // Initialize reminder service with sample data
    _reminderService.initializeWithSampleData();
    
    // Initialize achievement service with goal data
    _achievementService.initializeWithGoalData(_goalService.goals);
  }

  @override
  void dispose() {
    _fabAnimation.dispose();
    _headerAnimation.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalMessage() {
    final activeGoals = _goalService.activeGoals.length;
    final completedGoals = _goalService.completedGoals.length;
    
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
              AppTheme.primarySlate.withOpacity(0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), // Increased bottom spacing for nav clearance
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildStatsSection(),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildActiveGoalsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
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
                                color: AppTheme.accentIndigo.withOpacity(0.1),
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
                        // Achievement gem button on the right
                        GestureDetector(
                          onTap: () => _navigateToAchievements(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.darkAccentGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentIndigo.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.diamond_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Greeting and motivation
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.darkAccentGradient.createShader(bounds),
                      child: Text(
                        _authService.userDisplayName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      _getMotivationalMessage(),
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentIndigo.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppTheme.darkAccentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                  '${_goalService.activeGoals.length} active goals • ${_goalService.completedGoals.length} done',
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🔥 ${(_goalService.completedGoals.length * 2.5).toInt()}%',
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    final activeGoals = _goalService.activeGoals;
    final overdueGoals = _goalService.overdueGoals;
    final completedGoals = _goalService.completedGoals;
    final totalStakes = _goalService.totalStakesAtRisk;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentIndigo.withOpacity(0.1),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.darkAccentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentIndigo.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Last 7 days',
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
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppTheme.successGreen,
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
          
          // Main stats in single row for better use of space
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
              color: AppTheme.darkSurface.withOpacity(0.4),
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
                      '${(completedGoals.length / (activeGoals.length + completedGoals.length) * 100).toInt()}%',
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
                    value: (completedGoals.length / (activeGoals.length + completedGoals.length + 1)),
                    backgroundColor: AppTheme.mutedText.withOpacity(0.2),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.lightText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
                        color: AppTheme.accentIndigo.withOpacity(0.3),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '2',
                style: TextStyle(
                  color: AppTheme.accentIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Action cards in grid layout
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
        
        // Additional actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Set Reminders',
                subtitle: 'Stay on track',
                icon: Icons.notifications_active_rounded,
                gradient: AppTheme.warningGradient,
                onTap: () => _showRemindersDialog(),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentIndigo.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: gradient.begin,
                      end: gradient.end,
                      colors: gradient.colors.map((color) => color.withOpacity(0.8)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGoalsSection() {
    final activeGoals = _goalService.activeGoals;

    if (activeGoals.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.1),
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
                          color: AppTheme.successGreen.withOpacity(0.3),
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
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
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
          // Goal cards without complex animations
          ...activeGoals.take(2).map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalCard(
              goal: goal,
              onTap: () => _navigateToGoalDetail(goal),
              onProgressUpdate: (progress) => _updateGoalProgress(goal.id, progress),
            ),
          )).toList(),
          if (activeGoals.length > 2) ...[
            const SizedBox(height: 4), // Reduced spacing
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToGoals(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.mutedText.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${activeGoals.length - 2} more goals',
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.mutedText,
                          size: 16,
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.accentIndigo.withOpacity(0.15),
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
                        color: AppTheme.accentIndigo.withOpacity(0.3),
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
                        color: AppTheme.accentIndigo.withOpacity(0.4),
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
                                color: Colors.white.withOpacity(0.2),
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

  void _navigateToGoalDetail(Goal goal) {
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
    // Switch to goals tab in the parent HomeScreen
    // Since we're using a BottomNavigationBar, we need to communicate with parent
    // For now, we'll show a message to use the navigation bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Use the Goals tab in the bottom navigation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentIndigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToPartners() {
    // Switch to partners tab in the parent HomeScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Use the Partners tab in the bottom navigation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentIndigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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

  void _updateGoalProgress(String goalId, double progress) {
    setState(() {
      _goalService.updateProgress(goalId, progress);
      // Update achievement service with new goal data
      _achievementService.initializeWithGoalData(_goalService.goals);
    });
  }

  void _showRemindersDialog() {
    final upcomingReminders = _reminderService.upcomingReminders;
    final stats = _reminderService.stats;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.accentIndigo.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkAccentGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Reminders',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${stats.active} active • ${stats.today} today',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stats Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildReminderStat(
                        'Today',
                        stats.today.toString(),
                        Icons.today_rounded,
                        AppTheme.accentIndigo,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.mutedText.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildReminderStat(
                        'Active',
                        stats.active.toString(),
                        Icons.check_circle_rounded,
                        AppTheme.successGreen,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.mutedText.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildReminderStat(
                        'Overdue',
                        stats.overdue.toString(),
                        Icons.warning_rounded,
                        AppTheme.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: upcomingReminders.isEmpty
                    ? _buildNoRemindersState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: upcomingReminders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final schedule = upcomingReminders[index];
                          return _buildReminderScheduleCard(schedule);
                        },
                      ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to reminder management screen (future feature)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reminder management coming soon!'),
                          backgroundColor: AppTheme.accentIndigo,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.settings_rounded, size: 18),
                    label: Text('Manage Reminders'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.lightText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoRemindersState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 48,
              color: AppTheme.accentIndigo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Upcoming Reminders',
            style: TextStyle(
              color: AppTheme.lightText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a goal to set up reminders',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderScheduleCard(schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentIndigo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentIndigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.formattedDate,
                  style: TextStyle(
                    color: AppTheme.accentIndigo,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${schedule.reminders.length} reminder${schedule.reminders.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...schedule.reminders.map<Widget>((reminder) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.mutedText,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reminder.getFormattedTime(),
                    style: TextStyle(
                      color: AppTheme.lightText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 