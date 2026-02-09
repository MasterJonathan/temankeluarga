import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/main_navigation.dart';
import 'package:silver_guide/features/authentication/presentation/login_page.dart';
import 'package:silver_guide/features/authentication/presentation/auth_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:silver_guide/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SilverGuideApp()));
}

class SilverGuideApp extends ConsumerWidget {
  const SilverGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau Status Login
    final isLoggedIn = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Silver Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Logic Routing Sederhana
      home: isLoggedIn.when(
        data: (user) =>
            user != null ? const MainNavigationScaffold() : const LoginPage(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => const LoginPage(),
      ),
    );
  }
}
