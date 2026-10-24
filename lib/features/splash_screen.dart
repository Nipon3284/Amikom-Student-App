import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/portal_provider.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// Splash Screen modeled faithfully after the official website preloader
/// at https://amikompurwokerto.ac.id/ (modern-style.css #preloader).
/// Features rotating dual concentric rings, pulse logo, brand typography, and gold progress bar.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0720),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Dual Ring Spin Controller (1.2s per turn clockwise)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // 2. Logo Pulse Controller (scale 0.92 to 1.08, 1.8s alternate)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3. Horizontal Gold Progress Fill (1.5s ease-in-out)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _checkAuthentication();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Keep splash visible briefly to appreciate the authentic preloader animation
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final secureStorage = ref.read(secureStorageProvider);
    final savedNpm = await secureStorage.getNpm();
    final savedPass = await secureStorage.getPassword();
    final isBiometric = await secureStorage.isBiometricEnabled();

    if (savedNpm != null && savedPass != null) {
      if (isBiometric) {
        try {
          final canCheck = await _localAuth.canCheckBiometrics;
          final isDeviceSupported = await _localAuth.isDeviceSupported();

          if (canCheck && isDeviceSupported) {
            final didAuth = await _localAuth.authenticate(
              localizedReason:
                  'Gunakan sidik jari atau Face ID untuk masuk ke Amikom Student',
              biometricOnly: true,
              persistAcrossBackgrounding: true,
            );

            if (didAuth && mounted) {
              HapticFeedback.lightImpact();
              final ok = await ref
                  .read(authProvider.notifier)
                  .login(savedNpm, savedPass);
              if (ok && mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const MainNavigationScreen()),
                );
                return;
              }
            }
          }
        } catch (_) {}
      } else {
        // Direct auto-login with saved credentials
        final ok =
            await ref.read(authProvider.notifier).login(savedNpm, savedPass);
        if (ok && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
          return;
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0720), // Official preloader background
      body: Stack(
        children: [
          // Ambient Radial Violet Glow Behind Loader
          Positioned(
            top: MediaQuery.of(context).size.height * 0.32,
            left: MediaQuery.of(context).size.width * 0.5 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.amikomPurple.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Concentric Animated Preloader Rings + Center Logo
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Rings Painter
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, _) {
                          final spin = _spinController.value * 2 * math.pi;
                          // Reverse spin takes 3.0s (1200ms / 3000ms = 0.4x speed in reverse)
                          final reverseSpin = -_spinController.value * 0.4 * 2 * math.pi;

                          return CustomPaint(
                            size: const Size(140, 140),
                            painter: _PreloaderRingsPainter(
                              spinAngle: spin,
                              reverseSpinAngle: reverseSpin,
                            ),
                          );
                        },
                      ),

                      // Center Logo with Pulse Animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final scale = 0.92 + (_pulseController.value * 0.16);
                          final opacity = 0.85 + (_pulseController.value * 0.15);

                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1B0C30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amikomGold
                                          .withValues(alpha: 0.45),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  'assets/images/amikom_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Preloader Main Title
                const Text(
                  'UNIVERSITAS AMIKOM PURWOKERTO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFFFFFFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Preloader Subtext with Bullet Points
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amikomGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Kampus Berwawasan Technopreneur',
                      style: TextStyle(
                        color: AppColors.amikomGold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amikomGold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Preloader Animated Progress Bar
                Container(
                  width: 160,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amikomGold.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreloaderRingsPainter extends CustomPainter {
  final double spinAngle;
  final double reverseSpinAngle;

  _PreloaderRingsPainter({
    required this.spinAngle,
    required this.reverseSpinAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = 54.0;
    final outerRadius = 65.0;

    // 1. Outer Dashed Ring (preloader-ring-outer rotating counter-clockwise)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(reverseSpinAngle);

    final outerDashedPaint = Paint()
      ..color = const Color(0x77F49F31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const dashCount = 28;
    const dashSweep = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: outerRadius),
        i * dashSweep,
        dashSweep * 0.65,
        false,
        outerDashedPaint,
      );
    }
    canvas.restore();

    // 2. Inner Glowing Arc Ring (preloader-ring rotating clockwise)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spinAngle);

    final sweepGradient = const SweepGradient(
      colors: [
        AppColors.amikomGold,
        AppColors.amikomPurple,
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 0.8],
    );

    final innerArcPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: innerRadius),
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: innerRadius),
      0,
      math.pi * 1.5,
      false,
      innerArcPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreloaderRingsPainter oldDelegate) =>
      oldDelegate.spinAngle != spinAngle ||
      oldDelegate.reverseSpinAngle != reverseSpinAngle;
}
