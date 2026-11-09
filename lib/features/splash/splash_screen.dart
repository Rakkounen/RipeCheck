import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/database/app_database.dart';
import '../../services/tflite_service.dart';

/// D1. Splash Screen
/// Mengimplementasikan desain Stitch Screen 1 (Splash Screen):
/// - Brand logo box dengan scanner reticles, buah mango gradasi & green checkmark
/// - Wordmark "RipeCheck" dua warna (Orange & Forest Green)
/// - Feature pill badge: "Smart Fruit AI Scanner"
/// - Tagline: "Cek kematangan buah dalam sekali foto"
/// - Footer: Pulsing dot dengan status "Memuat kecerdasan botani..."
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Membuka database SQLite secara aman
      try {
        await AppDatabase().init();
      } catch (dbErr) {
        // Jangan blokir aplikasi jika hanya kendala non-kritis database
      }

      // 2. Memuat model dan label TFLite secara aman
      try {
        await TFLiteService().loadModel();
      } catch (modelErr) {
        // Model akan di-load ulang saat pertama kali scan
        // Jangan blokir navigasi ke onboarding/home
      }

      // 3. Jeda animasi splash screen yang nyaman dan profesional
      await Future.delayed(const Duration(milliseconds: 1800));

      if (!mounted) return;

      // Selalu tampilkan Onboarding saat pertama kali aplikasi dibuka
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Aplikasi belum siap. Model atau data gagal dimuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEBF3E8),
              Color(0xFFF4F7F2),
              Color(0xFFFBFBF7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Brand App Icon Box (Rounded card with shadow & inner icon)
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.16),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo_app.jpeg',
                    width: 116,
                    height: 116,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Wordmark Title
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Ripe',
                      style: TextStyle(
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -0.6,
                      ),
                    ),
                    TextSpan(
                      text: 'Check',
                      style: TextStyle(
                        color: Color(0xFF1F2A1F),
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Feature Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 15,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Smart Fruit AI Scanner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),

              // Tagline
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Loading Indicator atau Error Message
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingGreenDot(),
                      SizedBox(width: 8),
                      Text(
                        'Memuat kecerdasan botani...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          text: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          onPressed: _initializeApp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingGreenDot extends StatefulWidget {
  const _PulsingGreenDot();

  @override
  State<_PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<_PulsingGreenDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D32),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
