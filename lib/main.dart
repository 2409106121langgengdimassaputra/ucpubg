import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'firebase_options.dart'; // di-generate oleh `flutterfire configure`
import 'theme/app_theme.dart';

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum memanggil kode native/plugin.
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase SEBELUM aplikasi dijalankan.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TopUpApp());
}

class TopUpApp extends StatelessWidget {
  const TopUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthGate memutuskan home: sudah login -> MainShell, belum -> LoginPage
    return AuthGate(
      builder: (home) => MaterialApp(
        title: 'TopUp UC PUBGM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark, // tema gelap bergaya game
        home: home,
      ),
    );
  }
}