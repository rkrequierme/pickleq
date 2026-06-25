import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/glass_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start periodic timer to trigger UI rebuilds for active match clocks
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

    // If no active session, show the session start widget
    if (appState.activeSession == null) {
      return Center(
        child: SizedBox(
          width: 520,
          child: GlassCard(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.electricTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: AppTheme.electricTeal,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "NO ACTIVE SESSION",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Before registration, queueing, and match rotations can begin, you must open a daily session. This will initialize today's stats.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await appState.startNewSession();
                  },
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text("START DAILY SESSION"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shadowColor: AppTheme.neonLime.withOpacity(0.3),
                    elevation: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalRegistered = appState.allPlayers.length;
    final playersWaiting = appState.waitingQueue.length;
    final activeMatchesCount = appState.activeMatches.length;
    final availableCourtsCount = appState.courts.where((c) => c.status == 'available').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Welcome header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, ${appState.currentAdmin ?? 'Admin'}",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.electricTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Pickleball Dashboard",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              Text(
                "Today: ${appState.activeSession!.date}",
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stat Cards Grid
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            children: [
              StatCard(
                title: "Registered Players",
                value: "$totalRegistered",
                icon: Icons.people_alt,
                accentColor: AppTheme.electricTeal,
              ),
              StatCard(
                title: "Waiting in Queue",
                value: "$playersWaiting",
                icon: Icons.hourglass_empty,
                accentColor: AppTheme.neonLime,
              ),
              StatCard(
                title: "Active Matches",
                value: "$activeMatchesCount",
                icon: Icons.sports_tennis,
                accentColor: const Color(0xFFC77CFF),
              ),
              StatCard(
                title: "Available Courts",
                value: "$availableCourtsCount",
                icon: Icons.grid_view,
                accentColor: const Color(0xFF00FF85),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Courts Live Monitoring Panel
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "COURT MONITORING",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.courts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final court = appState.courts[index];
                        
                        // Find if there's an active match on this court
                        final matchIndex = appState.activeMatches.indexWhere((m) => m.courtId == court.id);
                        final hasMatch = matchIndex != -1;
                        final activeMatch = hasMatch ? appState.activeMatches[matchIndex] : null;

                        Color statusColor;
                        String statusText;
                        IconData statusIcon;

                        if (court.status == 'available') {
                          statusColor = const Color(0xFF00FF85);
                          statusText = "AVAILABLE";
                          statusIcon = Icons.check_circle_outline;
                        } else if (court.status == 'maintenance') {
                          statusColor = AppTheme.coralRed;
                          statusText = "MAINTENANCE";
                          statusIcon = Icons.build_outlined;
                        } else {
                          statusColor = AppTheme.electricTeal;
                          statusText = activeMatch?.type.toUpperCase() ?? "OCCUPIED";
                          statusIcon = Icons.play_arrow;
                        }

                        return GlassCard(
                          padding: const EdgeInsets.all(18),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 10, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
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
                                      // Render players list
                                      Text(
                                        activeMatch.players.map((p) => p.name).join(' • '),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatElapsedTime(activeMatch.startedAt),
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
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
                                      "Court offline for repair",
                                      style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 12),
                                    ),
                                  ),
                                )
                              ] else ...[
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      "Ready for assignment",
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                )
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Waiting Queue Preview Panel
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "UP NEXT (QUEUE PREVIEW)",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (appState.waitingQueue.isEmpty) ...[
                            const SizedBox(height: 60),
                            const Center(
                              child: Text(
                                "Queue is empty.\nRegister players to begin.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: appState.waitingQueue.length > 5 ? 5 : appState.waitingQueue.length,
                              separatorBuilder: (context, index) => const Divider(height: 16, color: AppTheme.borderMuted),
                              itemBuilder: (context, index) {
                                final player = appState.waitingQueue[index];
                                final diff = player.queueJoinedAt != null
                                    ? DateTime.now().difference(player.queueJoinedAt!)
                                    : Duration.zero;
                                
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: index < 4
                                          ? AppTheme.neonLime.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: index < 4 ? AppTheme.neonLime : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        player.name,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "${diff.inMinutes}m wait",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: index < 4 ? AppTheme.neonLime.withOpacity(0.8) : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (appState.waitingQueue.length > 5) ...[
                              const SizedBox(height: 12),
                              Text(
                                "+ ${appState.waitingQueue.length - 5} more waiting players",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ]
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
