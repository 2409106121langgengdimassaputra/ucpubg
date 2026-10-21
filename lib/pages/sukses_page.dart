import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaksi.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/detail_row.dart';

// ======================================================
// HALAMAN SUKSES: tampil setelah bayar.
// Consumer membuat pelacak status ikut berubah saat provider mengubah
// 'Diproses' -> 'Berhasil' (3 detik setelah transaksi dibuat).
// ======================================================
class SuksesPage extends StatelessWidget {
  final Transaksi transaksi;
  const SuksesPage({super.key, required this.transaksi});

  // Kembali ke halaman utama lalu pindah tab
  void _keluar(BuildContext context, int tab) {
    context.read<TopUpProvider>().setTab(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // tombol back sistem = kembali ke beranda
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _keluar(context, 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Consumer<TopUpProvider>(
            builder: (context, topup, child) {
              // Status terbaru dari provider (objek 'transaksi' bisa sudah usang)
              final berhasil = transaksi.berhasil ||
                  topup.riwayat.any((t) => t.id == transaksi.id && t.berhasil);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  children: [
                    // Animasi centang: membesar dengan efek memantul
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 52, color: AppColors.onAccent),
                      ),
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        berhasil ? 'UC berhasil dikirim!' : 'Pembayaran diterima',
                        key: ValueKey(berhasil),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      berhasil
                          ? '${transaksi.uc} sudah masuk ke akun ${transaksi.playerId}. Selamat bermain!'
                          : 'Pesananmu sedang diproses, biasanya hanya beberapa detik.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _pelacak(berhasil),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                      decoration: AppTheme.kartu(),
                      child: Column(
                        children: [
                          DetailRow(label: 'ID Transaksi', value: transaksi.kode),
                          DetailRow(
                              label: 'Waktu',
                              value: formatTanggal(transaksi.waktu)),
                          DetailRow(
                              label: 'Player ID', value: transaksi.playerId),
                          DetailRow(label: 'Paket', value: transaksi.uc),
                          DetailRow(label: 'Metode', value: transaksi.metode),
                          const Divider(height: 20),
                          DetailRow(
                            label: 'Total bayar',
                            value: formatRupiah(transaksi.harga),
                            tebal: true,
                            warnaNilai: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _keluar(context, 1),
                      child: const Text('Lihat Riwayat'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _keluar(context, 0),
                      child: const Text('Top Up Lagi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Pelacak 3 langkah: pembayaran -> proses -> UC terkirim
  Widget _pelacak(bool berhasil) {
    Widget langkah(String teks, bool selesai, bool aktif) {
      return Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selesai ? AppColors.success : AppColors.surfaceHigh,
                border: Border.all(
                    color: selesai
                        ? AppColors.success
                        : (aktif ? AppColors.accent : AppColors.border),
                    width: 1.5),
              ),
              child: selesai
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: AppColors.onAccent)
                  : aktif
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent))
                      : null,
            ),
            const SizedBox(height: 6),
            Text(teks,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: selesai || aktif
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.kartu(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          langkah('Pembayaran\nditerima', true, false),
          langkah('Memproses\npesanan', berhasil, !berhasil),
          langkah('UC masuk\nke akun', berhasil, false),
        ],
      ),
    );
  }
}
