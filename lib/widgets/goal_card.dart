import 'package:flutter/material.dart';
import '../models/firebase_goal.dart';
import '../models/firebase_partner.dart';
import '../services/firebase_partner_service.dart';
import '../services/firebase_goal_service.dart';
import '../main.dart';

class GoalCard extends StatefulWidget {
  final FirebaseGoal goal;
  final VoidCallback? onTap;
  final Function(double)? onProgressUpdate;
  final bool showPartners;
  final bool isCompact;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onProgressUpdate,
    this.showPartners = true,
    this.isCompact = false,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FirebasePartnerService _partnerService = FirebasePartnerService();
  List<UserProfile> _partners = [];
  bool _isLoadingPartners = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showPartners && widget.goal.partnerIds.isNotEmpty) {
      _loadPartners();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    if (widget.goal.partnerIds.isEmpty) return;
    
    setState(() {
      _isLoadingPartners = true;
    });

    try {
      final partners = <UserProfile>[];
      for (final partnerId in widget.goal.partnerIds) {
        final partner = await _partnerService.getUserProfile(partnerId);
        if (partner != null) {
          partners.add(partner);
        }
      }
      setState(() {
        _partners = partners;
      });
    } catch (e) {
      print('Error loading partners: $e');
    } finally {
      setState(() {
        _isLoadingPartners = false;
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
            border: Border.all(
              color: widget.goal.categoryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.goal.categoryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: widget.isCompact ? 8 : 12),
                _buildProgress(),
                if (!widget.isCompact) ...[
                  const SizedBox(height: 12),
                  _buildDetails(),
                ],
                if (widget.showPartners && widget.goal.partnerIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPartners(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Category icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.goal.categoryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.goal.categoryIcon,
            color: widget.goal.categoryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        
        // Title and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.goal.title,
                style: TextStyle(
                  color: AppTheme.lightText,
                  fontSize: widget.isCompact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: widget.isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!widget.isCompact) ...[
                const SizedBox(height: 4),
                Text(
                  widget.goal.description,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Status indicators
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusBadge(),
            if (widget.goal.stakeAmount > 0) ...[
              const SizedBox(height: 4),
              _buildStakeBadge(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (widget.goal.status) {
      case GoalStatus.completed:
        color = AppTheme.successGreen;
        text = 'Done';
        icon = Icons.check_circle;
        break;
      case GoalStatus.paused:
        color = AppTheme.warningAmber;
        text = 'Paused';
        icon = Icons.pause_circle;
        break;
      case GoalStatus.cancelled:
        color = AppTheme.errorRose;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      case GoalStatus.active:
      default:
        if (widget.goal.isOverdue) {
          color = AppTheme.errorRose;
          text = 'Overdue';
          icon = Icons.schedule;
        } else {
          color = AppTheme.accentIndigo;
          text = 'Active';
          icon = Icons.play_circle;
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '\$${widget.goal.stakeAmount.toStringAsFixed(0)}',
        style: TextStyle(
          color: AppTheme.warningAmber,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final progressPercentage = widget.goal.progressPercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.goal.currentProgress.toStringAsFixed(widget.goal.currentProgress == widget.goal.currentProgress.roundToDouble() ? 0 : 1)} / ${widget.goal.targetValue.toStringAsFixed(widget.goal.targetValue == widget.goal.targetValue.roundToDouble() ? 0 : 1)} ${widget.goal.unit}',
              style: TextStyle(
                color: AppTheme.lightText,
                fontSize: widget.isCompact ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progressPercentage * 100).toInt()}%',
              style: TextStyle(
                color: widget.goal.categoryColor,
                fontSize: widget.isCompact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        Container(
          height: widget.isCompact ? 6 : 8,
          decoration: BoxDecoration(
            color: AppTheme.mutedText.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressPercentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.goal.categoryColor,
                    widget.goal.categoryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: widget.goal.categoryColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Quick update buttons
        if (widget.onProgressUpdate != null && widget.goal.status == GoalStatus.active) ...[
          const SizedBox(height: 8),
          _buildQuickUpdateButtons(),
        ],
      ],
    );
  }

  Widget _buildQuickUpdateButtons() {
    final step = FirebaseGoalService.getSmartIncrement(widget.goal.targetValue);
    final currentProgress = widget.goal.currentProgress;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentProgress > 0)
          _buildQuickButton(
            icon: Icons.remove,
            onTap: () => widget.onProgressUpdate!(
              (currentProgress - step).clamp(0, widget.goal.targetValue)
            ),
            color: AppTheme.errorRose,
          ),
        const Spacer(),
        if (currentProgress < widget.goal.targetValue)
          _buildQuickButton(
            icon: Icons.add,
            onTap: () => widget.onProgressUpdate!(
              (currentProgress + step).clamp(0, widget.goal.targetValue)
            ),
            color: AppTheme.successGreen,
          ),
      ],
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        if (widget.goal.endDate != null) ...[
          Icon(
            Icons.schedule,
            color: widget.goal.isOverdue ? AppTheme.errorRose : AppTheme.mutedText,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            widget.goal.daysRemaining >= 0 
                ? '${widget.goal.daysRemaining} days left'
                : '${widget.goal.daysRemaining.abs()} days overdue',
            style: TextStyle(
              color: widget.goal.isOverdue ? AppTheme.errorRose : AppTheme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        Icon(
          Icons.category,
          color: AppTheme.mutedText,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          widget.goal.category.name.toUpperCase(),
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPartners() {
    if (_isLoadingPartners) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentIndigo),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading partners...',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_partners.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.person_add,
            color: AppTheme.mutedText,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'No partners yet',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.people,
          color: AppTheme.accentIndigo,
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: [
              // Partner avatars
              ...(_partners.take(3).map((partner) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: AppTheme.accentIndigo.withValues(alpha: 0.2),
                  backgroundImage: partner.photoUrl != null 
                      ? NetworkImage(partner.photoUrl!) 
                      : null,
                  child: partner.photoUrl == null
                      ? Text(
                          partner.displayName.isNotEmpty 
                              ? partner.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.accentIndigo,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ))),
              
              // Partners text
              if (_partners.length <= 3)
                Text(
                  _partners.length == 1 
                      ? _partners.first.displayName
                      : '${_partners.length} partners',
                  style: TextStyle(
                    color: AppTheme.accentIndigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  '${_partners.length} partners',
                  style: TextStyle(
                    color: AppTheme.accentIndigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 