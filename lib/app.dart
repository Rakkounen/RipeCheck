import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/prediction/prediction_screen.dart';
import 'features/history/history_screen.dart';
import 'features/fruit_guide/fruit_guide_screen.dart';
import 'features/feedback/feedback_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/auth/auth_screen.dart';

class RipeCheckApp extends StatelessWidget {
  const RipeCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/prediction': (context) => const PredictionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/fruit_guide': (context) => const FruitGuideScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/auth': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AuthScreen(initialIsRegister: args?['isRegister'] ?? false);
        },
      },
    );
  }
}
