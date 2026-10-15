import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> attributes;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  const RadarChartWidget({
    super.key,
    required this.attributes,
    this.maxValue = 100.0,
    this.lineColor = AppTheme.lfcRed,
    this.fillColor = const Color(0x55C8102E),
  });

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return const Center(child: Text('No attributes available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarChartPainter(
                attributes: attributes,
                maxValue: maxValue,
                lineColor: lineColor,
                fillColor: fillColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> attributes;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  _RadarChartPainter({
    required this.attributes,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 38;
    final keys = attributes.keys.toList();
    final count = keys.length;

    if (count < 3) return;

    final gridPaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = AppTheme.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw concentric polygons (25%, 50%, 75%, 100%)
    const levels = 4;
    for (int lvl = 1; lvl <= levels; lvl++) {
      final currentRadius = radius * (lvl / levels);
      final gridPath = Path();
      for (int i = 0; i < count; i++) {
        final angle = (2 * pi / count) * i - pi / 2;
        final x = center.dx + currentRadius * cos(angle);
        final y = center.dy + currentRadius * sin(angle);
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // Draw axes and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i - pi / 2;
      final endX = center.dx + radius * cos(angle);
      final endY = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);

      // Label text
      final key = keys[i];
      final val = attributes[key] ?? 0;
      final label = '$key\n${val.toInt()}';
      
      final labelDist = radius + 22;
      final labelX = center.dx + labelDist * cos(angle);
      final labelY = center.dy + labelDist * sin(angle);

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Draw player data polygon
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i - pi / 2;
      final val = attributes[keys[i]] ?? 0.0;
      final normalized = (val / maxValue).clamp(0.0, 1.0);
      final curRadius = radius * normalized;
      final x = center.dx + curRadius * cos(angle);
      final y = center.dy + curRadius * sin(angle);
      final point = Offset(x, y);
      dataPoints.add(point);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(dataPath, strokePaint);

    // Points
    final dotPaint = Paint()..color = AppTheme.lfcYellow;
    for (final pt in dataPoints) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.attributes != attributes ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
