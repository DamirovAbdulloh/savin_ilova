import 'dart:math';
import 'package:flutter/material.dart';

/// Yengil, hech qanday tashqi paketsiz konfetti animatsiyasi.
/// QR muvaffaqiyatli tasdiqlanganda ishlatiladi.
class ConfettiOverlay extends StatefulWidget {
  final bool play;
  const ConfettiOverlay({super.key, required this.play});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Particle {
  final double x0;
  final double vx;
  final double vy0;
  final double size;
  final Color color;
  final double rotSpeed;
  _Particle({
    required this.x0,
    required this.vx,
    required this.vy0,
    required this.size,
    required this.color,
    required this.rotSpeed,
  });
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random(7);
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFF3DCB5E),
    Color(0xFFF5A623),
    Color(0xFFE5484D),
    Color(0xFFFFFFFF),
    Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _particles = List.generate(50, (i) {
      return _Particle(
        x0: _rand.nextDouble(),
        vx: (_rand.nextDouble() - 0.5) * 0.6,
        vy0: 0.9 + _rand.nextDouble() * 0.6,
        size: 5 + _rand.nextDouble() * 6,
        color: _colors[_rand.nextInt(_colors.length)],
        rotSpeed: (_rand.nextDouble() - 0.5) * 10,
      );
    });
    if (widget.play) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final opacity = t > 0.7 ? (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;
    for (final p in particles) {
      final dx = (p.x0 + p.vx * t) * size.width;
      final dy = p.vy0 * t * t * size.height * 1.1 - (size.height * 0.15);
      if (dy < -20 || dy > size.height + 20) continue;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotSpeed * t * pi);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
