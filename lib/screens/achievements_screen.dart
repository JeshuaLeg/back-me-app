import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../main.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> 
    with TickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAchievementsTab(),
                    _buildRewardsTab(),
                    _buildLevelTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUserStats(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserStats() {
    final userLevel = _achievementService.currentUserLevel;
    final unlockedCount = _achievementService.unlockedAchievements.length;
    final totalCount = _achievementService.achievements.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.darkAccentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Level',
                '${_achievementService.currentLevel}',
                Icons.trending_up_rounded,
                Colors.white,
              ),
              _buildStatItem(
                'Points',
                '${_achievementService.totalPoints}',
                Icons.star_rounded,
                Colors.white,
              ),
              _buildStatItem(
                'Achievements',
                '$unlockedCount/$totalCount',
                Icons.emoji_events_rounded,
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: _achievementService.userTitleColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _achievementService.userTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentIndigo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          gradient: AppTheme.darkAccentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentIndigo.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.mutedText,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Badges'),
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Rewards'),
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Level'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = _achievementService.achievements;
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.isUnlocked).toList();
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          _buildSectionHeader('Unlocked', unlockedAchievements.length),
          const SizedBox(height: 12),
          ...unlockedAchievements.map((achievement) => 
            _buildAchievementCard(achievement, isUnlocked: true)),
          const SizedBox(height: 32),
        ],
        if (lockedAchievements.isNotEmpty) ...[
          _buildSectionHeader('Locked', lockedAchievements.length),
          const SizedBox(height: 12),
          ...lockedAchievements.map((achievement) => 
            _buildAchievementCard(achievement, isUnlocked: false)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title == 'Unlocked' ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: AppTheme.accentIndigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentIndigo.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: AppTheme.accentIndigo,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, {required bool isUnlocked}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(isUnlocked ? 0.8 : 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked 
              ? achievement.color.withOpacity(0.4) 
              : AppTheme.mutedText.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: achievement.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? achievement.color.withOpacity(0.2) 
                        : AppTheme.mutedText.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked 
                          ? achievement.color.withOpacity(0.3) 
                          : AppTheme.mutedText.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: isUnlocked ? achievement.color : AppTheme.mutedText,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? AppTheme.lightText : AppTheme.mutedText,
                              ),
                            ),
                          ),
                          _buildRarityBadge(achievement.rarity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnlocked 
                              ? AppTheme.mutedText 
                              : AppTheme.mutedText.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 16),
              _buildProgressBar(achievement),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningAmber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppTheme.warningAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.points} pts',
                        style: TextStyle(
                          color: AppTheme.warningAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnlocked && achievement.unlockedAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(AchievementRarity rarity) {
    Color color;
    String text;
    
    switch (rarity) {
      case AchievementRarity.common:
        color = AppTheme.mutedText;
        text = 'Common';
        break;
      case AchievementRarity.uncommon:
        color = AppTheme.successGreen;
        text = 'Uncommon';
        break;
      case AchievementRarity.rare:
        color = AppTheme.accentIndigo;
        text = 'Rare';
        break;
      case AchievementRarity.epic:
        color = Colors.purple;
        text = 'Epic';
        break;
      case AchievementRarity.legendary:
        color = Colors.orange;
        text = 'Legendary';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressBar(Achievement achievement) {
    final progress = achievement.progressPercentage.clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.mutedText.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: AppTheme.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${achievement.progress.toInt()}/${achievement.target}',
                style: TextStyle(
                  color: achievement.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.mutedText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * progress * 0.7, // Approximate available width
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      achievement.color,
                      achievement.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    final availableRewards = _achievementService.availableRewards;
    final unlockedRewards = _achievementService.unlockedRewards;
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _buildPointsBalance(),
        const SizedBox(height: 32),
        if (unlockedRewards.isNotEmpty) ...[
          _buildSectionHeader('Your Rewards', unlockedRewards.length),
          const SizedBox(height: 12),
          ...unlockedRewards.map((reward) => 
            _buildRewardCard(reward, isUnlocked: true)),
          const SizedBox(height: 32),
        ],
        _buildSectionHeader('Available Rewards', availableRewards.length),
        const SizedBox(height: 12),
        ...availableRewards.map((reward) => 
          _buildRewardCard(reward, isUnlocked: false)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPointsBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningAmber.withOpacity(0.8),
            AppTheme.warningAmber.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_achievementService.totalPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Reward reward, {required bool isUnlocked}) {
    final canAfford = _achievementService.totalPoints >= reward.pointsRequired;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(isUnlocked ? 0.8 : canAfford ? 0.6 : 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked 
              ? reward.color.withOpacity(0.4) 
              : canAfford 
                  ? reward.color.withOpacity(0.3)
                  : AppTheme.mutedText.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: isUnlocked || canAfford ? [
          BoxShadow(
            color: reward.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? reward.color.withOpacity(0.2) 
                        : canAfford 
                            ? reward.color.withOpacity(0.15)
                            : AppTheme.mutedText.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked 
                          ? reward.color.withOpacity(0.3) 
                          : canAfford 
                              ? reward.color.withOpacity(0.2)
                              : AppTheme.mutedText.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    reward.icon,
                    color: isUnlocked 
                        ? reward.color 
                        : canAfford 
                            ? reward.color.withOpacity(0.8)
                            : AppTheme.mutedText,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked 
                              ? AppTheme.lightText 
                              : canAfford 
                                  ? AppTheme.lightText 
                                  : AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnlocked 
                              ? AppTheme.mutedText 
                              : canAfford 
                                  ? AppTheme.mutedText 
                                  : AppTheme.mutedText.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningAmber.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.warningAmber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.pointsRequired} pts',
                            style: TextStyle(
                              color: AppTheme.warningAmber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: reward.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reward.category,
                        style: TextStyle(
                          color: reward.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked && canAfford)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [reward.color, reward.color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: reward.color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Claim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Claimed',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTab() {
    final currentLevel = _achievementService.currentUserLevel;
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _buildCurrentLevelCard(currentLevel),
        const SizedBox(height: 32),
        _buildLevelProgressSection(),
        const SizedBox(height: 32),
        _buildPerksSection(currentLevel),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCurrentLevelCard(UserLevel level) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            level.color.withOpacity(0.8),
            level.color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Level ${level.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            level.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep earning points to unlock higher levels!',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerksSection(UserLevel level) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Perks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 16),
          ...level.perks.map((perk) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    perk,
                    style: TextStyle(
                      color: AppTheme.lightText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
} 