import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/paket_card.dart';
import '../widgets/step_title.dart';
import '../widgets/uc_coin.dart';
import 'confirm_page.dart';

// ======================================================
// HALAMAN 1: HOME (alur 2 langkah + bar checkout selalu terlihat)
// State lokal : controller & focus node TextField.
// State bersama (Provider): idText, nickname, searchQuery, selectedPaket, dll.
// ======================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _idController = TextEditingController();
  final _idFocus = FocusNode();
  final _searchFocus = FocusNode();
  bool _mengetik = false; // true saat keyboard dipakai -> bar checkout disembunyikan

  @override
  void initState() {
    super.initState();
    _idFocus.addListener(_updateFokus);
    _searchFocus.addListener(_updateFokus);
  }

  void _updateFokus() {
    final aktif = _idFocus.hasFocus || _searchFocus.hasFocus;
    if (aktif != _mengetik) setState(() => _mengetik = aktif);
  }

  @override
  void dispose() {
    _idController.dispose();
    _idFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Tempel Player ID dari clipboard (hanya angka, maksimal 12)
  Future<void> _tempel() async {
    final provider = context.read<TopUpProvider>();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final angka = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (angka.isEmpty) return;
    final id = angka.length > 12 ? angka.substring(0, 12) : angka;
    _idController.text = id;
    provider.setIdText(id);
  }

  void _lanjutKonfirmasi() {
    final topup = context.read<TopUpProvider>();
    FocusScope.of(context).unfocus();
    topup.simpanPlayerId();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmPage(
          playerId: topup.idText,
          nickname: topup.nickname ?? '-',
          paket: topup.selectedPaket!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TopUpProvider>(
      builder: (context, topup, child) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(topup),
                      const SizedBox(height: 20),
                      _banner(),
                      const SizedBox(height: 14),
                      _keunggulan(),
                      const SizedBox(height: 28),
                      _langkahPlayerId(topup),
                      const SizedBox(height: 28),
                      _langkahNominal(topup),
                    ],
                  ),
                ),
                // Bar checkout: slide masuk/keluar mengikuti fokus keyboard
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: _mengetik ? const Offset(0, 1.2) : Offset.zero,
                    child: _barCheckout(topup),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== HEADER =====
  Widget _header(TopUpProvider topup) {
    final inisial = topup.nama.trim().isEmpty
        ? '?'
        : topup.nama.trim().substring(0, 1).toUpperCase();
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
          ),
          child: Text(inisial,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onAccent)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, ${topup.nama}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const Text('TopUp UC PUBGM',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi baru')),
            ),
          ),
        ),
      ],
    );
  }

  // ===== BANNER PROMO (gradient + dekorasi, tanpa aset gambar) =====
  Widget _banner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2410), Color(0xFF1C1208), Color(0xFF14110D)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.16),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 16,
              child: Transform.rotate(
                angle: -0.2,
                child: const UcCoin(size: 84),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text('PROMO',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: AppColors.accent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Bonus UC\nhingga 2.100 UC',
                      style: TextStyle(
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Makin besar paket, makin banyak bonus',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== KEUNGGULAN =====
  Widget _keunggulan() {
    Widget item(IconData ikon, String teks) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: AppTheme.kartu(),
            child: Column(
              children: [
                Icon(ikon, size: 20, color: AppColors.accent),
                const SizedBox(height: 4),
                Text(teks,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        item(Icons.bolt_rounded, 'Instan'),
        const SizedBox(width: 10),
        item(Icons.verified_user_outlined, 'Aman'),
        const SizedBox(width: 10),
        item(Icons.support_agent_rounded, 'CS 24 Jam'),
      ],
    );
  }

  // ===== LANGKAH 1: PLAYER ID =====
  Widget _langkahPlayerId(TopUpProvider topup) {
    final ada = topup.idText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitle(
            nomor: 1, judul: 'Masukkan Player ID', selesai: topup.idTerverifikasi),
        const SizedBox(height: 12),
        TextField(
          controller: _idController,
          focusNode: _idFocus,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: (v) => context.read<TopUpProvider>().setIdText(v),
          decoration: AppTheme.input(
            hint: 'Contoh: 5123456789',
            prefix: const Icon(Icons.badge_outlined),
            error: ada && !topup.idValid ? 'Player ID harus 8-12 digit' : null,
            suffix: ada
                ? IconButton(
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _idController.clear();
                      context.read<TopUpProvider>().setIdText('');
                    },
                  )
                : TextButton(
                    onPressed: _tempel,
                    child: const Text('Tempel'),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Hasil cek akun: berubah halus antara petunjuk / loading / ditemukan
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _statusAkun(topup),
        ),
      ],
    );
  }

  Widget _statusAkun(TopUpProvider topup) {
    if (topup.cekIdLoading) {
      return const Row(
        key: ValueKey('loading'),
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Memeriksa akun...',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      );
    }
    if (topup.nickname != null) {
      return Container(
        key: const ValueKey('ditemukan'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Akun ditemukan: ',
                  style: const TextStyle(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: topup.nickname,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(
                      text: '  (simulasi)',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const Row(
      key: ValueKey('petunjuk'),
      children: [
        Icon(Icons.info_outline_rounded,
            size: 16, color: AppColors.textSecondary),
        SizedBox(width: 8),
        Expanded(
          child: Text('Cek Player ID di game: ketuk foto profil di lobi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  // ===== LANGKAH 2: NOMINAL =====
  Widget _langkahNominal(TopUpProvider topup) {
    final paket = topup.paketTampil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepTitle(
            nomor: 2,
            judul: 'Pilih nominal UC',
            selesai: topup.selectedPaket != null),
        const SizedBox(height: 12),
        TextField(
          focusNode: _searchFocus,
          onChanged: (v) => context.read<TopUpProvider>().setSearchQuery(v),
          decoration: AppTheme.input(
            hint: 'Cari paket, contoh: 660',
            prefix: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        if (paket.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 44,
                      color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  const Text('Paket tidak ditemukan',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          // LayoutBuilder + Wrap: 2 kolom, tinggi kartu mengikuti isi
          LayoutBuilder(
            builder: (context, c) {
              final lebar = (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: paket
                    .map((p) => SizedBox(
                          width: lebar,
                          child: PaketCard(
                            paket: p,
                            selected: topup.selectedPaket?.nama == p.nama,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              context.read<TopUpProvider>().pilihPaket(p);
                            },
                          ),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  // ===== BAR CHECKOUT (selalu terlihat di bawah) =====
  Widget _barCheckout(TopUpProvider topup) {
    final paket = topup.selectedPaket;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  paket == null ? 'Total bayar' : '${paket.nama} dipilih',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  paket == null ? '-' : formatRupiah(paket.harga),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: topup.bisaLanjut ? _lanjutKonfirmasi : null,
                  child: const Text('Lanjut'),
                ),
                // Petunjuk kenapa tombol belum aktif
                if (!topup.bisaLanjut) ...[
                  const SizedBox(height: 4),
                  Text(topup.petunjukLanjut,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
