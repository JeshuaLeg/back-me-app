import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';
import '../main.dart';
import '../utils/date_formatter.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();

  @override
  void initState() {
    super.initState();
    // The achievements are already initialized in the service constructor
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.lightText,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Achievements',
          style: TextStyle(
            color: AppTheme.lightText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
        child: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _buildLevelSection(),
                _buildTabBar(),
                Expanded(child: _buildAchievementsGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLevelSection() {
    final userLevel = _achievementService.currentUserLevel;
    final achievements = _achievementService.unlockedAchievements;

    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Level Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentIndigo,
                  AppTheme.accentIndigo.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${userLevel.level}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          userLevel.title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Points: ${userLevel.currentPoints} / ${userLevel.pointsRequired}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: userLevel.progressToNext,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Points',
                  '${_achievementService.totalPoints}',
                  Icons.star,
                  AppTheme.warningAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Unlocked',
                  '${achievements.length}',
                  Icons.emoji_events,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Level',
                  '${_achievementService.currentLevel}',
                  Icons.trending_up,
                  AppTheme.accentIndigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppTheme.accentIndigo,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.mutedText,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unlocked'),
          Tab(text: 'Locked'),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: TabBarView(
        children: [
          _buildAchievementsList(_achievementService.achievements),
          _buildAchievementsList(_achievementService.unlockedAchievements),
          _buildAchievementsList(_achievementService.achievements.where((a) => !a.isUnlocked).toList()),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppTheme.mutedText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements here yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete goals to unlock achievements!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), // Add bottom padding for nav bar
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Significantly increased for much more height
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progressPercentage;
    
    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        padding: const EdgeInsets.all(12), // Further reduced from 16
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked 
                ? AppTheme.successGreen.withValues(alpha: 0.3)
                : AppTheme.mutedText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // Further reduced from 10
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? AppTheme.successGreen.withValues(alpha: 0.2)
                        : AppTheme.mutedText.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8), // Reduced from 10
                  ),
                  child: Icon(
                    achievement.icon,
                    color: isUnlocked ? AppTheme.successGreen : AppTheme.mutedText,
                    size: 20, // Further reduced from 22
                  ),
                ),
                _buildRarityBadge(achievement.rarity),
              ],
            ),
            const SizedBox(height: 10), // Further reduced from 12
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 14, // Further reduced from 15
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppTheme.lightText : AppTheme.mutedText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Further reduced from 6
            Expanded( // Changed from Text widget to Expanded to be more flexible
              flex: 3,
              child: Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 10, // Further reduced from 11
                  color: AppTheme.mutedText,
                ),
                maxLines: 2, // Reduced from 3
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Bottom section with minimal spacing
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Use minimum space needed
              children: [
                if (!isUnlocked && progress > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 8, // Further reduced from 9
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 8, // Further reduced from 9
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2), // Further reduced from 3
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.mutedText.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo),
                    minHeight: 2, // Further reduced from 3
                  ),
                  const SizedBox(height: 4), // Further reduced from 6
                ],
                Row(
                  children: [
                    Text(
                      '${achievement.points} Points',
                      style: TextStyle(
                        fontSize: 10, // Further reduced from 11
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                    if (isUnlocked && achievement.unlockedAt != null) ...[
                      const SizedBox(width: 4), // Further reduced from 6
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), // Further reduced padding
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3), // Further reduced from 4
                          ),
                          child: Text(
                            DateFormatter.formatTimeAgo(achievement.unlockedAt!),
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 7, // Further reduced from 8
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Further reduced padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4), // Reduced border radius
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8, // Further reduced font size
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progressPercentage;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnlocked 
                          ? AppTheme.successGreen.withValues(alpha: 0.2)
                          : AppTheme.mutedText.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      achievement.icon,
                      color: isUnlocked ? AppTheme.successGreen : AppTheme.mutedText,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRarityBadge(achievement.rarity),
                            const SizedBox(width: 12),
                            Text(
                              '${achievement.points} Points',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (!isUnlocked && progress > 0) ...[
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    Text(
                      '${achievement.progress.toInt()}/${achievement.target}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.mutedText.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo),
                  minHeight: 8,
                ),
                const SizedBox(height: 24),
              ],
              if (isUnlocked && achievement.unlockedAt != null) ...[
                Text(
                  'Unlocked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.successGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Unlocked ${DateFormatter.formatTimeAgo(achievement.unlockedAt!)}',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(color: AppTheme.mutedText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 