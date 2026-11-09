import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/ripeness_chip.dart';

class PredictionScreen extends StatelessWidget {
  final String fruitName;
  final String ripenessStatus;
  final double confidence;
  final bool isConfident;
  final String? imagePath;

  const PredictionScreen({
    super.key,
    this.fruitName = 'Mangga Harumanis',
    this.ripenessStatus = 'Matang',
    this.confidence = 0.95,
    this.isConfident = true,
    this.imagePath,
  });

  Map<String, String> _getFruitAdvice() {
    final status = ripenessStatus.toLowerCase();
    if (status.contains('matang') && !status.contains('setengah')) {
      return {
        'actionAdvice': 'Siap dikonsumsi langsung! Mangga Harumanis sudah manis dan lembut. Sangat nikmat disajikan segar atau sebagai jus.',
        'storage': 'Simpan di lemari es (7°C - 10°C) agar kesegaran dan rasa manisnya bertahan lebih lama.',
        'shelfLife': '2 - 4 hari pada suhu ruang, hingga 7 hari di dalam kulkas.',
      };
    } else if (status.contains('setengah')) {
      return {
        'actionAdvice': 'Biarkan 1-2 hari lagi pada suhu ruang agar mencapai kematangan manis sempurna. Atau bisa dinikmati bagi yang suka rasa manis segar sedikit asam.',
        'storage': 'Simpan di suhu ruang terbuka (25°C). Jangan langsung dimasukkan ke kulkas agar pematangan tidak terhenti.',
        'shelfLife': '3 - 5 hari menuju kematangan puncak.',
      };
    } else if (status.contains('mentah')) {
      return {
        'actionAdvice': 'Jangan langsung dikonsumsi sebagai buah manis karena masih asam dan keras. Sangat cocok diolah menjadi rujak, asinan, atau sambal mangga.',
        'storage': 'Peram di suhu ruang dalam wadah tertutup kertas atau beras untuk mempercepat kematangan alami.',
        'shelfLife': '5 - 8 hari sebelum siap matang sempurna.',
      };
    } else {
      return {
        'actionAdvice': 'Buah sudah tidak layak konsumsi karena telah busuk atau rusak. Segera pisahkan agar tidak mencemari buah lainnya.',
        'storage': 'Jangan dikonsumsi atau disimpan kembali.',
        'shelfLife': 'Sudah melewati masa segar layak konsumsi.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil arguments jika dilewatkan lewat Navigator.pushNamed
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final effectiveFruitName = args?['fruitName'] as String? ?? fruitName;
    final effectiveRipeness = args?['ripenessStatus'] as String? ?? ripenessStatus;
    final effectiveConfidence = (args?['confidence'] as num?)?.toDouble() ?? confidence;
    final effectiveIsConfident = (args?['isConfident'] as bool?) ?? isConfident;
    final effectiveImagePath = args?['imagePath'] as String? ?? imagePath;

    final advice = _getFruitAdvice();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Prediksi AI'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Tampilan Foto Nyata Hasil Scan / Galeri
                    if (effectiveImagePath != null && File(effectiveImagePath).existsSync()) ...[
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.mdRadius,
                          child: Image.file(
                            File(effectiveImagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Result Overview Container
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!effectiveIsConfident) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: AppRadius.smRadius,
                                border: Border.all(color: const Color(0xFFFDBA74)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 20),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Foto belum dapat dianalisis dengan yakin. Silakan ambil foto ulang dengan pencahayaan yang lebih baik.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF9A3412),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effectiveFruitName,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Tingkat Kepercayaan ${(effectiveConfidence * 100).toStringAsFixed(1)}%',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RipenessChip.fromString(effectiveRipeness, isLarge: true),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(),
                          const SizedBox(height: AppSpacing.md),

                          // Saran Penggunaan / Tindakan (Hanya menyisakan saran yang sesuai)
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Saran Penyajian & Tindakan',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            advice['actionAdvice']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textCharcoal,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Information Details Rows (Saran Penyimpanan & Masa Simpan)
                    Material(
                      color: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.mdRadius,
                        side: BorderSide(color: AppColors.borderSubtle),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.kitchen_outlined, color: AppColors.secondary),
                            title: const Text('Saran Penyimpanan'),
                            subtitle: Text(advice['storage']!),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.secondary),
                            title: const Text('Perkiraan Masa Simpan'),
                            subtitle: Text(advice['shelfLife']!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: 'Pindai Buah Lain',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    text: 'Koreksi / Beri Umpan Balik',
                    icon: Icons.feedback_outlined,
                    onPressed: () => Navigator.pushNamed(context, '/feedback'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
