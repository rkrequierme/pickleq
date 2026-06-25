import 'dart:math';
import 'package:flutter/material.dart';
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

    final maxVal = data.values.isEmpty ? 1.0 : data.values.reduce(max);
    final limit = maxVal == 0 ? 10.0 : maxVal * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(data: data, maxVal: limit),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double maxVal;

  _BarChartPainter({required this.data, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final list = data.entries.toList();
    final barCount = list.length;
    
    final double paddingRight = 10.0;
    final double paddingLeft = 40.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 30.0;
    
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    
    final barWidth = (chartWidth / barCount) * 0.55;
    final spacing = (chartWidth / barCount) * 0.45;
    
    // Draw Y-Axis lines (Grid lines)
    final gridPaint = Paint()
      ..color = AppTheme.borderMuted.withOpacity(0.3)
      ..strokeWidth = 1;
      
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 4; i++) {
      final yVal = (maxVal / 4) * i;
      final y = paddingTop + chartHeight - (chartHeight * (i / 4));
      
      // Grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
      
      // Grid label
      textPainter.text = TextSpan(
        text: yVal.toStringAsFixed(0),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Inter'),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
    
    // Draw Bars
    for (int i = 0; i < barCount; i++) {
      final entry = list[i];
      final val = entry.value;
      final label = entry.key;
      
      final barHeight = chartHeight * (val / maxVal);
      final left = paddingLeft + (spacing / 2) + i * (barWidth + spacing);
      final right = left + barWidth;
      final top = paddingTop + chartHeight - barHeight;
      final bottom = paddingTop + chartHeight;
      
      // Gradient for bar
      final rect = Rect.fromLTRB(left, top, right, bottom);
      final barPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.electricTeal, AppTheme.neonLime],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(rect)
        ..style = PaintingStyle.fill;
        
      // Draw rounded top bar
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      
      canvas.drawRRect(rrect, barPaint);
      
      // Draw shadow glow for active bar
      if (val > 0) {
        final glowPaint = Paint()
          ..color = AppTheme.neonLime.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rrect, glowPaint);
      }

      // Draw Value on top of bar
      textPainter.text = TextSpan(
        text: val.toStringAsFixed(0),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, top - textPainter.height - 4),
      );

      // Draw X Label
      final truncatedLabel = label.length > 8 ? '${label.substring(0, 6)}..' : label;
      textPainter.text = TextSpan(
        text: truncatedLabel,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Inter'),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Text(
          "No activity recorded yet",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DonutChartPainter(data: data),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
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
      const Color(0xFFC77CFF),
      const Color(0xFFFFB800),
      const Color(0xFF00FF85),
    ];

    final entries = data.entries.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final color = colors[index % colors.length];
        final entry = entries[index];
        
        // Show in hours/minutes
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
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontFamily: 'Inter'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedVal,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> data;

  _DonutChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.values.reduce((a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;
    final strokeWidth = radius * 0.35;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final colors = [
      AppTheme.neonLime,
      AppTheme.electricTeal,
      const Color(0xFFC77CFF),
      const Color(0xFFFFB800),
      const Color(0xFF00FF85),
    ];

    double startAngle = -pi / 2;

    int colorIndex = 0;
    data.forEach((key, val) {
      final sweepAngle = (val / total) * 2 * pi;
      if (sweepAngle > 0) {
        paint.color = colors[colorIndex % colors.length];
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        // Drawing a subtle inner line for separations
        final separatorPaint = Paint()
          ..color = AppTheme.obsidianBg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawLine(
          center + Offset(cos(startAngle) * (radius - strokeWidth / 2), sin(startAngle) * (radius - strokeWidth / 2)),
          center + Offset(cos(startAngle) * (radius + strokeWidth / 2), sin(startAngle) * (radius + strokeWidth / 2)),
          separatorPaint,
        );

        startAngle += sweepAngle;
        colorIndex++;
      }
    });

    // Draw central text percentage/summary (e.g. "Utilized")
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "COURT USAGE",
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontFamily: 'Outfit',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 2),
    );

    final matchesCount = data.values.length;
    final numPainter = TextPainter(
      text: TextSpan(
        text: "$matchesCount courts",
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Outfit',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numPainter.paint(
      canvas,
      Offset(center.dx - numPainter.width / 2, center.dy + 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- LINE CHART WIDGET (Queue Activity Trends) ---

class LineChartWidget extends StatelessWidget {
  final List<double> points; // Y-values corresponding to hourly intervals
  final List<String> labels; // X-values corresponding to hour labels
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _LineChartPainter(points: points, labels: labels),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final List<String> labels;

  _LineChartPainter({required this.points, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingRight = 20.0;
    final double paddingLeft = 35.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 30.0;
    
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    
    final maxVal = points.reduce(max);
    final limitY = maxVal == 0 ? 5.0 : maxVal * 1.25;

    // Draw Grid Lines (Y values)
    final gridPaint = Paint()
      ..color = AppTheme.borderMuted.withOpacity(0.2)
      ..strokeWidth = 1;
      
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 3; i++) {
      final yVal = (limitY / 3) * i;
      final y = paddingTop + chartHeight - (chartHeight * (i / 3));
      
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
      
      textPainter.text = TextSpan(
        text: yVal.toStringAsFixed(0),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Inter'),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    if (points.length < 2) {
      // Draw single point if only 1 data element exists
      if (points.isNotEmpty) {
        final x = paddingLeft + chartWidth / 2;
        final y = paddingTop + chartHeight - (chartHeight * (points[0] / limitY));
        final dotPaint = Paint()..color = AppTheme.electricTeal;
        canvas.drawCircle(Offset(x, y), 6, dotPaint);
        
        textPainter.text = TextSpan(
          text: labels[0],
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Inter'),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, paddingTop + chartHeight + 8));
      }
      return;
    }

    final double stepX = chartWidth / (points.length - 1);
    
    // Generate drawing path
    final path = Path();
    final fillPath = Path();
    
    final firstY = paddingTop + chartHeight - (chartHeight * (points[0] / limitY));
    path.moveTo(paddingLeft, firstY);
    fillPath.moveTo(paddingLeft, paddingTop + chartHeight);
    fillPath.lineTo(paddingLeft, firstY);

    for (int i = 1; i < points.length; i++) {
      final currentX = paddingLeft + i * stepX;
      final currentY = paddingTop + chartHeight - (chartHeight * (points[i] / limitY));
      
      // Control points for smooth bezier curves
      final prevX = paddingLeft + (i - 1) * stepX;
      final prevY = paddingTop + chartHeight - (chartHeight * (points[i - 1] / limitY));
      final controlX1 = prevX + (currentX - prevX) / 2;
      final controlY1 = prevY;
      final controlX2 = prevX + (currentX - prevX) / 2;
      final controlY2 = currentY;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, currentX, currentY);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, currentX, currentY);
    }
    
    fillPath.lineTo(paddingLeft + (points.length - 1) * stepX, paddingTop + chartHeight);
    fillPath.close();

    // Draw Fill Shader under line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.electricTeal.withOpacity(0.25), AppTheme.electricTeal.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, paddingTop + chartHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Bezier Line
    final linePaint = Paint()
      ..color = AppTheme.electricTeal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw Glowing dots and X-axis Labels
    final dotPaint = Paint()
      ..color = AppTheme.neonLime
      ..style = PaintingStyle.fill;
    
    final dotBorderPaint = Paint()
      ..color = AppTheme.obsidianBg
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final x = paddingLeft + i * stepX;
      final y = paddingTop + chartHeight - (chartHeight * (points[i] / limitY));
      
      // Draw glowing dot border
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      
      // Draw X Label
      if (i % max(1, points.length ~/ 6) == 0 || i == points.length - 1) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Inter'),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, paddingTop + chartHeight + 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
