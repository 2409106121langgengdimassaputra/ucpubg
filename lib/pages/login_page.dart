import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ======================================================
// LOGIN & REGISTRASI (Firebase Authentication - Email/Password)
// Setelah sukses, AuthGate otomatis memindahkan layar (tidak perlu Navigator).
// ======================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _modeDaftar = false; // false = Login, true = Registrasi
  bool _loading = false;
  bool _sembunyikan = true;
  String? _error;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_modeDaftar) {
        // Registrasi akun baru
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Simpan nama tampilan (fitur tambahan)
        await cred.user?.updateDisplayName(_namaController.text.trim());
      } else {
        // Login
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // Sukses: AuthGate mendeteksi perubahan dan memindahkan layar.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _pesanError(e));
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Fitur tambahan: reset password lewat email
  Future<void> _lupaPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Isi email dulu, lalu tekan "Lupa password?"');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link reset password dikirim ke $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _pesanError(e));
    }
  }

  String _pesanError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Login Email/Password belum diaktifkan di Firebase Console.';
      default:
        return 'Gagal (${e.code}): ${e.message ?? ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                      ),
                      child: const Icon(Icons.toll_rounded,
                          size: 44, color: AppColors.onAccent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _modeDaftar ? 'Buat Akun' : 'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modeDaftar
                          ? 'Daftar untuk mulai top up UC'
                          : 'Login untuk lanjut top up UC',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    if (_modeDaftar) ...[
                      TextFormField(
                        controller: _namaController,
                        textInputAction: TextInputAction.next,
                        maxLength: 20,
                        decoration: AppTheme.input(
                          hint: 'Nama',
                          prefix: const Icon(Icons.person_outline_rounded),
                        ).copyWith(counterText: ''),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: AppTheme.input(
                        hint: 'Email',
                        prefix: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Email wajib diisi';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _sembunyikan,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                      decoration: AppTheme.input(
                        hint: 'Password',
                        prefix: const Icon(Icons.lock_outline_rounded),
                        suffix: IconButton(
                          icon: Icon(_sembunyikan
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _sembunyikan = !_sembunyikan),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),
                    if (!_modeDaftar)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _lupaPassword,
                          child: const Text('Lupa password?'),
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.5)),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.onAccent),
                            )
                          : Text(_modeDaftar ? 'Daftar' : 'Login'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _modeDaftar = !_modeDaftar;
                                _error = null;
                              }),
                      child: Text(_modeDaftar
                          ? 'Sudah punya akun? Login'
                          : 'Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
