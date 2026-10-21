import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaksi.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/detail_row.dart';
import '../widgets/status_badge.dart';
import '../widgets/uc_coin.dart';

// ======================================================
// HALAMAN 3: RIWAYAT
// State lokal: _filter. Data riwayat dimiliki TopUpProvider (Consumer).
// UX: geser kartu ke kiri untuk hapus (ada "Urungkan"), ketuk untuk detail.
// ======================================================
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const List<String> _opsiFilter = ['Semua', 'Diproses', 'Berhasil'];
  String _filter = 'Semua';

  Future<void> _konfirmasiHapusSemua() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus semua riwayat?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin == true && mounted) context.read<TopUpProvider>().hapusSemua();
  }

  // Hapus satu transaksi + SnackBar dengan tombol Urungkan
  void _hapus(Transaksi item) {
    final provider = context.read<TopUpProvider>();
    final index = provider.riwayat.indexOf(item);
    provider.hapusTransaksi(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Transaksi ${item.uc} dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => provider.pulihkanTransaksi(item, index),
        ),
      ));
  }

  // Detail transaksi dalam bottom sheet
  void _lihatDetail(Transaksi itemAwal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer<TopUpProvider>(
        // Consumer di dalam sheet: status ikut berubah jika masih diproses
        builder: (context, topup, child) {
          // Ambil data terbaru dari provider (snapshot Firestore membuat objek baru)
          final item = topup.riwayat.firstWhere(
            (t) => t.id == itemAwal.id,
            orElse: () => itemAwal,
          );
          return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const UcCoin(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Top Up ${item.uc}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  StatusBadge(berhasil: item.berhasil),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              DetailRow(label: 'ID Transaksi', value: item.kode),
              DetailRow(label: 'Waktu', value: formatTanggal(item.waktu)),
              DetailRow(label: 'Player ID', value: item.playerId),
              DetailRow(label: 'Metode', value: item.metode),
              const Divider(height: 20),
              DetailRow(
                label: 'Total bayar',
                value: formatRupiah(item.harga),
                tebal: true,
                warnaNilai: AppColors.accent,
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TopUpProvider>(
      builder: (context, topup, child) {
        final riwayat = topup.riwayat;
        final tampil = _filter == 'Semua'
            ? riwayat
            : riwayat.where((t) => t.status == _filter).toList();

        int hitung(String f) => f == 'Semua'
            ? riwayat.length
            : riwayat.where((t) => t.status == f).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi'),
            actions: [
              IconButton(
                tooltip: 'Hapus semua',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: riwayat.isEmpty ? null : _konfirmasiHapusSemua,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter: chip dengan jumlah, bisa di-scroll horizontal
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    itemCount: _opsiFilter.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _opsiFilter[i];
                      final aktif = _filter == f;
                      return ChoiceChip(
                        label: Text('$f (${hitung(f)})'),
                        selected: aktif,
                        showCheckmark: false,
                        selectedColor: AppColors.accent.withValues(alpha: 0.18),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                            color: aktif ? AppColors.accent : AppColors.border),
                        shape: const StadiumBorder(),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: aktif
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _filter = f),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: tampil.isEmpty
                      ? _kosong(riwayat.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: tampil.length,
                          itemBuilder: (context, index) =>
                              _kartuTransaksi(tampil[index]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kosong(bool belumAdaSama) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surface),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              belumAdaSama ? 'Belum ada transaksi' : 'Tidak ada transaksi di filter ini',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              belumAdaSama
                  ? 'Top up pertamamu akan muncul di sini.'
                  : 'Coba pilih filter lain.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (belumAdaSama) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () => context.read<TopUpProvider>().setTab(0),
                  child: const Text('Mulai Top Up'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kartuTransaksi(Transaksi item) {
    // Dismissible: geser ke kiri untuk menghapus
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _hapus(item),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger),
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            onTap: () => _lihatDetail(item),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.kartu(warna: Colors.transparent),
              child: Row(
                children: [
                  const UcCoin(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Up ${item.uc}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('${item.metode} - ID ${item.playerId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Text(formatTanggal(item.waktu),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatRupiah(item.harga),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 6),
                      StatusBadge(berhasil: item.berhasil),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
