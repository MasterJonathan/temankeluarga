import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:teman_keluarga/main_navigation.dart';
import 'package:teman_keluarga/features/authentication/presentation/login_page.dart';
import 'package:teman_keluarga/features/authentication/presentation/auth_controller.dart';
import 'package:teman_keluarga/features/profile/presentation/profile_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teman_keluarga/firebase_options.dart';
import 'package:teman_keluarga/services/notification_service.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Anda bisa melakukan inisialisasi firebase core di sini jika perlu akses DB
  // Tapi untuk sekadar menampilkan notif, Android/iOS otomatis menanganinya jika payload ada 'notification'
  debugPrint("Handling background message: ${message.messageId}");
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final notifService = NotificationService();
  await notifService.init();

  runApp(const ProviderScope(child: SilverGuideApp()));
}

class SilverGuideApp extends ConsumerWidget {
  const SilverGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau Status Login
    final isLoggedIn = ref.watch(authStateProvider);

    // Pantau Ukuran Teks
    final asyncUserProfile = ref.watch(profileControllerProvider);
    final double textSize = asyncUserProfile.when(
      data: (user) => user.textSize,
      loading: () => 1.0,
      error: (_, _) => 1.0,
    );

    return MaterialApp(
      title: 'Silver Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textSize)),
          child: child!,
        );
      },
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
