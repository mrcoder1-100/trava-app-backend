import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../home/main_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _roadAnimation;
  late Animation<double> _busPositionAnimation;
  late Animation<double> _pinScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();
    // 3.0 second intro animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 0.0 - 0.8s: Road draws onto screen
    _roadAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
    );

    // 0.8 - 1.8s: Stylized bus moves smoothly along road
    _busPositionAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.62, curve: Curves.easeInOutCubic),
    );

    // 1.8 - 2.5s: GPS pin pulses and drops into place
    _pinScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.82, curve: Curves.elasticOut),
    );

    // 2.5 - 3.0s: Trava branding and tagline reveal
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    final api = ApiService();
    if (api.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Stack(
        children: [
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _navigateNext,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Main Animation Canvas
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation Stage
                    SizedBox(
                      width: 320,
                      height: 180,
                      child: CustomPaint(
                        painter: _IntroScenePainter(
                          roadProgress: _roadAnimation.value,
                          busProgress: _busPositionAnimation.value,
                          pinScale: _pinScaleAnimation.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Brand & Official Tagline
                    Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppTheme.emeraldDark,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.tagline,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.charcoal,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.emerald.withOpacity(0.2)),
                            ),
                            child: const Text(
                              '📍 Coimbatore City Transit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroScenePainter extends CustomPainter {
  final double roadProgress;
  final double busProgress;
  final double pinScale;

  _IntroScenePainter({
    required this.roadProgress,
    required this.busProgress,
    required this.pinScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadY = size.height * 0.72;

    // 1. Road base
    final roadPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    final roadStart = Offset(20, roadY);
    final roadEnd = Offset(20 + (size.width - 40) * roadProgress, roadY);

    if (roadProgress > 0) {
      canvas.drawLine(roadStart, roadEnd, roadPaint);

      // Dash road markings
      final dashPaint = Paint()
        ..color = const Color(0xFFF1C40F)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      const dashWidth = 14.0;
      const dashSpace = 10.0;
      double currentX = 30.0;

      while (currentX < roadEnd.dx - 10) {
        final nextX = math.min(currentX + dashWidth, roadEnd.dx);
        canvas.drawLine(Offset(currentX, roadY), Offset(nextX, roadY), dashPaint);
        currentX += dashWidth + dashSpace;
      }
    }

    // 2. Stylized Bus
    if (busProgress > 0) {
      final busWidth = 58.0;
      final busHeight = 34.0;
      final busX = 20 + (size.width - 40 - busWidth) * busProgress;
      final busY = roadY - busHeight - 2;

      // Tracking trail line
      final trailPaint = Paint()
        ..color = AppTheme.emerald.withOpacity(0.4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(30, 80), Offset(busX + busWidth / 2, busY + busHeight / 2), trailPaint);

      // Bus Body
      final busBodyPaint = Paint()..color = AppTheme.emerald;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(busX, busY, busWidth, busHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, busBodyPaint);

      // Bus Roof accent
      final roofPaint = Paint()..color = AppTheme.amber;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(busX + 4, busY + 2, busWidth - 8, 4),
          const Radius.circular(2),
        ),
        roofPaint,
      );

      // Bus Windows
      final windowPaint = Paint()..color = Colors.white.withOpacity(0.9);
      for (int i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(busX + 8 + (i * 15.0), busY + 8, 11, 11),
            const Radius.circular(2),
          ),
          windowPaint,
        );
      }

      // Wheels
      final wheelPaint = Paint()..color = const Color(0xFF1C2024);
      final wheelRimPaint = Paint()..color = Colors.white;

      final wheel1Center = Offset(busX + 14, roadY - 1);
      final wheel2Center = Offset(busX + busWidth - 14, roadY - 1);

      canvas.drawCircle(wheel1Center, 7, wheelPaint);
      canvas.drawCircle(wheel1Center, 3, wheelRimPaint);

      canvas.drawCircle(wheel2Center, 7, wheelPaint);
      canvas.drawCircle(wheel2Center, 3, wheelRimPaint);

      // 3. Pulsing GPS Pin above bus
      if (pinScale > 0) {
        final pinX = busX + busWidth / 2;
        final pinY = busY - 18;

        canvas.save();
        canvas.translate(pinX, pinY);
        canvas.scale(pinScale);

        // Radar pulse ring
        final pulsePaint = Paint()
          ..color = AppTheme.amber.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset.zero, 16, pulsePaint);

        // Pin head
        final pinPaint = Paint()..color = AppTheme.amber;
        canvas.drawCircle(const Offset(0, -4), 8, pinPaint);

        // White dot inside pin
        final dotPaint = Paint()..color = Colors.white;
        canvas.drawCircle(const Offset(0, -4), 3, dotPaint);

        // Pin tip
        final path = Path()
          ..moveTo(-5, -2)
          ..lineTo(0, 6)
          ..lineTo(5, -2)
          ..close();
        canvas.drawPath(path, pinPaint);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IntroScenePainter oldDelegate) {
    return oldDelegate.roadProgress != roadProgress ||
        oldDelegate.busProgress != busProgress ||
        oldDelegate.pinScale != pinScale;
  }
}
