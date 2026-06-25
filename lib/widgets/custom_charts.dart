import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

// --- BAR CHART WIDGET (Player Attendance / Games Played) ---

class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final barGroups = <BarChartGroupData>[];
    int index = 0;
    data.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: AppTheme.neonLime,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      index++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < data.keys.length) {
                        final text = data.keys.elementAt(idx);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            text.length > 6 ? '${text.substring(0, 5)}..' : text,
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- DONUT CHART WIDGET (Court Utilization) ---

class DonutChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const DonutChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.values.every((v) => v <= 0.002)) {
      return Center(
        child: Text(
          "No activity recorded yet",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final colors = [
      AppTheme.neonLime,
      AppTheme.electricTeal,
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
    ];

    int colorIndex = 0;
    final sections = <PieChartSectionData>[];
    data.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            value: value,
            color: colors[colorIndex % colors.length],
            radius: 20,
            showTitle: false,
          ),
        );
        colorIndex++;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildLegend(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final colors = [
      AppTheme.neonLime,
      AppTheme.electricTeal,
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
    ];

    final entries = data.entries.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final color = colors[index % colors.length];
        final entry = entries[index];
        
        final duration = entry.value;
        String formattedVal = '';
        if (duration < 60) {
          formattedVal = '${duration.toStringAsFixed(0)}s';
        } else if (duration < 3600) {
          formattedVal = '${(duration / 60).toStringAsFixed(0)}m';
        } else {
          formattedVal = '${(duration / 3600).toStringAsFixed(1)}h';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedVal,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- LINE CHART WIDGET (Queue Activity Trends) ---

class LineChartWidget extends StatelessWidget {
  final List<double> points;
  final List<String> labels;
  final String title;

  const LineChartWidget({
    super.key,
    required this.points,
    required this.labels,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          "No matches played today",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.electricTeal,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.electricTeal.withOpacity(0.05),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
