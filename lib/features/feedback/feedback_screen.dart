import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/custom_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _fruitController = TextEditingController();
  final _correctionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fruitController.dispose();
    _correctionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_fruitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama buah')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Umpan balik Anda membantu meningkatkan akurasi model.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Beri Umpan Balik'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Text(
              'Bantu Tingkatkan Akurasi Model',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jika hasil deteksi kematangan kurang tepat, kirimkan koreksi agar sistem pembelajaran dapat diperbaiki.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppTextField(
              controller: _fruitController,
              label: 'Nama Buah',
              hintText: 'Misal: Pisang Cavendish, Apel Fuji',
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _correctionController,
              label: 'Status Kematangan yang Sebenarnya',
              hintText: 'Misal: Seharusnya Terlalu Matang',
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _notesController,
              label: 'Catatan Tambahan (Opsional)',
              hintText: 'Deskripsikan kondisi fisik, warna, atau tekstur buah...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'Kirim Umpan Balik',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
