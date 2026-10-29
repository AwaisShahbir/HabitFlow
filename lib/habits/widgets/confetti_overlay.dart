import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlayController extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void _finish() {
    _isPlaying = false;
    notifyListeners();
  }
}

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final ConfettiOverlayController controller;

  const ConfettiOverlay({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_ConfettiParticle> _particles = [];
  final Random _rng = Random();

  static const List<Color> _colors = [
    Color(0xFF15803D), // Forest Emerald
    Color(0xFF22C55E), // Vivid Green
    Color(0xFF86EFAC), // Mint Light
    Color(0xFFF59E0B), // Vibrant Gold
    Color(0xFFFBBF24), // Warm Yellow
    Color(0xFFEF4444), // Coral Red
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFA855F7), // Royal Purple
    Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    widget.controller.addListener(_handleController);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller._finish();
        setState(() {
          _particles.clear();
        });
      }
    });
  }

  void _handleController() {
    if (widget.controller.isPlaying && !_animController.isAnimating) {
      _spawnParticles();
      _animController.forward(from: 0.0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    const count = 75;
    for (int i = 0; i < count; i++) {
      final color = _colors[_rng.nextInt(_colors.length)];
      // Spawn from middle-lower area for a celebration fountain
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * (pi * 0.85);
      final speed = 650.0 + _rng.nextDouble() * 650.0;
      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed;

      final size = 7.0 + _rng.nextDouble() * 6.0;
      final isCircle = _rng.nextBool();
      final rotSpeed = (_rng.nextDouble() - 0.5) * 12.0;

      _particles.add(
        _ConfettiParticle(
          xRatio: 0.5 + (_rng.nextDouble() - 0.5) * 0.3,
          yRatio: 0.75,
          vx: vx,
          vy: vy,
          color: color,
          size: size,
          isCircle: isCircle,
          rotationSpeed: rotSpeed,
          flutterSpeed: 3.0 + _rng.nextDouble() * 5.0,
          flutterAmplitude: 15.0 + _rng.nextDouble() * 25.0,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleController);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _animController.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double xRatio;
  final double yRatio;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final bool isCircle;
  final double rotationSpeed;
  final double flutterSpeed;
  final double flutterAmplitude;

  _ConfettiParticle({
    required this.xRatio,
    required this.yRatio,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.isCircle,
    required this.rotationSpeed,
    required this.flutterSpeed,
    required this.flutterAmplitude,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    // t is elapsed seconds (approx 2.6s total)
    final t = progress * 2.6;
    const gravity = 850.0; // px/s^2

    // Fade out during final 25% of animation
    final double alpha = progress > 0.75 ? ((1.0 - progress) / 0.25).clamp(0.0, 1.0) : 1.0;

    for (final p in particles) {
      final startX = size.width * p.xRatio;
      final startY = size.height * p.yRatio;

      final currentX = startX + p.vx * t + sin(t * p.flutterSpeed) * p.flutterAmplitude;
      final currentY = startY + p.vy * t + 0.5 * gravity * t * t;

      if (currentY > size.height + 40 || currentX < -40 || currentX > size.width + 40) {
        continue;
      }

      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      final rotation = t * p.rotationSpeed;
      canvas.rotate(rotation);

      // Simulates 3D flipping in air
      final scaleX = cos(t * p.rotationSpeed * 1.5).abs().clamp(0.15, 1.0);
      canvas.scale(scaleX, 1.0);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.4, height: p.size * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

