import 'package:flutter/material.dart';
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

  Widget _buildSkillBadge(String skillLevel) {
    Color badgeColor;
    String label;
    if (skillLevel == 'beginner') {
      badgeColor = Colors.blue;
      label = "BEG";
    } else if (skillLevel == 'advanced') {
      badgeColor = Colors.orange;
      label = "ADV";
    } else {
      badgeColor = Colors.green;
      label = "INT";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waitText = _formatWaitTime(player.queueJoinedAt);
    final posText = "#${index + 1}";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderMuted, width: 1),
      ),
      color: AppTheme.slateCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Standard M3 ranking badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < 4 ? AppTheme.neonLime : AppTheme.borderMuted,
              ),
              alignment: Alignment.center,
              child: Text(
                posText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
                  Row(
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSkillBadge(player.skillLevel),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11,
                        color: index < 4 ? AppTheme.neonLime : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waitText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: index < 4 ? AppTheme.neonLime : AppTheme.textSecondary,
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
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: onMoveUp != null ? AppTheme.textSecondary : AppTheme.borderMuted.withOpacity(0.3),
                  tooltip: 'Move Up',
                  onPressed: onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  color: onMoveDown != null ? AppTheme.textSecondary : AppTheme.borderMuted.withOpacity(0.3),
                  tooltip: 'Move Down',
                  onPressed: onMoveDown,
                ),
                const SizedBox(width: 4),
                // Skip Button
                TextButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.redo, size: 12),
                  label: const Text("Skip"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.electricTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                // Remove Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.coralRed),
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
