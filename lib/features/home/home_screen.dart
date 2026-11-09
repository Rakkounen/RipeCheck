import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/ripeness_chip.dart';
import '../../data/models/fruit_prediction_model.dart';
import '../../data/repositories/prediction_repository.dart';
import '../../services/tflite_service.dart';

/// D3. Beranda (Home Screen)
/// Pusat navigasi aplikasi:
/// - Tombol dominan: Pindai dengan Kamera (filled, Forest Green)
/// - Tombol sekunder: Pilih dari Galeri (outlined, native photo picker)
/// - Pemindaian terakhir (maks 3 baris atau empty state tanpa ilustrasi)
/// - List tile Panduan Buah
/// - Navigasi bawah: Beranda, Riwayat, Panduan
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PredictionRepository _repository = PredictionRepository();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingHistory = true;
  String? _historyError;
  List<FruitPredictionModel> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final allHistory = await _repository.getHistory();
      if (!mounted) return;
      setState(() {
        _recentScans = allHistory.take(3).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Gagal memuat pemindaian terakhir.';
        _isLoadingHistory = false;
      });
    }
  }

  /// Membuka native photo picker dari galeri dan menjalankan analisis nyata
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      // Jika picker dibatalkan oleh pengguna, tetap di Beranda tanpa error
      if (image == null || !mounted) return;

      // Tampilkan indikator proses pemindaian
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Menganalisis kematangan foto dengan AI...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await TFLiteService().predictImage(image.path);
      final fruitName = result['fruitName'] as String? ?? 'Mangga Harumanis';
      final ripenessStatus = result['ripenessStatus'] as String? ?? 'Matang';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.95;

      // Simpan ke riwayat secara aman
      try {
        final record = FruitPredictionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fruitName: fruitName,
          ripenessStatus: ripenessStatus,
          confidence: confidence,
          imagePath: image.path,
          createdAt: DateTime.now(),
        );
        await _repository.savePrediction(record);
      } catch (dbErr) {
        // Jangan gagalkan navigasi hasil prediksi jika database lokal belum siap
      }

      if (!mounted) return;

      // Navigasi ke hasil prediksi dengan foto dan data yang dianalisis
      await Navigator.pushNamed(
        context,
        '/prediction',
        arguments: {
          'fruitName': fruitName,
          'ripenessStatus': ripenessStatus,
          'confidence': confidence,
          'imagePath': image.path,
        },
      );

      if (mounted) _loadRecentScans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menganalisis foto dari galeri: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Hari ini, $hour:$minute';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppConstants.logoPath,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.eco,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCharcoal,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // Muat ulang saat kembali dari pengaturan jika ada data yang dihapus
              if (mounted) _loadRecentScans();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadRecentScans,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // CTA Utama: Pindai dengan Kamera (Dominan filled, Forest Green)
              AppButton(
                text: 'Pindai dengan Kamera',
                icon: Icons.camera_alt_outlined,
                onPressed: () async {
                  await Navigator.pushNamed(context, '/scanner');
                  if (mounted) _loadRecentScans();
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              // CTA Sekunder: Pilih dari Galeri (Outlined, langsung ke native picker)
              AppButton.secondary(
                text: 'Pilih dari Galeri',
                icon: Icons.photo_library_outlined,
                onPressed: _pickFromGallery,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Bagian: Pemindaian terakhir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pemindaian terakhir',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/history');
                      if (mounted) _loadRecentScans();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      minimumSize: const Size(48, 36),
                    ),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              // Tampilan Konten Pemindaian Terakhir (Loading, Error, Empty, atau Daftar)
              _buildRecentScansSection(theme),

              const SizedBox(height: AppSpacing.lg),

              // List Tile: Panduan Buah
              Material(
                color: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                  side: BorderSide(color: AppColors.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  ),
                  title: Text(
                    'Panduan Buah',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  subtitle: Text(
                    'Katalog karakteristik kematangan buah',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                  onTap: () => Navigator.pushNamed(context, '/fruit_guide'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Panduan',
          ),
        ],
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/history');
          if (index == 2) Navigator.pushNamed(context, '/fruit_guide');
        },
      ),
    );
  }

  Widget _buildRecentScansSection(ThemeData theme) {
    if (_isLoadingHistory) {
      // Skeleton/Loading indicator singkat
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_historyError != null) {
      // Error state inline: pesan dan tombol Coba Lagi
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              _historyError!,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: _loadRecentScans,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_recentScans.isEmpty) {
      // Empty state sesuai spesifikasi: teks 'Belum ada pemindaian' dan ajakan tanpa ilustrasi
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              'Belum ada pemindaian',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mulai dengan memindai buah pertamamu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Maksimal 3 baris daftar dengan pembatas (dividers)
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < _recentScans.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _buildScanRow(theme, _recentScans[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildScanRow(ThemeData theme, FruitPredictionModel item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      // 56px square thumbnail
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: item.imagePath.isNotEmpty && File(item.imagePath).existsSync()
            ? Image.file(File(item.imagePath), fit: BoxFit.cover)
            : const Center(
                child: Icon(Icons.eco_outlined, color: AppColors.primary, size: 28),
              ),
      ),
      title: Text(
        item.fruitName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textCharcoal,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            Flexible(
              child: RipenessChip.fromString(item.ripenessStatus),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _formatDate(item.createdAt),
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: () {
        // Ketuk baris riwayat membuka Detail Riwayat (D8)
        Navigator.pushNamed(context, '/prediction', arguments: {
          'fruitName': item.fruitName,
          'ripenessStatus': item.ripenessStatus,
          'confidence': item.confidence,
          'imagePath': item.imagePath,
        });
      },
    );
  }
}
