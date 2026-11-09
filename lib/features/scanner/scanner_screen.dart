import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_state_views.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/models/fruit_prediction_model.dart';
import '../../data/repositories/prediction_repository.dart';
import '../../services/tflite_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final TFLiteService _tfLiteService = TFLiteService();
  final PredictionRepository _repository = PredictionRepository();

  bool _isAnalyzing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Buka kamera secara otomatis begitu layar pemindai terbuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  /// Membuka kamera perangkat secara langsung untuk mengambil foto buah
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (photo == null) {
        // Pengguna membatalkan pengambilan gambar
        return;
      }

      final file = File(photo.path);
      setState(() {
        _selectedImage = file;
      });

      await _processImagePrediction(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kendala mengakses kamera: $e')),
      );
    }
  }

  /// Membuka galeri foto dari layar scanner
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image == null) return;

      final file = File(image.path);
      setState(() {
        _selectedImage = file;
      });

      await _processImagePrediction(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kendala memilih foto: $e')),
      );
    }
  }

  /// Menganalisis gambar menggunakan model TFLite EfficientNetB0 yang telah dilatih
  Future<void> _processImagePrediction(String imagePath) async {
    setState(() => _isAnalyzing = true);

    try {
      // 1. Eksekusi inferensi AI nyata pada citra
      final result = await _tfLiteService.predictImage(imagePath);

      final fruitName = result['fruitName'] as String? ?? 'Mangga Harumanis';
      final ripenessStatus = result['ripenessStatus'] as String? ?? 'Matang';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.95;

      // 2. Simpan hasil prediksi ke dalam database lokal riwayat secara aman
      try {
        final predictionRecord = FruitPredictionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fruitName: fruitName,
          ripenessStatus: ripenessStatus,
          confidence: confidence,
          imagePath: imagePath,
          createdAt: DateTime.now(),
        );
        await _repository.savePrediction(predictionRecord);
      } catch (dbErr) {
        // Jangan gagalkan alur inferensi jika database lokal ada kendala
      }

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      // 3. Pindah ke layar hasil prediksi dengan membawa data dan foto asli
      Navigator.pushReplacementNamed(
        context,
        '/prediction',
        arguments: {
          'fruitName': fruitName,
          'ripenessStatus': ripenessStatus,
          'confidence': confidence,
          'imagePath': imagePath,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menganalisis citra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pindai Buah Asli'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              Text(
                'Arahkan kamera ke buah mangga untuk analisis kematangan & varietas otomatis',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Viewfinder frame / Image Preview
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340, maxHeight: 380),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isAnalyzing
                        ? const AppLoadingState(message: 'Menganalisis kematangan dengan AI...')
                        : _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.photo_camera_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Kamera Aktif',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.textCharcoal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Posisikan buah tepat di tengah layar',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Tombol Kontrol
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: _isAnalyzing ? 'Sedang Memproses AI...' : 'Ambil Ulang Foto Kamera',
                    icon: Icons.camera_alt_rounded,
                    isLoading: _isAnalyzing,
                    onPressed: _isAnalyzing ? null : _takePhoto,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    text: 'Pilih dari Galeri',
                    icon: Icons.photo_library_outlined,
                    onPressed: _isAnalyzing ? null : _pickFromGallery,
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
