import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum ButtonVariant {
  primary,
  secondary,
  destructive,
}

/// Standardized App Button adhering to C2, C3, and C4:
/// - Minimum interactive height >= 48px (Touch Target Rule)
/// - Clean flat styling without gratuitous shadow/gradients
/// - Three explicit purposeful variants: Primary, Secondary, Destructive
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = ButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = ButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.textInverse;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.surface;
        foregroundColor = AppColors.textCharcoal;
        borderSide = const BorderSide(color: AppColors.border, width: 1.5);
        break;
      case ButtonVariant.destructive:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.onError;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: AppSpacing.minTouchTarget,
      child: Material(
        color: onPressed == null ? backgroundColor.withValues(alpha: 0.5) : backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
