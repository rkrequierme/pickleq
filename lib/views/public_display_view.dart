import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class PublicDisplayView extends StatefulWidget {
  final VoidCallback onClose;

  const PublicDisplayView({super.key, required this.onClose});

  @override
  State<PublicDisplayView> createState() => _PublicDisplayViewState();
}

class _PublicDisplayViewState extends State<PublicDisplayView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start periodic timer to update active match timers
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsedTime(DateTime startedAt) {
    final diff = DateTime.now().difference(startedAt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    String pad(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return "${pad(hours)}:${pad(minutes)}:${pad(seconds)}";
    }
    return "${pad(minutes)}:${pad(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final size = MediaQuery.of(context).size;

    return Container(
      color: Colors.black, // Darkest background for high contrast
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.neonLime, width: 2),
                    ),
                    child: const Icon(Icons.sports_tennis, color: AppTheme.neonLime, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "PickleQ • COURT ROTATIONS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Exit Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 28),
                tooltip: 'Exit Public View',
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Main layout content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Active Court Grid
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.borderMuted.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "ONGOING MATCHES",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.electricTeal,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          itemCount: appState.courts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.3,
                          ),
                          itemBuilder: (context, index) {
                            final court = appState.courts[index];
                            final matchIndex = appState.activeMatches.indexWhere((m) => m.courtId == court.id);
                            final hasMatch = matchIndex != -1;
                            final activeMatch = hasMatch ? appState.activeMatches[matchIndex] : null;

                            Color cardBg = const Color(0xFF11141B);
                            Color accentColor;
                            String statusText;

                            if (court.status == 'available') {
                              accentColor = const Color(0xFF00FF85);
                              statusText = "AVAILABLE";
                            } else if (court.status == 'maintenance') {
                              accentColor = AppTheme.coralRed;
                              statusText = "MAINTENANCE";
                            } else {
                              accentColor = AppTheme.electricTeal;
                              statusText = activeMatch?.type.toUpperCase() ?? "OCCUPIED";
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: court.status == 'occupied'
                                      ? AppTheme.electricTeal.withOpacity(0.4)
                                      : court.status == 'maintenance'
                                          ? AppTheme.coralRed.withOpacity(0.3)
                                          : const Color(0xFF00FF85).withOpacity(0.2),
                                  width: court.status == 'occupied' ? 2 : 1,
                                ),
                                boxShadow: court.status == 'occupied'
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.electricTeal.withOpacity(0.08),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        court.name,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (court.status == 'occupied' && activeMatch != null) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            activeMatch.players.map((p) => p.name).join('  •  '),
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.timer, size: 16, color: AppTheme.neonLime),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatElapsedTime(activeMatch.startedAt),
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.neonLime,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ] else if (court.status == 'maintenance') ...[
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          "OFFLINE FOR MAINTENANCE",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            color: Colors.white38,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    )
                                  ] else ...[
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          "READY FOR GAME",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            color: const Color(0xFF00FF85).withOpacity(0.5),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                // Right Panel: Waiting Queue View
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.borderMuted.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "UPCOMING PLAYERS (QUEUE)",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neonLime,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1218),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderMuted),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: appState.waitingQueue.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Queue is empty.\nRegister at the front desk.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white30,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: appState.waitingQueue.length,
                                  separatorBuilder: (context, idx) => const Divider(
                                    height: 20,
                                    color: AppTheme.borderMuted,
                                    thickness: 1,
                                  ),
                                  itemBuilder: (context, idx) {
                                    final player = appState.waitingQueue[idx];
                                    final waitDiff = player.queueJoinedAt != null
                                        ? DateTime.now().difference(player.queueJoinedAt!)
                                        : Duration.zero;

                                    return Row(
                                      children: [
                                        // Large Queue number badge
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: idx < 4
                                                ? AppTheme.neonLime
                                                : Colors.white.withOpacity(0.05),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${idx + 1}",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: idx < 4 ? Colors.black : Colors.white60,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Player Name
                                        Expanded(
                                          child: Text(
                                            player.name,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Wait Time
                                        Text(
                                          "${waitDiff.inMinutes}m wait",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: idx < 4
                                                ? AppTheme.neonLime.withOpacity(0.8)
                                                : Colors.white38,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
