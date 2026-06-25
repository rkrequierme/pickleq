import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  String _formatDateTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "0s";
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min == 0) return "${sec}s";
    return "${min}m ${sec}s";
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final history = appState.completedMatches;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0), // Main layout takes care of padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "COMPLETED MATCH LOGS",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: history.isEmpty
                ? GlassCard(
                    child: const Center(
                      child: Text(
                        "No completed matches recorded yet.",
                        style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Inter'),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final match = history[index];
                      final dateStr = DateFormat('EEEE, MMM dd').format(match.startedAt);
                      final startStr = _formatDateTime(match.startedAt);
                      final endStr = match.endedAt != null ? _formatDateTime(match.endedAt!) : '';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.glassCard(
                          color: AppTheme.slateCard,
                          radius: 12,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Court Badge
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.neonLime.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.neonLime.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  match.courtName?.replaceAll("Court ", "#") ?? "#${match.courtId}",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.neonLime,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Match details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.players.map((p) => p.name).join(', '),
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.electricTeal.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            match.type.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.electricTeal,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "$dateStr • $startStr - $endStr",
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Duration
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "DURATION",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(match.durationSeconds),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.neonLime,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
