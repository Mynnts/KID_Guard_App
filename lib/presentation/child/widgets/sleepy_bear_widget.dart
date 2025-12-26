import 'dart:math';
import 'package:flutter/material.dart';

/// Sleepy Bear Widget - Animated cute bear mascot for lock screen
class SleepyBearWidget extends StatefulWidget {
  final bool isSleeping;
  final double size;

  const SleepyBearWidget({super.key, this.isSleeping = true, this.size = 180});

  @override
  State<SleepyBearWidget> createState() => _SleepyBearWidgetState();
}

class _SleepyBearWidgetState extends State<SleepyBearWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _eyeController;
  late AnimationController _zzzController;
  late Animation<double> _breathAnimation;
  late Animation<double> _eyeAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Eye blinking animation
    _eyeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _eyeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut));

    // Occasional blink
    _startBlinking();

    // ZZZ floating animation
    _zzzController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  void _startBlinking() {
    Future.delayed(Duration(milliseconds: Random().nextInt(3000) + 2000), () {
      if (mounted && !widget.isSleeping) {
        _eyeController.forward().then((_) {
          _eyeController.reverse().then((_) {
            _startBlinking();
          });
        });
      } else if (mounted) {
        _startBlinking();
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _eyeController.dispose();
    _zzzController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bear body
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathAnimation.value,
                child: _buildBear(),
              );
            },
          ),

          // ZZZ bubbles
          if (widget.isSleeping) ...[
            _buildZzz(0, -30, 0.0, 18),
            _buildZzz(20, -50, 0.3, 22),
            _buildZzz(45, -75, 0.6, 26),
          ],
        ],
      ),
    );
  }

  Widget _buildBear() {
    final size = widget.size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Bear body
        Container(
          width: size * 0.75,
          height: size * 0.6,
          margin: EdgeInsets.only(top: size * 0.35),
          decoration: BoxDecoration(
            color: const Color(0xFFDEB887), // Tan/Beige
            borderRadius: BorderRadius.circular(size * 0.35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),

        // Bear belly
        Container(
          width: size * 0.45,
          height: size * 0.35,
          margin: EdgeInsets.only(top: size * 0.45),
          decoration: BoxDecoration(
            color: const Color(0xFFF5DEB3), // Wheat
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
        ),

        // Bear head
        Container(
          width: size * 0.7,
          height: size * 0.6,
          margin: EdgeInsets.only(bottom: size * 0.3),
          decoration: BoxDecoration(
            color: const Color(0xFFDEB887),
            borderRadius: BorderRadius.circular(size * 0.35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left ear
              Positioned(
                left: size * 0.02,
                top: -size * 0.05,
                child: _buildEar(size * 0.18),
              ),

              // Right ear
              Positioned(
                right: size * 0.02,
                top: -size * 0.05,
                child: _buildEar(size * 0.18),
              ),

              // Face
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size * 0.08),

                  // Eyes row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(size * 0.08, isLeft: true),
                      SizedBox(width: size * 0.15),
                      _buildEye(size * 0.08, isLeft: false),
                    ],
                  ),

                  SizedBox(height: size * 0.03),

                  // Muzzle
                  Container(
                    width: size * 0.28,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5DEB3),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size * 0.1),
                        topRight: Radius.circular(size * 0.1),
                        bottomLeft: Radius.circular(size * 0.14),
                        bottomRight: Radius.circular(size * 0.14),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nose
                        Container(
                          width: size * 0.08,
                          height: size * 0.05,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3728),
                            borderRadius: BorderRadius.circular(size * 0.03),
                          ),
                        ),
                        SizedBox(height: size * 0.01),
                        // Mouth
                        _buildMouth(size),
                      ],
                    ),
                  ),
                ],
              ),

              // Blush cheeks
              Positioned(
                left: size * 0.08,
                top: size * 0.32,
                child: _buildBlush(size * 0.08),
              ),
              Positioned(
                right: size * 0.08,
                top: size * 0.32,
                child: _buildBlush(size * 0.08),
              ),
            ],
          ),
        ),

        // Arms holding phone
        Positioned(top: size * 0.5, child: _buildArmsWithPhone(size)),
      ],
    );
  }

  Widget _buildEar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDEB887),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC4A574), width: 2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB6C1), // Light pink inner ear
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEye(double size, {required bool isLeft}) {
    if (widget.isSleeping) {
      // Sleeping eyes - curved lines
      return SizedBox(
        width: size * 1.5,
        height: size,
        child: CustomPaint(painter: _SleepingEyePainter(isLeft: isLeft)),
      );
    }

    // Awake eyes
    return AnimatedBuilder(
      animation: _eyeAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size * _eyeAnimation.value,
          decoration: BoxDecoration(
            color: const Color(0xFF2C1810),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: _eyeAnimation.value > 0.5
              ? Align(
                  alignment: isLeft
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: size * 0.3,
                    height: size * 0.3,
                    margin: EdgeInsets.only(
                      right: isLeft ? size * 0.15 : 0,
                      left: isLeft ? 0 : size * 0.15,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMouth(double size) {
    if (widget.isSleeping) {
      // Peaceful sleeping smile
      return SizedBox(
        width: size * 0.12,
        height: size * 0.04,
        child: CustomPaint(painter: _SmilePainter()),
      );
    }
    // Normal mouth
    return Container(
      width: size * 0.03,
      height: size * 0.02,
      decoration: BoxDecoration(
        color: const Color(0xFF4A3728),
        borderRadius: BorderRadius.circular(size * 0.01),
      ),
    );
  }

  Widget _buildBlush(double size) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB6C1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }

  Widget _buildArmsWithPhone(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Phone
        Container(
          width: size * 0.25,
          height: size * 0.35,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(size * 0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: widget.isSleeping
                  ? const Color(0xFF1a1a2e)
                  : const Color(0xFF4FC3F7),
              borderRadius: BorderRadius.circular(size * 0.02),
            ),
            child: widget.isSleeping
                ? Center(
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: size * 0.1,
                    ),
                  )
                : null,
          ),
        ),

        // Left paw
        Positioned(
          left: -size * 0.18,
          child: Transform.rotate(angle: 0.3, child: _buildPaw(size * 0.15)),
        ),

        // Right paw
        Positioned(
          right: -size * 0.18,
          child: Transform.rotate(angle: -0.3, child: _buildPaw(size * 0.15)),
        ),
      ],
    );
  }

  Widget _buildPaw(double size) {
    return Container(
      width: size,
      height: size * 1.3,
      decoration: BoxDecoration(
        color: const Color(0xFFDEB887),
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: size * 0.7,
          height: size * 0.5,
          margin: EdgeInsets.only(bottom: size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFF5DEB3),
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildZzz(
    double offsetX,
    double offsetY,
    double delay,
    double fontSize,
  ) {
    return AnimatedBuilder(
      animation: _zzzController,
      builder: (context, child) {
        final progress = ((_zzzController.value + delay) % 1.0);
        final opacity = progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
        final yOffset = offsetY - (progress * 30);

        return Positioned(
          right: widget.size * 0.15 + offsetX,
          top: widget.size * 0.15 + yOffset,
          child: Opacity(
            opacity: opacity.clamp(0.0, 0.8),
            child: Text(
              'z',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for sleeping eyes (curved lines)
class _SleepingEyePainter extends CustomPainter {
  final bool isLeft;

  _SleepingEyePainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C1810)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isLeft) {
      path.moveTo(0, size.height * 0.3);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      );
    } else {
      path.moveTo(0, size.height * 0.3);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for smile
class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A3728)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.5, size.height * 1.5, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
