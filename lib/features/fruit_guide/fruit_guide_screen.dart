import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ripeness_chip.dart';

class FruitGuideScreen extends StatelessWidget {
  const FruitGuideScreen({super.key});

  final List<Map<String, dynamic>> _guides = const [
    {
      'name': 'Apel',
      'scientific': 'Malus domestica',
      'idealStatus': 'Matang / Segar',
      'tips': 'Kulit halus, warna merata, tekstur padat saat ditekan lembut, aroma manis segar.',
    },
    {
      'name': 'Pisang',
      'scientific': 'Musa acuminata',
      'idealStatus': 'Matang / Segar',
      'tips': 'Warna kuning cerah dengan sedikit bintik cokelat kecil (sugar spots), tangkai masih kokoh.',
    },
    {
      'name': 'Jeruk',
      'scientific': 'Citrus sinensis',
      'idealStatus': 'Matang / Segar',
      'tips': 'Kulit berpori halus, terasa padat berbobot (menandakan kandungan air melimpah), aroma wangi.',
    },
    {
      'name': 'Mangga',
      'scientific': 'Mangifera indica',
      'idealStatus': 'Matang / Segar',
      'tips': 'Tekstur agak empuk saat ditekan lembut dekat tangkai, mengeluarkan aroma harum kuat.',
    },
    {
      'name': 'Pepaya',
      'scientific': 'Carica papaya',
      'idealStatus': 'Matang / Segar',
      'tips': 'Kulit menguning setidaknya 50-80%, daging buah sedikit empuk saat ditekan.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panduan Buah'),
      ),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: _guides.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final fruit = _guides[index];
          // C3 Anti-Slop: Gunakan baris daftar yang rapi dan terstruktur
          return Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.smRadius,
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary),
              ),
              title: Text(
                fruit['name'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textCharcoal,
                ),
              ),
              subtitle: Text(
                fruit['scientific'] as String,
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              trailing: RipenessChip.fromString(fruit['idealStatus'] as String),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fruit['tips'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
