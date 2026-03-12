import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;

  // Phase animations (driven by _masterController)
  late final Animation<double> _bgFade;
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldRotation;
  late final Animation<double> _shieldGlow;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _exitFade;

  // Pulse for the icon (continuous)
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Immersive status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Master timeline: 3.2 seconds total
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Continuous pulse for the icon glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Slow orbit for floating particles
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Phase 1 (0-400ms): Background fade in
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0, 0.12, curve: Curves.easeOut),
      ),
    );

    // Phase 2 (200-900ms): Shield icon scale up + rotate
    _shieldScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.06, 0.30, curve: Curves.elasticOut),
      ),
    );

    _shieldRotation = Tween<double>(begin: -0.15, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.06, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 3 (600-1000ms): Shield glow bloom
    _shieldGlow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.18, 0.35, curve: Curves.easeOut),
      ),
    );

    // Phase 4 (800-1400ms): Title slides up + fades in
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.28, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.28, 0.45, curve: Curves.easeOut),
      ),
    );

    // Phase 5 (1200-1800ms): Subtitle fade in
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.40, 0.58, curve: Curves.easeOut),
      ),
    );

    // Phase 6 (1600-2200ms): Tagline fade in
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.52, 0.70, curve: Curves.easeOut),
      ),
    );

    // Phase 7 (2800-3200ms): Everything fades out for transition
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the master animation
    _masterController.forward();

    // Navigate after the splash completes
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.bgDark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterController,
          _pulseController,
          _orbitController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF0D0D0D),
                      const Color(0xFF1A1A1A),
                      _bgFade.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF0D0D0D),
                      const Color(0xFF111111),
                      _bgFade.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF0D0D0D),
                      const Color(0xFF0A0A0A),
                      _bgFade.value,
                    )!,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Floating particles
                  ..._buildFloatingParticles(),

                  // Subtle radial glow behind the icon
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.30,
                    child: Opacity(
                      opacity: _shieldGlow.value * 0.5,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accentCyan.withValues(alpha: 0.15 * _pulse.value),
                              AppColors.accentCyan.withValues(alpha: 0.05 * _pulse.value),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.5, 1],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Shield icon
                      Transform.rotate(
                        angle: _shieldRotation.value,
                        child: Transform.scale(
                          scale: _shieldScale.value * _pulse.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2A2A2A),
                                  Color(0xFF1A1A1A),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan
                                      .withValues(alpha: 0.3 * _shieldGlow.value),
                                  blurRadius: 40 * _shieldGlow.value,
                                  spreadRadius: 2 * _shieldGlow.value,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.accentCyan
                                    .withValues(alpha: 0.2 * _shieldGlow.value),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Title: H.A.I.L.M.A.R.Y.
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleFade.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFFB0B0B0),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'H.A.I.L.M.A.R.Y.',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtle divider line
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accentCyan.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Text(
                          'Hostel Administrative Intelligence\n& Logistics Management for Access,\nRegulation and Systems',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF808080),
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tagline
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                          child: Text(
                            'Smart Hostel Management',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF606060),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Bottom loading indicator
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 140,
                              child: _AnimatedLoadingBar(
                                progress: _masterController.value,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Initializing secure session...',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF505050),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingParticles() {
    // Generate subtle floating dots
    final particles = <Widget>[];
    final size = MediaQuery.of(context).size;
    final random = math.Random(42); // Fixed seed for consistent layout

    for (int i = 0; i < 12; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final particleSize = 2.0 + random.nextDouble() * 3;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final delay = random.nextDouble();

      // Calculate orbit position
      final angle = (_orbitController.value * 2 * math.pi * speed) + (i * 0.5);
      final radius = 15.0 + random.nextDouble() * 25;
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius;

      // Fade particles with the splash
      final opacity = (_bgFade.value * 0.4 * (0.3 + delay * 0.7)).clamp(0.0, 0.4);

      particles.add(
        Positioned(
          left: startX + dx,
          top: startY + dy,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i % 3 == 0
                    ? AppColors.accentCyan
                    : i % 3 == 1
                        ? Colors.white
                        : AppColors.accentAmber,
              ),
            ),
          ),
        ),
      );
    }
    return particles;
  }
}

/// Animated loading bar that fills up during the splash
class _AnimatedLoadingBar extends StatelessWidget {
  final double progress;
  const _AnimatedLoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Map 0.5-0.9 of master progress to 0-1 for the bar
    final barProgress = ((progress - 0.45) / 0.45).clamp(0.0, 1.0);

    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: barProgress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  AppColors.accentCyan.withValues(alpha: 0.8),
                  AppColors.accentCyan.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
