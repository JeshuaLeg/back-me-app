import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final Function(double)? onProgressUpdate;
  final bool showOverdueBadge;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onProgressUpdate,
    this.showOverdueBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            if (showOverdueBadge || goal.isOverdue) _buildOverdueBanner(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildDescription(context),
                  const SizedBox(height: 16),
                  _buildProgressSection(context),
                  const SizedBox(height: 12),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'OVERDUE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: goal.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            goal.categoryIcon,
            color: goal.statusColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                goal.categoryDisplayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: goal.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (goal.stakeAmount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$${goal.stakeAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      goal.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(goal.progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: goal.statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: goal.progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
        ),
        if (onProgressUpdate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: goal.progress,
                  onChanged: onProgressUpdate,
                  activeColor: goal.statusColor,
                  divisions: 10,
                  label: '${(goal.progress * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          goal.daysRemaining > 0 
              ? '${goal.daysRemaining} days left'
              : 'Due today',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: goal.isOverdue 
                ? Colors.red 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        if (goal.accountabilityPartners.isNotEmpty) ...[
          Icon(
            Icons.people,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${goal.accountabilityPartners.length} partner${goal.accountabilityPartners.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
} 