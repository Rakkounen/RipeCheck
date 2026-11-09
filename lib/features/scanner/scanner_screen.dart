import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_logger.dart';
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

  bool _isPickingImage = false;
  bool _isAnalyzing = false;
  File? _selectedImage;

  bool get _isBusy => _isPickingImage || _isAnalyzing;

  Future<void> _pickImage(ImageSource source) async {
    if (_isBusy) return;
    setState(() => _isPickingImage = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (!mounted || image == null) return;

      final file = File(image.path);
      setState(() {
        _selectedImage = file;
        _isPickingImage = false;
        _isAnalyzing = true;
      });

      await _processImagePrediction(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kendala mengakses kamera: $e'
                : 'Kendala memilih foto: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _processImagePrediction(String imagePath) async {
    try {
      final result = await _tfLiteService.predictImage(imagePath);
      final fruitName = result['fruitName'] as String;
      final ripenessStatus = result['ripenessStatus'] as String;
      final confidence = (result['confidence'] as num).toDouble();
      final isConfident = result['isConfident'] as bool;
      var historySaved = true;
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
      } catch (e, stackTrace) {
        historySaved = false;
        AppLogger.error(
          'Hasil prediksi tidak dapat disimpan ke riwayat',
          e,
          stackTrace,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/prediction',
        arguments: {
          'fruitName': fruitName,
          'ripenessStatus': ripenessStatus,
          'confidence': confidence,
          'isConfident': isConfident,
          'historySaved': historySaved,
          'imagePath': imagePath,
        },
      );
    } catch (e) {
      if (!mounted) return;
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
                'Ambil foto mangga dengan kamera perangkat atau pilih gambar dari galeri untuk dianalisis.',
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
                    child: _isBusy
                        ? AppLoadingState(
                            message: _isAnalyzing
                                ? 'Menganalisis kematangan dengan AI...'
                                : 'Membuka pemilih gambar...',
                          )
                        : _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
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
                                'Siap Memindai',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.textCharcoal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pilih kamera atau gambar dari galeri',
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
                    text: _isAnalyzing
                        ? 'Sedang Memproses AI...'
                        : _isPickingImage
                        ? 'Membuka Kamera...'
                        : _selectedImage == null
                        ? 'Ambil Foto dengan Kamera'
                        : 'Ambil Ulang Foto Kamera',
                    icon: Icons.camera_alt_rounded,
                    isLoading: _isBusy,
                    onPressed: _isBusy
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    text: _isPickingImage
                        ? 'Membuka Galeri...'
                        : 'Pilih dari Galeri',
                    icon: Icons.photo_library_outlined,
                    isLoading: _isBusy,
                    onPressed: _isBusy
                        ? null
                        : () => _pickImage(ImageSource.gallery),
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
