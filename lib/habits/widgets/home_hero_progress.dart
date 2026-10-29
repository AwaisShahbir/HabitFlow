import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitflow/habits/widgets/plant_data.dart';

class HomeHeroProgress extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final String dateWeekday;
  final String dateDayMonthYear;

  const HomeHeroProgress({
    Key? key,
    required this.completedCount,
    required this.totalCount,
    required this.dateWeekday,
    required this.dateDayMonthYear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progress =
        totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left: Date Info
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateWeekday,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateDayMonthYear,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center: Rounded circle in exact middle, Leaf on its left side
          Center(
            child: SizedBox(
              width: 250,
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Soft Watercolor Aura behind the plant on full left
                  Positioned(
                    left: -35,
                    top: 10,
                    child: Container(
                      width: 170,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark
                                    ? const Color(0xFF166534)
                                    : const Color(0xFFDCFCE7))
                                .withOpacity(isDark ? 0.35 : 0.65),
                            (isDark ? const Color(0xFF0F172A) : Colors.white)
                                .withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Botanical Foliage on FULL LEFT SIDE (tucked under left arc)
                  Positioned(
                    left: 197,
                    top: 2,
                    width: 145,
                    height: 176,
                    child: Image.memory(
                      isDark ? kHeroPlantDarkBytes : kHeroPlantLightBytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  // 3. Circular Progress Ring (Centered in the 250x180 container)
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Outer Glow
                        Container(
                          width: 146,
                          height: 146,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A)
                                    .withOpacity(isDark ? 0.25 : 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),

                        // Ring Canvas Arc
                        CustomPaint(
                          size: const Size(150, 150),
                          painter: GradientRingPainter(
                            progress: progress,
                            strokeWidth: 15,
                            trackColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            startColor: const Color(0xFF4ADE80),
                            endColor: const Color(0xFF15803D),
                          ),
                        ),

                        // Inner White Center
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.35 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$completedCount/$totalCount',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
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
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the gradient circular progress ring
class GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Full Circular Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Active Gradient Arc
    final sweepAngle = 2 * math.pi * progress;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [startColor, endColor],
      stops: const [0.0, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant GradientRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}
