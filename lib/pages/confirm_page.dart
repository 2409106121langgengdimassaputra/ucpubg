import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/paket_uc.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/detail_row.dart';
import '../widgets/step_title.dart';
import '../widgets/uc_coin.dart';
import 'sukses_page.dart';

// Data satu metode pembayaran (tampilan saja)
class _Metode {
  final String nama;
  final String ket;
  final IconData ikon;
  final Color warna;
  const _Metode(this.nama, this.ket, this.ikon, this.warna);
}

// ======================================================
// HALAMAN 2: KONFIRMASI & PEMBAYARAN
// State lokal (setState): _metode, _setuju, _isLoading.
// ======================================================
class ConfirmPage extends StatefulWidget {
  final String playerId;
  final String nickname;
  final PaketUc paket;

  const ConfirmPage({
    super.key,
    required this.playerId,
    required this.nickname,
    required this.paket,
  });

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  static const List<_Metode> _daftarMetode = [
    _Metode('DANA', 'E-wallet', Icons.account_balance_wallet_rounded,
        Color(0xFF118EEA)),
    _Metode('OVO', 'E-wallet', Icons.account_balance_wallet_rounded,
        Color(0xFF6B3FB5)),
    _Metode('GoPay', 'E-wallet', Icons.account_balance_wallet_rounded,
        Color(0xFF00AED6)),
    _Metode('QRIS', 'Scan dari aplikasi apa pun', Icons.qr_code_2_rounded,
        Color(0xFFE6382F)),
    _Metode('Transfer Bank', 'Virtual account', Icons.account_balance_rounded,
        Color(0xFF2E9E5B)),
  ];

  String? _metode;
  bool _setuju = false;
  bool _isLoading = false;

  bool get _bisaBayar => _metode != null && _setuju && !_isLoading;

  Future<void> _bayar() async {
    final navigator = Navigator.of(context);
    final provider = context.read<TopUpProvider>();

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulasi pembayaran
    if (!mounted) return;

    final transaksi =
        provider.tambahTransaksi(widget.paket, widget.playerId, _metode!);
    // pushReplacement: halaman konfirmasi diganti halaman sukses
    // (user tidak bisa "back" ke form pembayaran yang sudah selesai)
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => SuksesPage(transaksi: transaksi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paket = widget.paket;
    // PopScope: cegah kembali saat pembayaran sedang diproses
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Konfirmasi Top Up')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kartuPesanan(paket),
                const SizedBox(height: 28),
                const StepTitle(nomor: 3, judul: 'Pilih pembayaran'),
                const SizedBox(height: 12),
                ..._daftarMetode.map(_tileMetode),
                const SizedBox(height: 12),
                _persetujuan(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _barBayar(paket),
      ),
    );
  }

  Widget _kartuPesanan(PaketUc paket) {
    return Container(
      decoration: AppTheme.kartu(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(
              children: [
                const UcCoin(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PUBG MOBILE',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                      const SizedBox(height: 2),
                      Text('${formatRibuan(paket.total)} UC',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      if (paket.punyaBonus)
                        Text(
                            '${formatRibuan(paket.ucDasar)} UC + ${formatRibuan(paket.bonus)} bonus',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Column(
              children: [
                DetailRow(label: 'Player ID', value: widget.playerId),
                DetailRow(label: 'Nickname', value: widget.nickname),
                const Divider(height: 20),
                DetailRow(
                  label: 'Total bayar',
                  value: formatRupiah(paket.harga),
                  tebal: true,
                  warnaNilai: AppColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Satu pilihan metode: kartu yang bisa diketuk, bukan chip kecil
  Widget _tileMetode(_Metode m) {
    final aktif = _metode == m.nama;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: _isLoading ? null : () => setState(() => _metode = m.nama),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.kartu(
              selected: aktif,
              warna: aktif
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.surface,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: m.warna.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.ikon, color: m.warna),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(m.ket,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Radio buatan sendiri
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: aktif ? AppColors.accent : AppColors.border,
                      width: aktif ? 6.5 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _persetujuan() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isLoading ? null : () => setState(() => _setuju = !_setuju),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _setuju,
              activeColor: AppColors.accent,
              checkColor: AppColors.onAccent,
              side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _setuju = v ?? false),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Data yang saya masukkan sudah benar. UC yang sudah dikirim tidak dapat dibatalkan.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barBayar(PaketUc paket) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: _bisaBayar ? _bayar : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.accent),
                    )
                  : Text('Bayar ${formatRupiah(paket.harga)}'),
            ),
            if (!_bisaBayar && !_isLoading) ...[
              const SizedBox(height: 6),
              Text(
                _metode == null
                    ? 'Pilih metode pembayaran'
                    : 'Centang persetujuan untuk melanjutkan',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
