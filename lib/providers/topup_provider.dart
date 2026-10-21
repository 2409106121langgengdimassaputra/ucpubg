import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // ChangeNotifier
import '../models/paket_uc.dart';
import '../models/transaksi.dart';

// ======================================================
// TopUpProvider: pusat state bersama aplikasi.
//
//  - ChangeNotifier  : class dasar yang menyediakan mekanisme notifikasi perubahan.
//  - notifyListeners : dipanggil setelah state berubah supaya widget yang
//                      mendengarkan (Consumer / watch / select) di-rebuild.
//
// State baru di versi redesign:
//  - nickname / cekIdLoading : simulasi "cek nickname" setelah Player ID valid
//  - level member            : derived state dari total belanja (Bronze..Diamond)
// ======================================================
//
// Versi Firebase:
//  - Paket UC   : dibaca REALTIME dari koleksi 'products' (snapshots()).
//                 Jika koleksi masih kosong / gagal dibaca, dipakai daftar bawaan.
//  - Riwayat    : disimpan per user di users/{uid}/transactions (realtime).
//  - Profil     : nama, notifikasi, Player ID tersimpan di users/{uid}.
// ======================================================
class TopUpProvider extends ChangeNotifier {
  TopUpProvider({required User user})
      : _user = user,
        _nama = _namaAwal(user) {
    _mulaiListener();
  }

  final User _user;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subPaket;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subProfil;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subRiwayat;

  static String _namaAwal(User u) {
    final dn = u.displayName?.trim() ?? '';
    if (dn.isNotEmpty) return dn;
    final mail = u.email ?? '';
    return mail.contains('@') ? mail.split('@').first : 'Survivor Player';
  }

  DocumentReference<Map<String, dynamic>> get _docUser =>
      _db.collection('users').doc(_user.uid);
  CollectionReference<Map<String, dynamic>> get _kolTransaksi =>
      _docUser.collection('transactions');

  // Daftar paket bawaan (fallback bila Firestore kosong). Harga simulasi.
  static const List<PaketUc> paketBawaan = [
    PaketUc(ucDasar: 60, harga: 15000),
    PaketUc(ucDasar: 300, bonus: 25, harga: 75000),
    PaketUc(ucDasar: 600, bonus: 60, harga: 150000, tag: 'Terlaris'),
    PaketUc(ucDasar: 1500, bonus: 300, harga: 385000),
    PaketUc(ucDasar: 3000, bonus: 850, harga: 765000, tag: 'Hemat'),
    PaketUc(ucDasar: 6000, bonus: 2100, harga: 1525000, tag: 'Best Value'),
  ];

  // Tingkatan member berdasarkan total belanja (nama, batas minimal)
  static const List<(String, int)> _tingkat = [
    ('Bronze', 0),
    ('Silver', 100000),
    ('Gold', 300000),
    ('Platinum', 750000),
    ('Diamond', 1500000),
  ];

  static const List<String> _nickSimulasi = [
    'ShadowSniper', 'NoobMaster69', 'ChickenHunter', 'VikendiKing',
    'RushB_Pro', 'ErangelLegend', 'SilentPeeker', 'ClutchGod',
    'MiramarWolf', 'DropZoneAce',
  ];

  int _currentIndex = 0;
  String _playerId = '';
  String _idText = '';
  String? _nickname;
  bool _cekIdLoading = false;
  String _searchQuery = '';
  PaketUc? _selectedPaket;
  String _nama;
  List<PaketUc> _paket = paketBawaan;
  bool _paketLoading = true;
  String? _paketError;
  bool _riwayatLoading = true;
  bool _notifAktif = true;
  final List<Transaksi> _riwayat = [];
  Uint8List? _foto; // foto profil (disimpan sebagai teks base64 di Firestore)
  String? _fotoBase64;
  bool _paketDariFirestore = false;
  bool _disposed = false; // mencegah notifyListeners() setelah provider dibuang

  // ----- Getter (UI hanya membaca, tidak mengubah langsung) -----
  int get currentIndex => _currentIndex;
  String get playerId => _playerId;
  String get idText => _idText;
  String? get nickname => _nickname;
  bool get cekIdLoading => _cekIdLoading;
  String get searchQuery => _searchQuery;
  PaketUc? get selectedPaket => _selectedPaket;
  String get nama => _nama;
  String get email => _user.email ?? '';
  Uint8List? get foto => _foto;
  bool get paketLoading => _paketLoading;
  String? get paketError => _paketError;
  bool get riwayatLoading => _riwayatLoading;
  bool get paketDariFirestore => _paketDariFirestore;
  bool get notifAktif => _notifAktif;
  List<Transaksi> get riwayat => List.unmodifiable(_riwayat);

  // ----- Derived state -----
  bool get idValid => _idText.length >= 8 && _idText.length <= 12;
  bool get idTerverifikasi => idValid && _nickname != null;

  // Tombol lanjut aktif jika akun terverifikasi dan paket sudah dipilih
  bool get bisaLanjut => idTerverifikasi && _selectedPaket != null;

  // Alasan tombol belum aktif: dipakai UI untuk memberi petunjuk ke user
  String get petunjukLanjut {
    if (!idValid) return 'Masukkan Player ID dulu';
    if (_cekIdLoading || _nickname == null) return 'Memeriksa akun...';
    if (_selectedPaket == null) return 'Pilih nominal UC';
    return '';
  }

  List<PaketUc> get paketTampil => _paket
      .where((p) => p.nama.toLowerCase().contains(_searchQuery))
      .toList();

  // Statistik profil
  int get jumlahTransaksi => _riwayat.length;
  int get totalBelanja => _riwayat.fold<int>(0, (sum, t) => sum + t.harga);
  int get totalUc => _riwayat.fold<int>(0, (sum, t) => sum + t.ucTotal);
  int get jumlahDiproses => _riwayat.where((t) => !t.berhasil).length;

  // Level member (derived dari totalBelanja)
  int get _idxLevel {
    var hasil = 0;
    for (var i = 0; i < _tingkat.length; i++) {
      if (totalBelanja >= _tingkat[i].$2) hasil = i;
    }
    return hasil;
  }

  String get levelNama => _tingkat[_idxLevel].$1;
  bool get levelMaks => _idxLevel == _tingkat.length - 1;
  String get levelBerikut => levelMaks ? '' : _tingkat[_idxLevel + 1].$1;
  int get sisaKeLevelBerikut =>
      levelMaks ? 0 : _tingkat[_idxLevel + 1].$2 - totalBelanja;
  double get progressLevel {
    if (levelMaks) return 1;
    final awal = _tingkat[_idxLevel].$2;
    final akhir = _tingkat[_idxLevel + 1].$2;
    return ((totalBelanja - awal) / (akhir - awal)).clamp(0.0, 1.0).toDouble();
  }

  // ----- Listener Firestore (realtime) -----
  void _mulaiListener() {
    // 1) Paket UC: koleksi 'products'
    _subPaket = _db.collection('products').orderBy('harga').snapshots().listen(
      (snap) {
        final hasil = <PaketUc>[];
        for (final d in snap.docs) {
          try {
            hasil.add(PaketUc.fromMap(d.data()));
          } catch (_) {
            // dokumen cacat (field kurang) dilewati
          }
        }
        _paketDariFirestore = hasil.isNotEmpty;
        _paket = hasil.isNotEmpty ? hasil : paketBawaan;
        _paketLoading = false;
        _paketError = null;
        _kabari();
      },
      onError: (Object e) {
        _paket = paketBawaan;
        _paketDariFirestore = false;
        _paketLoading = false;
        _paketError = 'Gagal memuat paket dari server, memakai data bawaan.';
        _kabari();
      },
    );

    // 2) Profil user: users/{uid}
    _subProfil = _docUser.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final n = data['nama'];
      if (n is String && n.trim().isNotEmpty) _nama = n;
      final notif = data['notifAktif'];
      if (notif is bool) _notifAktif = notif;
      final pid = data['playerId'];
      if (pid is String && pid.isNotEmpty) _playerId = pid;
      final f = data['fotoBase64'];
      final fotoBaru = (f is String && f.isNotEmpty) ? f : null;
      if (fotoBaru != _fotoBase64) {
        _fotoBase64 = fotoBaru;
        try {
          _foto = fotoBaru == null ? null : base64Decode(fotoBaru);
        } catch (_) {
          _foto = null;
        }
      }
      _kabari();
    }, onError: (Object e) {});

    // 3) Riwayat transaksi: users/{uid}/transactions
    _subRiwayat =
        _kolTransaksi.orderBy('waktu', descending: true).snapshots().listen(
      (snap) {
        _riwayat
          ..clear()
          ..addAll(snap.docs.map((d) => Transaksi.fromMap(d.id, d.data())));
        _riwayatLoading = false;
        _kabari();
      },
      onError: (Object e) {
        _riwayatLoading = false;
        _kabari();
      },
    );
  }

  // notifyListeners yang aman setelah provider dibuang
  void _kabari() {
    if (!_disposed) notifyListeners();
  }

  // ----- Aksi -----
  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setIdText(String value) {
    _idText = value;
    _nickname = null;
    if (idValid) {
      _cariNickname(value);
    } else {
      _cekIdLoading = false;
    }
    notifyListeners();
  }

  // Simulasi pengecekan akun ke server (Future.delayed). Nickname hanya
  // contoh dari daftar lokal, bukan data akun sungguhan.
  Future<void> _cariNickname(String id) async {
    _cekIdLoading = true;
    await Future.delayed(const Duration(milliseconds: 900));
    if (_disposed || id != _idText) return; // ID sudah berubah, abaikan hasil lama
    final angka = int.tryParse(id.substring(id.length - 2)) ?? 0;
    _nickname = _nickSimulasi[angka % _nickSimulasi.length];
    _cekIdLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.toLowerCase().trim();
    notifyListeners();
  }

  void pilihPaket(PaketUc paket) {
    _selectedPaket = paket;
    notifyListeners();
  }

  void simpanPlayerId() {
    _playerId = _idText;
    notifyListeners();
    _simpanProfil({'playerId': _idText});
  }

  void setNama(String value) {
    _nama = value;
    notifyListeners();
    _simpanProfil({'nama': value});
    _user.updateDisplayName(value).catchError((_) {});
  }

  void setNotif(bool value) {
    _notifAktif = value;
    notifyListeners();
    _simpanProfil({'notifAktif': value});
  }

  // Simpan foto profil. Gambar sudah dikecilkan di halaman profil, lalu
  // diubah jadi teks base64 dan disimpan di dokumen users/{uid}.
  Future<void> setFoto(Uint8List bytes) async {
    final b64 = base64Encode(bytes);
    _foto = bytes;
    _fotoBase64 = b64;
    notifyListeners();
    await _docUser.set({'fotoBase64': b64}, SetOptions(merge: true));
  }

  Future<void> hapusFoto() async {
    _foto = null;
    _fotoBase64 = null;
    notifyListeners();
    await _docUser.set({'fotoBase64': FieldValue.delete()}, SetOptions(merge: true));
  }

  // Simpan sebagian field profil (merge = tidak menimpa field lain)
  void _simpanProfil(Map<String, dynamic> data) {
    _docUser.set({
      ...data,
      'email': _user.email,
    }, SetOptions(merge: true)).catchError((Object e) {
      debugPrint('Gagal simpan profil: $e');
    });
  }

  // Dipanggil dari ConfirmPage setelah user menekan "Bayar".
  // Mengembalikan transaksi agar halaman sukses bisa menampilkannya.
  Transaksi tambahTransaksi(PaketUc paket, String playerId, String metode) {
    final transaksi = Transaksi(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      uc: paket.nama,
      ucTotal: paket.total,
      playerId: playerId,
      harga: paket.harga,
      metode: metode,
      waktu: DateTime.now(),
      status: 'Diproses',
    );
    // Tulis ke Firestore. Listener riwayat langsung menampilkannya (bahkan
    // sebelum server membalas), jadi tidak perlu menambah ke list manual.
    _kolTransaksi.doc(transaksi.id).set(transaksi.toMap()).catchError((Object e) {
      debugPrint('Gagal simpan transaksi: $e');
    });
    _selectedPaket = null; // reset pilihan, Player ID tetap untuk top up ulang
    notifyListeners();

    // Simulasi proses server: 3 detik kemudian status menjadi 'Berhasil'.
    Future.delayed(const Duration(seconds: 3), () {
      _kolTransaksi.doc(transaksi.id).update({'status': 'Berhasil'}).catchError(
        (Object e) {
          debugPrint('Gagal update status: $e');
        },
      );
    });
    return transaksi;
  }

  void hapusTransaksi(String id) {
    _kolTransaksi.doc(id).delete().catchError((Object e) {
      debugPrint('Gagal hapus transaksi: $e');
    });
  }

  // Dipakai tombol "Urungkan" setelah geser-untuk-hapus
  void pulihkanTransaksi(Transaksi transaksi, int index) {
    // Urutan mengikuti 'waktu', jadi index tidak dipakai; cukup tulis ulang.
    _kolTransaksi.doc(transaksi.id).set(transaksi.toMap()).catchError(
      (Object e) {
        debugPrint('Gagal pulihkan transaksi: $e');
      },
    );
  }

  void hapusSemua() {
    final batch = _db.batch();
    for (final t in _riwayat) {
      batch.delete(_kolTransaksi.doc(t.id));
    }
    batch.commit().catchError((Object e) {
      debugPrint('Gagal hapus semua: $e');
    });
  }

  // ----- Logout -----
  Future<void> logout() => FirebaseAuth.instance.signOut();

  // ----- Seeding (khusus pengembangan) -----
  // Mengisi koleksi 'products' dengan paket bawaan. Rules produksi melarang
  // write ke 'products', jadi pakai HANYA saat rules dibuka sementara
  // (lihat panduan). Mengembalikan jumlah paket yang ditulis.
  Future<int> seedPaket() async {
    final batch = _db.batch();
    for (final p in paketBawaan) {
      batch.set(_db.collection('products').doc('uc_${p.total}'), p.toMap());
    }
    await batch.commit();
    return paketBawaan.length;
  }

  @override
  void dispose() {
    _disposed = true;
    _subPaket?.cancel();
    _subProfil?.cancel();
    _subRiwayat?.cancel();
    super.dispose();
  }
}