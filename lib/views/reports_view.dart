import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_charts.dart';
import 'history_view.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _courtData = [];
  List<Map<String, dynamic>> _queueData = [];
  bool _loadingReports = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchReportsData();
  }

  Future<void> _fetchReportsData() async {
    setState(() {
      _loadingReports = true;
    });

    final appState = Provider.of<AppStateProvider>(context, listen: false);

    try {
      final attendance = await appState.getAttendanceReport();
      final courts = await appState.getCourtUtilizationStats();
      final queue = await appState.getQueueActivityReport();

      if (mounted) {
        setState(() {
          _attendanceData = attendance;
          _courtData = courts;
          _queueData = queue;
        });
      }
    } catch (e) {
      debugPrint("Error loading reports data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingReports = false;
        });
      }
    }
  }

  // Helper to compile data for Bar Chart (top players by games played)
  Map<String, double> _getTopPlayersBarData() {
    final Map<String, double> data = {};
    
    // Sort players by games played descending
    final sorted = List<Map<String, dynamic>>.from(_attendanceData);
    sorted.sort((a, b) => (b['games_played'] as int).compareTo(a['games_played'] as int));

    // Get top 6
    final top = sorted.take(6).toList();
    for (final p in top) {
      data[p['name'] as String] = (p['games_played'] as int).toDouble();
    }
    return data;
  }

  // Helper to compile data for Court Donut Chart (duration seconds per court)
  Map<String, double> _getCourtDonutData() {
    final Map<String, double> data = {};
    for (final c in _courtData) {
      final double sec = (c['total_duration_seconds'] as num).toDouble();
      data[c['name'] as String] = sec > 0 ? sec : 0.001; // Avoid exact zero to make rendering easier
    }
    return data;
  }

  // Helper to compile queue activity hourly points
  Map<String, List<dynamic>> _getHourlyActivityData() {
    // Generate list of 8 primary operating hours (e.g. 8 AM - 4 PM)
    final Map<String, double> hourlyCounts = {
      '08 AM': 0, '09 AM': 0, '10 AM': 0, '11 AM': 0,
      '12 PM': 0, '01 PM': 0, '02 PM': 0, '03 PM': 0,
      '04 PM': 0, '05 PM': 0, '06 PM': 0, '07 PM': 0,
      '08 PM': 0,
    };

    for (final m in _queueData) {
      final endedAtStr = m['ended_at'] as String?;
      if (endedAtStr == null) continue;

      final dt = DateTime.parse(endedAtStr);
      final hourStr = DateFormat('hh a').format(dt);
      
      if (hourlyCounts.containsKey(hourStr)) {
        hourlyCounts[hourStr] = hourlyCounts[hourStr]! + 1;
      }
    }

    return {
      'labels': hourlyCounts.keys.toList(),
      'values': hourlyCounts.values.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ANALYTICS & SUMMARY STATS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.electricTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Reports Dashboard",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                tooltip: 'Refresh Reports',
                onPressed: _fetchReportsData,
              )
            ],
          ),
          const SizedBox(height: 24),
          // Custom TabBar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.neonLime,
              labelColor: AppTheme.neonLime,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "MATCH LOGS", icon: Icon(Icons.history, size: 18)),
                Tab(text: "PLAYER ATTENDANCE", icon: Icon(Icons.people_outline, size: 18)),
                Tab(text: "COURT UTILIZATION", icon: Icon(Icons.pie_chart_outline, size: 18)),
                Tab(text: "QUEUE HOURLY ACTIVITY", icon: Icon(Icons.show_chart_outlined, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tab views
          Expanded(
            child: _loadingReports
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // View 1: History
                      const HistoryView(),
                      
                      // View 2: Player attendance
                      _buildPlayerAttendanceView(),
                      
                      // View 3: Court utilization
                      _buildCourtUtilizationView(),
                      
                      // View 4: Queue activity
                      _buildQueueActivityView(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAttendanceView() {
    final barData = _getTopPlayersBarData();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Panel
        Expanded(
          flex: 1,
          child: GlassCard(
            child: BarChartWidget(
              data: barData,
              title: "TOP PLAYERS BY GAMES PLAYED",
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Grid Table Panel
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ATTENDANCE CHECK-IN LOGS",
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: _attendanceData.isEmpty
                      ? const Center(child: Text("No players checked in today.", style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          itemCount: _attendanceData.length,
                          separatorBuilder: (context, idx) => const Divider(height: 12, color: AppTheme.borderMuted),
                          itemBuilder: (context, idx) {
                            final row = _attendanceData[idx];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['name'] as String,
                                      style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "Status: ${(row['status'] as String).toUpperCase()}",
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonLime.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.neonLime.withOpacity(0.15)),
                                  ),
                                  child: Text(
                                    "${row['games_played']} games played",
                                    style: const TextStyle(
                                      color: AppTheme.neonLime,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Outfit',
                                    ),
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
    );
  }

  Widget _buildCourtUtilizationView() {
    final donutData = _getCourtDonutData();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Panel
        Expanded(
          flex: 1,
          child: GlassCard(
            child: DonutChartWidget(
              data: donutData,
              title: "COURT ENGAGEMENT RATIOS",
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Grid Table Panel
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "COURT OPERATION METRICS",
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: _courtData.isEmpty
                      ? const Center(child: Text("No court records.", style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          itemCount: _courtData.length,
                          separatorBuilder: (context, idx) => const Divider(height: 12, color: AppTheme.borderMuted),
                          itemBuilder: (context, idx) {
                            final row = _courtData[idx];
                            final durationSec = row['total_duration_seconds'] as int? ?? 0;
                            final durationMin = durationSec / 60;
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['name'] as String,
                                      style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "Total matches: ${row['total_matches']}",
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${durationMin.toStringAsFixed(1)} active min",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.electricTeal,
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
    );
  }

  Widget _buildQueueActivityView() {
    final trend = _getHourlyActivityData();
    final List<double> values = List<double>.from(trend['values']!);
    final List<String> labels = List<String>.from(trend['labels']!);

    // Calculate queue metrics
    final totalGames = _queueData.length;
    double avgDurationMin = 0;
    if (totalGames > 0) {
      final totalSec = _queueData.fold<int>(0, (sum, item) => sum + (item['duration_seconds'] as int? ?? 0));
      avgDurationMin = (totalSec / totalGames) / 60;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Panel
        Expanded(
          flex: 2,
          child: GlassCard(
            child: LineChartWidget(
              points: values,
              labels: labels,
              title: "MATCHES COMPLETED HOURLY TRENDS",
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Grid Table Panel
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SUMMARY ANALYSIS",
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Metric 1: Total matches played
                      _buildMetricRow("Matches Completed", "$totalGames", Icons.check_circle_outline),
                      const Divider(height: 32, color: AppTheme.borderMuted),
                      
                      // Metric 2: Average match length
                      _buildMetricRow("Average Game Length", "${avgDurationMin.toStringAsFixed(1)} min", Icons.timer_outlined),
                      const Divider(height: 32, color: AppTheme.borderMuted),
                      
                      // Metric 3: Peak hour
                      _buildMetricRow(
                        "Peak Hours",
                        _getPeakHourText(values, labels),
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Queue activity reports are based on completed game logs recorded within today's operational window.",
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.neonLime.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.neonLime, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPeakHourText(List<double> values, List<String> labels) {
    if (values.isEmpty || values.every((v) => v == 0)) return "N/A";
    
    double maxVal = 0;
    int peakIndex = 0;
    
    for (int i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        peakIndex = i;
      }
    }
    
    return "${labels[peakIndex]} (${maxVal.toStringAsFixed(0)} games)";
  }
}
