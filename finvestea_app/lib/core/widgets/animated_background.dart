import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _glowController;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.mainGradient,
      child: Stack(
        children: [
          // Animated waves
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(
                  animationValue: _waveAnimation.value,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                size: Size.infinite,
              );
            },
          ),
          // Radial glow effects
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.5),
                    radius: 0.8,
                    colors: [
                      AppTheme.secondaryAccentColor.withValues(
                        alpha: _glowAnimation.value * 0.2,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          // Second radial glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, 0.8),
                    radius: 0.6,
                    colors: [
                      AppTheme.highlightColor.withValues(
                        alpha: _glowAnimation.value * 0.15,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          // Main content
          widget.child,
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create multiple wave layers
    for (int i = 0; i < 3; i++) {
      final waveHeight = 20.0 + i * 10;
      final speed = 1.0 + i * 0.5;
      final phase = animationValue * 2 * 3.14159 * speed;

      path.reset();
      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 5) {
        final y =
            size.height * 0.7 +
            waveHeight *
                (0.5 + 0.5 * (i + 1) / 3) *
                (sin(x * 0.01 + phase) + sin(x * 0.005 + phase * 0.7));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
