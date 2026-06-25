import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class QueueListTile extends StatelessWidget {
  final Player player;
  final int index;
  final VoidCallback onSkip;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const QueueListTile({
    super.key,
    required this.player,
    required this.index,
    required this.onSkip,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  String _formatWaitTime(DateTime? joinedTime) {
    if (joinedTime == null) return "Waiting";
    final diff = DateTime.now().difference(joinedTime);
    if (diff.inMinutes < 1) {
      return "Just joined";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return "${hours}h ${minutes}m ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitText = _formatWaitTime(player.queueJoinedAt);
    final posText = "#${index + 1}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        color: AppTheme.slateCard,
        radius: 12,
        borderWidth: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Ranking Glow Circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: index < 4
                      ? [AppTheme.neonLime, AppTheme.electricTeal]
                      : [AppTheme.borderMuted, AppTheme.borderMuted],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: index < 4
                    ? [
                        BoxShadow(
                          color: AppTheme.neonLime.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                posText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: index < 4 ? Colors.black : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Player details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 12,
                        color: index < 4 ? AppTheme.neonLime : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waitText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: index < 4 ? AppTheme.neonLime.withOpacity(0.8) : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Rearrangement controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  color: onMoveUp != null ? AppTheme.textSecondary : AppTheme.borderMuted,
                  tooltip: 'Move Up',
                  onPressed: onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  color: onMoveDown != null ? AppTheme.textSecondary : AppTheme.borderMuted,
                  tooltip: 'Move Down',
                  onPressed: onMoveDown,
                ),
                const SizedBox(width: 8),
                // Skip Button
                TextButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.redo, size: 14),
                  label: const Text("Skip"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.electricTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                // Remove Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.coralRed),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
