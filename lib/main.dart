import 'package:flutter/material.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/main_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: SilverGuideApp()));
}

class SilverGuideApp extends StatelessWidget {
  const SilverGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silver Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Terapkan tema Autumn
      home: const MainNavigationScaffold(),
    );
  }
}