import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// ======================================================
// HALAMAN 4: PROFIL
// State lokal: _namaController, _editMode. Lifecycle: initState, dispose.
// State bersama (Provider): nama, playerId, statistik, level, notifAktif.
// ======================================================
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late TextEditingController _namaController;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: context.read<TopUpProvider>().nama);
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _mulaiEdit() {
    _namaController.text = context.read<TopUpProvider>().nama;
    setState(() => _editMode = true);
  }

  void _simpanNama() {
    final baru = _namaController.text.trim();
    if (baru.isEmpty) return;
    context.read<TopUpProvider>().setNama(baru);
    setState(() => _editMode = false);
  }

  void _salinId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Player ID disalin')));
  }

  // Pilih foto dari galeri, kecilkan, lalu simpan
  Future<void> _gantiFoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TopUpProvider>();
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400, // dikecilkan supaya muat di Firestore (maks 1 MB)
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return; // dibatalkan
      final bytes = await file.readAsBytes();
      await provider.setFoto(bytes);
      messenger.showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal mengganti foto: $e')));
    }
  }

  void _menuFoto(bool adaFoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(sheetContext);
                _gantiFoto();
              },
            ),
            if (adaFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: const Text('Hapus foto',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.read<TopUpProvider>().hapusFoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Avatar bulat: foto profil, atau huruf inisial kalau belum ada foto
  Widget _avatar(TopUpProvider topup, String inisial) {
    final foto = topup.foto;
    return GestureDetector(
      onTap: () => _menuFoto(foto != null),
      child: Stack(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                ),
              ],
            ),
            child: foto != null
                ? Image.memory(foto,
                    width: 84, height: 84, fit: BoxFit.cover, gaplessPlayback: true)
                : Text(inisial,
                    style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onAccent)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // Konfirmasi lalu keluar akun. AuthGate otomatis kembali ke LoginPage.
  Future<void> _logout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin == true && mounted) {
      await context.read<TopUpProvider>().logout(); // FirebaseAuth.signOut()
    }
  }

  // Khusus debug: isi koleksi 'products' (butuh rules write dibuka sementara)
  Future<void> _seed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await context.read<TopUpProvider>().seedPaket();
      messenger.showSnackBar(SnackBar(content: Text('$n paket ditulis ke Firestore')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Gagal seed (rules write masih false?): $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TopUpProvider>(
      builder: (context, topup, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  _kartuProfil(topup),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _tileStat(Icons.receipt_long_rounded,
                            'Transaksi', '${topup.jumlahTransaksi}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tileStat(Icons.toll_rounded, 'Total UC',
                            formatRibuan(topup.totalUc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _pengaturan(topup),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar akun'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aplikasi simulasi untuk pembelajaran. Tidak berafiliasi dengan PUBG MOBILE, KRAFTON, atau Tencent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Kartu utama: avatar, nama (bisa diedit), Player ID, level + progres
  Widget _kartuProfil(TopUpProvider topup) {
    final inisial = topup.nama.trim().isEmpty
        ? '?'
        : topup.nama.trim().substring(0, 1).toUpperCase();
    final adaId = topup.playerId.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.16),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          _avatar(topup, inisial),
          const SizedBox(height: 14),
          if (_editMode)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _namaController,
                    autofocus: true,
                    maxLength: 20,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _simpanNama(),
                    decoration: AppTheme.input(hint: 'Nama profil')
                        .copyWith(counterText: ''),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: AppColors.success),
                  onPressed: _simpanNama,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _editMode = false),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(topup.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  tooltip: 'Ubah nama',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: _mulaiEdit,
                ),
              ],
            ),
          if (topup.email.isNotEmpty)
            Text(topup.email,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          // Player ID + tombol salin
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: adaId ? () => _salinId(topup.playerId) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    adaId ? 'Player ID: ${topup.playerId}' : 'Player ID belum diisi',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (adaId) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Level member + progress ke level berikutnya
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech_rounded,
                        color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('Member ${topup.levelNama}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Text(formatRupiah(topup.totalBelanja),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: topup.progressLevel,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHigh,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topup.levelMaks
                      ? 'Level tertinggi tercapai!'
                      : '${formatRupiah(topup.sisaKeLevelBerikut)} lagi menuju ${topup.levelBerikut}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileStat(IconData ikon, String label, String nilai) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.kartu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(nilai,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _pengaturan(TopUpProvider topup) {
    return Container(
      decoration: AppTheme.kartu(),
      child: Column(
        children: [
          SwitchListTile(
            secondary:
                const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifikasi promo',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(topup.notifAktif ? 'Aktif' : 'Nonaktif'),
            value: topup.notifAktif,
            onChanged: (v) => context.read<TopUpProvider>().setNotif(v),
          ),
          const Divider(height: 1),
          if (kDebugMode) ...[
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Seed paket ke Firestore (debug)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(topup.paketDariFirestore
                  ? 'Paket sudah dibaca dari Firestore'
                  : 'Memakai data bawaan'),
              onTap: _seed,
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Bantuan & CS',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur bantuan belum tersedia (simulasi)')),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Tentang aplikasi',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'TopUp UC PUBGM',
              applicationVersion: '1.0.0',
              children: const [
                Text('Aplikasi simulasi top up UC dengan Flutter dan Provider.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}