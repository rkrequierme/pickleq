import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SessionView extends StatefulWidget {
  const SessionView({super.key});

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  bool _calculatingEod = false;
  Map<String, dynamic>? _summaryReport;

  Future<void> _generateSummary(AppStateProvider appState) async {
    setState(() {
      _calculatingEod = true;
    });

    try {
      final attendance = await appState.getAttendanceReport();
      final utilization = await appState.getCourtUtilizationStats();
      final queue = await appState.getQueueActivityReport();

      final totalMatches = queue.length;
      final totalPlayers = attendance.length;
      
      int totalMinutes = 0;
      for (final m in queue) {
        totalMinutes += ((m['duration_seconds'] as int? ?? 0) / 60).round();
      }

      setState(() {
        _summaryReport = {
          'date': appState.activeSession?.date ?? 'N/A',
          'matches': totalMatches,
          'players': totalPlayers,
          'totalMinutes': totalMinutes,
          'avgMinutes': totalMatches > 0 ? (totalMinutes / totalMatches).toStringAsFixed(1) : '0',
          'busyCourt': _getBusiestCourt(utilization),
        };
      });
    } catch (e) {
      debugPrint("Error compiling summary: $e");
    } finally {
      setState(() {
        _calculatingEod = false;
      });
    }
  }

  String _getBusiestCourt(List<Map<String, dynamic>> utilization) {
    if (utilization.isEmpty) return "None";
    
    double maxTime = -1;
    String busiest = "None";

    for (final row in utilization) {
      final double sec = (row['total_duration_seconds'] as num).toDouble();
      if (sec > maxTime) {
        maxTime = sec;
        busiest = row['name'] as String;
      }
    }
    return busiest;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    if (appState.activeSession == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: SizedBox(
            width: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_outlined, color: AppTheme.neonLime, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "START DAILY SESSION",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No operational session is currently open. Starting a session initializes today's database logs, tracking players and courts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.startNewSession();
                    },
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text("START SESSION NOW"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final session = appState.activeSession!;
    final startedTimeStr = DateFormat('hh:mm a').format(session.startedAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "END-OF-DAY OPERATIONS",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.electricTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Daily Session Control",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Status & Close Button
              Expanded(
                flex: 1,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Session Overview",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow("Operational Date", session.date),
                      const Divider(height: 24, color: AppTheme.borderMuted),
                      _buildInfoRow("Opened Today At", startedTimeStr),
                      const Divider(height: 24, color: AppTheme.borderMuted),
                      _buildInfoRow("Active Matches Running", "${appState.activeMatches.length}"),
                      const Divider(height: 24, color: AppTheme.borderMuted),
                      _buildInfoRow("Players Currently Waiting", "${appState.waitingQueue.length}"),
                      const SizedBox(height: 32),
                      
                      // Compile EOD Button
                      if (_summaryReport == null)
                        ElevatedButton.icon(
                          onPressed: () => _generateSummary(appState),
                          icon: const Icon(Icons.assignment_outlined, size: 16),
                          label: const Text("GENERATE END-OF-DAY SUMMARY"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricTeal,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: () => _showCloseSessionConfirm(context, appState),
                          icon: const Icon(Icons.power_settings_new, size: 16),
                          label: const Text("CLOSE SESSION & ARCHIVE DATA"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.coralRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _summaryReport = null;
                            });
                          },
                          child: const Center(
                            child: Text(
                              "RESET SUMMARY VIEW",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Generated EOD Daily Summary Report Preview
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DAILY SUMMARY PREVIEW",
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
                      child: _calculatingEod
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                          : _summaryReport == null
                              ? const SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: Text(
                                      "Click 'Generate End-of-Day Summary'\nto compile today's analytics.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "PickleQ EOD Summary",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonLime.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.neonLime.withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            _summaryReport!['date'] as String,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.neonLime,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildReportMetric("Total Unique Attendance", "${_summaryReport!['players']} players"),
                                    const SizedBox(height: 12),
                                    _buildReportMetric("Completed Rotations", "${_summaryReport!['matches']} matches"),
                                    const SizedBox(height: 12),
                                    _buildReportMetric("Busiest Court", "${_summaryReport!['busyCourt']}"),
                                    const SizedBox(height: 12),
                                    _buildReportMetric("Total Playtime Logged", "${_summaryReport!['totalMinutes']} min"),
                                    const SizedBox(height: 12),
                                    _buildReportMetric("Average Game Duration", "${_summaryReport!['avgMinutes']} min"),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.borderMuted.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 14, color: AppTheme.electricTeal),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Closing the session resets all players to 'inactive' and clears the waiting list to prepare for tomorrow.",
                                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
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
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReportMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showCloseSessionConfirm(BuildContext context, AppStateProvider appState) {
    final activeCount = appState.activeMatches.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Close Session & End Day"),
          content: Text(
            "Are you sure you want to shut down operations for today?\n\n"
            "${activeCount > 0 ? 'WARNING: There are currently $activeCount active matches running. Closing the session will immediately stop all ongoing games, calculate and record their durations, and make courts available.\n\n' : ''}"
            "This process archives today's logs and sets all players to inactive. You will need to start a new session tomorrow.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await appState.endCurrentSession();
                setState(() {
                  _summaryReport = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Session closed successfully. Daily logs archived."),
                    backgroundColor: AppTheme.neonLime,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
              child: const Text("CLOSE SESSION & LOG OUT EOD", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
