import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final Color? borderColor;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.borderWidth = 1,
    this.borderColor,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: AppTheme.glassCard(
        color: color,
        radius: radius,
        borderWidth: borderWidth,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}
