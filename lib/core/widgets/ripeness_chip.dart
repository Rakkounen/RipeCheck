import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum RipenessLevel {
  ripe,
  unripe,
  overripe,
  rotten,
  unknown,
}

/// Reusable Widget: RipenessChip (C2 requirement)
/// Status kematangan memakai chip berisi ikon dan teks.
/// Tidak membedakan status HANYA dengan warna. Gaya chip seragam dengan ikon berbeda per kelas.
class RipenessChip extends StatelessWidget {
  final String label;
  final RipenessLevel level;
  final bool isLarge;

  const RipenessChip({
    super.key,
    required this.label,
    required this.level,
    this.isLarge = false,
  });

  factory RipenessChip.fromString(String rawText, {bool isLarge = false}) {
    final lower = rawText.toLowerCase();
    RipenessLevel level = RipenessLevel.unknown;

    if (lower.contains('rotten') || lower.contains('busuk')) {
      level = RipenessLevel.rotten;
    } else if (lower.contains('overripe') || lower.contains('terlalu matang')) {
      level = RipenessLevel.overripe;
    } else if (lower.contains('unripe') || lower.contains('mentah')) {
      level = RipenessLevel.unripe;
    } else if (lower.contains('setengah matang') || lower.contains('half ripe')) {
      level = RipenessLevel.overripe;
    } else if (lower.contains('ripe') || lower.contains('fresh') || lower.contains('matang') || lower.contains('segar')) {
      level = RipenessLevel.ripe;
    }

    return RipenessChip(
      label: rawText,
      level: level,
      isLarge: isLarge,
    );
  }

  IconData _getIconForLevel(RipenessLevel level) {
    switch (level) {
      case RipenessLevel.ripe:
        return Icons.check_circle_outline;
      case RipenessLevel.unripe:
        return Icons.hourglass_top_outlined;
      case RipenessLevel.overripe:
        return Icons.warning_amber_rounded;
      case RipenessLevel.rotten:
        return Icons.cancel_outlined;
      case RipenessLevel.unknown:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconForLevel(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppSpacing.md : AppSpacing.sm,
        vertical: isLarge ? AppSpacing.xs + 2 : AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.chipBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: isLarge ? 18 : 14,
            color: AppColors.textCharcoal,
          ),
          SizedBox(width: isLarge ? AppSpacing.xs + 2 : AppSpacing.xs),
          Text(
            label,
            style: (isLarge ? theme.textTheme.labelLarge : theme.textTheme.labelMedium)?.copyWith(
              color: AppColors.textCharcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
