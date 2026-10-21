import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'providers/topup_provider.dart';
import 'theme/app_theme.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.builder});

  // Membuat MaterialApp dengan `home` yang ditentukan AuthGate
  final Widget Function(Widget home) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builder(const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ));
        }

        final user = snapshot.data;
        if (user == null) return builder(const LoginPage());

        // Provider ada DI ATAS MaterialApp, jadi semua halaman
        // (termasuk yang dibuka lewat Navigator.push) bisa memakainya.
        return ChangeNotifierProvider<TopUpProvider>(
          key: ValueKey(user.uid),
          create: (_) => TopUpProvider(user: user),
          child: builder(const MainShell()),
        );
      },
    );
  }
}