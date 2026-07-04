import 'dart:math';
import 'package:flutter/material.dart';

class ChartSegment {
  final String label;
  final int value;
  final Color color;
  ChartSegment(this.label, this.value, this.color);
}

class ReportDonutChart extends StatelessWidget {
  final List<ChartSegment> segments;
  final double size;
  final double thickness;

  const ReportDonutChart({
    Key? key,
    required this.segments,
    this.size = 140,
    this.thickness = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = segments.map((s) => s.value).fold(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.08),
        ),
        child: const Center(
          child: Text(
            '0',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments, thickness: thickness),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                total.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              const Text(
                'TOTAL',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double thickness;

  _DonutPainter({required this.segments, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = segments.map((s) => s.value.toDouble()).fold(0.0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - thickness) / 2;

    double startAngle = -pi / 2;

    for (final seg in segments) {
      if (seg.value == 0) continue;
      final sweepAngle = (seg.value / total) * 2 * pi;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ReportStackedBarChart extends StatelessWidget {
  final List<ChartSegment> segments;

  const ReportStackedBarChart({Key? key, required this.segments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = segments.map((s) => s.value).fold(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        child: Row(
          children: segments.where((s) => s.value > 0).map((seg) {
            final flex = ((seg.value / total) * 1000).round();
            return Expanded(
              flex: flex > 0 ? flex : 1,
              child: Container(
                color: seg.color,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
