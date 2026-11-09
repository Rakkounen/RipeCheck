import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'custom_button.dart';

/// Reusable Widget: AppDialog (C4 requirement)
/// Dialog izin menjelaskan alasan permintaan secara spesifik. Kontrol sentuh >= 48px dan tidak berdekatan.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Batal',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String reason,
    String confirmText = 'Izinkan Akses',
    String cancelText = 'Nanti Saja',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.camera_alt_outlined,
        title: title,
        message: reason,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Lanjutkan',
    String cancelText = 'Batal',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Icon(icon, size: 28, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  text: confirmText,
                  onPressed: onConfirm,
                  variant: isDestructive ? ButtonVariant.destructive : ButtonVariant.primary,
                ),
                if (cancelText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    text: cancelText!,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
