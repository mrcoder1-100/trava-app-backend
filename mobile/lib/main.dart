import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/intro/intro_screen.dart';
import 'services/api_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  await LanguageService().init();
  runApp(const TravaApp());
}

class TravaApp extends StatelessWidget {
  const TravaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService().currentLanguageNotifier,
      builder: (context, currentLang, _) {
        return MaterialApp(
          key: ValueKey(currentLang),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const IntroScreen(),
        );
      },
    );
  }
}
