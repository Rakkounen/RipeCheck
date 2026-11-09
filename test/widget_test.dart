import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:project_mobile/app.dart';
import 'package:project_mobile/core/constants/app_constants.dart';
import 'package:project_mobile/data/models/fruit_prediction_model.dart';
import 'package:project_mobile/data/repositories/prediction_repository.dart';
import 'package:project_mobile/features/home/home_screen.dart';
import 'package:project_mobile/features/onboarding/onboarding_screen.dart';
import 'package:project_mobile/features/prediction/prediction_screen.dart';
import 'package:project_mobile/features/scanner/scanner_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Scanner menunggu pengguna memilih kamera atau galeri', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));

    expect(find.text('Siap Memindai'), findsOneWidget);
    expect(find.text('Ambil Foto dengan Kamera'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
  });

  testWidgets('PredictionScreen menampilkan ketidakpastian dan kegagalan riwayat', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PredictionScreen(
          ripenessStatus: 'Mentah',
          confidence: 0.4,
          isConfident: false,
          historySaved: false,
        ),
      ),
    );

    expect(
      find.text(
        'Foto belum dapat dianalisis dengan yakin. Silakan ambil foto ulang dengan pencahayaan yang lebih baik.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Hasil analisis berhasil dibuat, tetapi tidak dapat disimpan ke riwayat.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('masih asam dan keras'), findsOneWidget);
  });

  testWidgets('SplashScreen membuka Beranda dan menampilkan tombol CTA utama D3', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOnboardingSeen: true,
    });

    await tester.pumpWidget(const RipeCheckApp());

    // Memverifikasi Splash Screen tampil
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    // Menunggu inisialisasi selesai dan navigasi ke Beranda
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Verifikasi Komponen D3 Beranda
    expect(find.text('Pindai dengan Kamera'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Pemindaian terakhir'), findsOneWidget);
    expect(find.text('Lihat Semua'), findsOneWidget);
    expect(find.text('Panduan Buah'), findsOneWidget);
  });

  testWidgets('Pengguna baru diarahkan ke Onboarding dari Splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOnboardingSeen: false,
    });

    await tester.pumpWidget(const RipeCheckApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Memverifikasi navigasi ke Onboarding Langkah 1 (Kenali Buahmu)
    expect(find.text('Kenali Buahmu'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });

  testWidgets('HomeScreen menampilkan empty state jika belum ada riwayat pemindaian', (WidgetTester tester) async {
    final repo = PredictionRepository();
    await repo.clearHistory();

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi empty state tanpa ilustrasi sesuai spesifikasi D3
    expect(find.text('Belum ada pemindaian'), findsOneWidget);
    expect(find.text('Mulai dengan memindai buah pertamamu.'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.text('Panduan Buah'), findsOneWidget);
  });

  testWidgets('HomeScreen menampilkan daftar baris pemindaian terakhir jika ada data', (WidgetTester tester) async {
    final repo = PredictionRepository();
    await repo.clearHistory();
    await repo.savePrediction(
      FruitPredictionModel(
        id: '1',
        fruitName: 'Apel Fuji',
        ripenessStatus: 'Matang / Segar',
        confidence: 0.95,
        imagePath: '',
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi item tampil dengan nama buah dan chip status
    expect(find.text('Apel Fuji'), findsOneWidget);
    expect(find.text('Matang / Segar'), findsOneWidget);
  });

  testWidgets('OnboardingScreen 3 langkah berjalan runtut hingga Mulai', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOnboardingSeen: false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const OnboardingScreen(),
        routes: {
          '/home': (context) => const Scaffold(body: Text('Beranda')),
        },
      ),
    );

    // Langkah 1: Kenali Buahmu
    expect(find.text('Kenali Buahmu'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    // Tekan Lanjut -> ke Langkah 2: Cara Memindai
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Langkah 2: Cara Memindai
    expect(find.text('Cara Memindai'), findsOneWidget);
    expect(find.text('Cahaya Cukup'), findsOneWidget);
    expect(find.text('Buah di Tengah Bingkai'), findsOneWidget);
    expect(find.text('Ambil Foto'), findsOneWidget);

    // Tekan Lanjut -> ke Langkah 3: Izin Akses
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Langkah 3: Izin Akses
    expect(find.text('Izin Akses'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('Nanti Saja'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);

    // Tekan Mulai -> Menyimpan status onboarding dan pindah ke Beranda
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppConstants.prefOnboardingSeen), isTrue);
    expect(find.text('Beranda'), findsOneWidget);
  });
}
