import 'package:flutter/material.dart';

import '../data/models/activity_entry.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';

class ActivityVisual {
  const ActivityVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static ActivityVisual forType(ActivityType type) {
    switch (type) {
      case ActivityType.dibuat:
        return const ActivityVisual(
          icon: Icons.add_circle_outline_rounded,
          color: Color(0xFF2563EB),
        );
      case ActivityType.diperbarui:
        return const ActivityVisual(
          icon: Icons.edit_outlined,
          color: AppColors.primary,
        );
      case ActivityType.dihapus:
        return const ActivityVisual(
          icon: Icons.delete_outline_rounded,
          color: AppColors.danger,
        );
      case ActivityType.dipulihkan:
        return const ActivityVisual(
          icon: Icons.restore_rounded,
          color: Color(0xFF059669),
        );
      case ActivityType.diterbitkan:
        return const ActivityVisual(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
        );
      case ActivityType.ditarikDraft:
        return const ActivityVisual(
          icon: Icons.pause_circle_outline_rounded,
          color: AppColors.accent,
        );
      case ActivityType.diduplikasi:
        return const ActivityVisual(
          icon: Icons.copy_rounded,
          color: Color(0xFF7C3AED),
        );
    }
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.entry,
    this.onTap,
    this.dense = false,
  });

  final ActivityEntry entry;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = ActivityVisual.forType(entry.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 4 : 2,
          vertical: dense ? 9 : 11,
        ),
        child: Row(
          children: [
            Container(
              width: dense ? 34 : 38,
              height: dense ? 34 : 38,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                visual.icon,
                size: dense ? 17 : 19,
                color: visual.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.type.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: visual.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.judulModul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatWaktuRelatif(entry.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
