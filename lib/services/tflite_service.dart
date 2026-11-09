import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Interpreter? _interpreter;
  List<String> _labels = [];
  List<String> get labels => _labels;

  static const int inputSize = 224;

  Future<void> loadModel() async {
    if (_isLoaded && _interpreter != null) {
      AppLogger.log('Model TFLite sudah dimuat sebelumnya.');
      return;
    }

    _isLoaded = false;
    try {
      AppLogger.log('Memuat model dan label TFLite...');

      final labelsData = await rootBundle.loadString(AppConstants.labelsPath);
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (_labels.isEmpty) {
        throw StateError('Daftar label model kosong.');
      }

      _interpreter = await Interpreter.fromAsset(
        AppConstants.modelPath,
        options: InterpreterOptions()..threads = 4,
      );

      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      if (inputTensors.length != 1 || outputTensors.length != 1) {
        throw StateError('Model harus memiliki satu input tensor dan satu output tensor.');
      }

      final inputShape = inputTensors.single.shape;
      final outputShape = outputTensors.single.shape;
      if (inputShape.length != 4 ||
          inputShape[0] != 1 ||
          inputShape[1] != inputSize ||
          inputShape[2] != inputSize ||
          inputShape[3] != 3 ||
          outputShape.length != 2 ||
          outputShape[0] != 1 ||
          outputShape[1] != _labels.length) {
        throw StateError(
          'Bentuk tensor model tidak sesuai dengan ukuran gambar atau jumlah label.',
        );
      }

      _isLoaded = true;
      AppLogger.log(
        'Model TFLite dan ${_labels.length} label berhasil dimuat.',
      );
    } catch (e, stackTrace) {
      _interpreter?.close();
      _interpreter = null;
      _labels = [];
      _isLoaded = false;
      AppLogger.error('Gagal memuat model TFLite', e, stackTrace);
      rethrow;
    }
  }

  /// Menjalankan model klasifikasi dan mengembalikan label teratas beserta confidence.
  Future<Map<String, dynamic>> predictImage(String imagePath) async {
    if (!_isLoaded || _interpreter == null) {
      await loadModel();
    }

    try {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('File gambar tidak ditemukan di path: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Format gambar tidak dapat dibaca.');
      }

      // Resize gambar ke ukuran input model (224 x 224)
      final resizedImage = img.copyResize(
        decodedImage,
        width: inputSize,
        height: inputSize,
      );

      // Siapkan buffer tensor input berdimensi [1, 224, 224, 3] dengan nilai float [0..255]
      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
          ),
        ),
      );

      final outputTensor = List.generate(
        1,
        (_) => List.filled(_labels.length, 0.0),
      );

      _interpreter!.run(inputTensor, outputTensor);
      final probabilities = List<double>.from(outputTensor[0]);
      var bestIndex = 0;
      var highestProb = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > highestProb) {
          highestProb = probabilities[i];
          bestIndex = i;
        }
      }
      AppLogger.log(
        'TFLite raw probabilities: $probabilities, bestIndex: $bestIndex (${_labels[bestIndex]})',
      );

      final confidence = math.max(0.01, math.min(1.0, highestProb));
      final predictedLabel = _labels[bestIndex];
      final isConfident = confidence >= 0.60;

      String fruitName = 'Mangga Harumanis';
      String ripenessStatus = 'Matang';

      if (predictedLabel.contains('Busuk')) {
        ripenessStatus = 'Busuk';
        fruitName = predictedLabel.replaceAll('Busuk', '').trim();
      } else if (predictedLabel.contains('Setengah Matang')) {
        ripenessStatus = 'Setengah Matang';
        fruitName = predictedLabel.replaceAll('Setengah Matang', '').trim();
      } else if (predictedLabel.contains('Mentah')) {
        ripenessStatus = 'Mentah';
        fruitName = predictedLabel.replaceAll('Mentah', '').trim();
      } else if (predictedLabel.contains('Matang')) {
        ripenessStatus = 'Matang';
        fruitName = predictedLabel.replaceAll('Matang', '').trim();
      } else {
        fruitName = predictedLabel;
      }

      return {
        'label': predictedLabel,
        'fruitName': fruitName,
        'ripenessStatus': ripenessStatus,
        'confidence': confidence,
        'isConfident': isConfident,
        'allProbabilities': probabilities,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Gagal melakukan prediksi pada gambar', e, stackTrace);
      rethrow;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    _labels = [];
  }
}
