import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// D2. Onboarding Screen
/// Mengimplementasikan 3 layar onboarding dari Stitch (RipeCheck Fruit Ripeness Scanner):
/// - Layar 1: "Kenali Buahmu" (Pengenalan deteksi kematangan dengan scan reticles & badge)
/// - Layar 2: "Cara Memindai" (Panduan 3 langkah pencahayaan, posisi bingkai, dan shutter)
/// - Layar 3: "Izin Akses" (Permintaan izin akses Kamera & Galeri dengan aksi interaktif)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Status izin interaktif untuk layar 3
  bool _cameraGranted = false;
  bool _galleryGranted = false;

  // Stitch Design Tokens
  static const Color _stitchCanvas = Color(0xFFFAFAF5);
  static const Color _stitchPrimary = Color(0xFF2E7D32);
  static const Color _stitchPrimaryDark = Color(0xFF256629);
  static const Color _stitchDarkText = Color(0xFF1F2A1F);
  static const Color _stitchBodyText = Color(0xFF4A554B);
  static const Color _stitchMutedText = Color(0xFF5C6B5E);
  static const Color _stitchDotInactive = Color(0xFFD6DFD4);
  static const Color _stitchSoftGreen = Color(0xFFEAF3E7);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingSeen, true);

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stitchCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo Minimal (Green rounded box with checkmark + RipeCheck)
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: _stitchDarkText,
                          ),
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _stitchPrimary.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo_app.jpeg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'RipeCheck',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _stitchDarkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // Tombol Lewati (Hanya muncul jika belum di halaman terakhir)
                  AnimatedOpacity(
                    opacity: _currentPage < 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _currentPage < 2 ? _completeOnboarding : null,
                      style: TextButton.styleFrom(
                        foregroundColor: _stitchMutedText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        minimumSize: const Size(48, 36),
                      ),
                      child: const Text(
                        'Lewati',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView 3 Langkah
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildStepOneKenaliBuahmu(),
                  _buildStepTwoCaraMemindai(),
                  _buildStepThreeIzinAkses(),
                ],
              ),
            ),

            // Bottom Area: Page Indicator & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indikator 3 Titik
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? _stitchPrimary : _stitchDotInactive,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tombol Utama (Lanjut -> / Mulai)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _stitchPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: _stitchPrimary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Mulai' : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (_currentPage < 2) ...[
                            const SizedBox(width: AppSpacing.xs + 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: KENALI BUAHMU (Stitch Screen 1)
  // ==========================================
  Widget _buildStepOneKenaliBuahmu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Card dengan Scanner Frame Reticles & Badge
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 270),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8EDE5)),
              boxShadow: [
                BoxShadow(
                  color: _stitchDarkText.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 4 Corner Scanning Target Reticles
                const Positioned(
                  top: 0,
                  left: 0,
                  child: _ScannerBracket(corner: _BracketCorner.topLeft),
                ),
                const Positioned(
                  top: 0,
                  right: 0,
                  child: _ScannerBracket(corner: _BracketCorner.topRight),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  child: _ScannerBracket(corner: _BracketCorner.bottomLeft),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: _ScannerBracket(corner: _BracketCorner.bottomRight),
                ),

                // Center Composition: Ilustrasi Buah & Scan Beam
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft glow di belakang buah
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFE082).withValues(alpha: 0.4),
                                _stitchSoftGreen.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Buah Utama (Mangga / Apel / Jeruk)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Green Apple
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF8BC34A), Color(0xFF558B2F)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Ripe Mango (Hero)
                            Container(
                              width: 84,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(38),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFF9800),
                                    Color(0xFFE65100),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.energy_savings_leaf_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Orange Slice
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Scanning Laser Beam
                        Positioned(
                          top: 48,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _stitchPrimary.withValues(alpha: 0.9),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Detection Pill Badge: "• Matang 94%"
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: const Color(0xFFE0E6DD)),
                      boxShadow: [
                        BoxShadow(
                          color: _stitchDarkText.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _stitchPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'Matang 94%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _stitchDarkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Typography
          const Text(
            'Kenali Buahmu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _stitchDarkText,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Kenali jenis buah dan prediksi tingkat kematangannya hanya melalui foto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _stitchBodyText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: CARA MEMINDAI (Stitch Screen 2)
  // ==========================================
  Widget _buildStepTwoCaraMemindai() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Visual Preview Smartphone & AI Focus Tag
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 155),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone Viewfinder Illustration
                Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD3E0D1), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _stitchDarkText.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Buah di dalam bidik layar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 16,
                          color: Color(0xFFFFA4A2),
                        ),
                      ),
                      // Frame Reticle hijau
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _stitchPrimary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating AI badge
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: const Color(0xFFD6E2D4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _stitchPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'Fokus Kamera AI Otomatis',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _stitchDarkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Typography
          const Text(
            'Cara Memindai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _stitchDarkText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Ikuti langkah sederhana untuk mendapatkan hasil prediksi yang lebih baik.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _stitchBodyText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3 Step Instruction Cards
          _buildInstructionCard(
            stepNumber: 1,
            icon: Icons.wb_sunny_outlined,
            title: 'Cahaya Cukup',
            description: 'Gunakan pencahayaan alami yang merata.',
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          _buildInstructionCard(
            stepNumber: 2,
            icon: Icons.filter_center_focus_rounded,
            title: 'Buah di Tengah Bingkai',
            description: 'Posisikan buah tepat di dalam kotak panduan.',
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          _buildInstructionCard(
            stepNumber: 3,
            icon: Icons.camera_alt_outlined,
            title: 'Ambil Foto',
            description: 'Tekan tombol shutter untuk memproses hasil.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDE5)),
        boxShadow: [
          BoxShadow(
            color: _stitchDarkText.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _stitchSoftGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _stitchPrimary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _stitchSoftGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LANGKAH $stepNumber',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _stitchPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _stitchDarkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _stitchMutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: IZIN AKSES (Stitch Screen 4)
  // ==========================================
  Widget _buildStepThreeIzinAkses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Graphic: Phone dengan Floating Camera & Gallery Badges
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 155),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone Outline
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4E2D2), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA726),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: Color(0xFFFFCC80),
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Floating Camera Badge (Left)
                Positioned(
                  left: 36,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4E2D2)),
                      boxShadow: [
                        BoxShadow(
                          color: _stitchDarkText.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _stitchPrimary,
                      size: 20,
                    ),
                  ),
                ),

                // Floating Gallery Badge (Right)
                Positioned(
                  right: 36,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4E2D2)),
                      boxShadow: [
                        BoxShadow(
                          color: _stitchDarkText.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: _stitchPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Typography
          const Text(
            'Izin Akses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _stitchDarkText,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Izinkan akses yang diperlukan agar kamu dapat memindai buah dengan mudah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _stitchBodyText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Permission Cards (Kamera & Galeri)
          _buildPermissionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Kamera',
            description: 'Untuk mengambil foto buah secara langsung.',
            isGranted: _cameraGranted,
            onToggle: () {
              setState(() {
                _cameraGranted = !_cameraGranted;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionCard(
            icon: Icons.photo_library_outlined,
            title: 'Galeri',
            description: 'Untuk memilih foto buah yang tersimpan di HP.',
            isGranted: _galleryGranted,
            onToggle: () {
              setState(() {
                _galleryGranted = !_galleryGranted;
              });
            },
          ),
          const SizedBox(height: AppSpacing.xs),

          // Tombol Text: Nanti Saja
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: _stitchMutedText,
              minimumSize: const Size(80, 36),
            ),
            child: const Text(
              'Nanti Saja',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? _stitchPrimary.withValues(alpha: 0.3) : const Color(0xFFE8EDE5),
        ),
        boxShadow: [
          BoxShadow(
            color: _stitchDarkText.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Icon Holder
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isGranted ? _stitchPrimary : _stitchSoftGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check_rounded : icon,
              color: isGranted ? Colors.white : _stitchPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _stitchDarkText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _stitchMutedText,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Action Button
          Material(
            color: isGranted ? _stitchSoftGreen : _stitchSoftGreen,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 7,
                ),
                child: Text(
                  isGranted ? 'Diizinkan' : 'Izinkan Akses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isGranted ? _stitchPrimaryDark : _stitchPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCANNER CORNER BRACKET WIDGET
// ==========================================
enum _BracketCorner { topLeft, topRight, bottomLeft, bottomRight }

class _ScannerBracket extends StatelessWidget {
  final _BracketCorner corner;

  const _ScannerBracket({required this.corner});

  @override
  Widget build(BuildContext context) {
    const double size = 20;
    const double thickness = 2.5;
    const Color color = Color(0xFF2E7D32);
    const Radius radius = Radius.circular(6);

    Border border;
    BorderRadius borderRadius;

    switch (corner) {
      case _BracketCorner.topLeft:
        border = const Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        );
        borderRadius = const BorderRadius.only(topLeft: radius);
        break;
      case _BracketCorner.topRight:
        border = const Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        );
        borderRadius = const BorderRadius.only(topRight: radius);
        break;
      case _BracketCorner.bottomLeft:
        border = const Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        );
        borderRadius = const BorderRadius.only(bottomLeft: radius);
        break;
      case _BracketCorner.bottomRight:
        border = const Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        );
        borderRadius = const BorderRadius.only(bottomRight: radius);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: border,
        borderRadius: borderRadius,
      ),
    );
  }
}
