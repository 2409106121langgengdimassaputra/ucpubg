import 'package:cloud_firestore/cloud_firestore.dart';

// Model satu transaksi top up
class Transaksi {
  final String id; // id unik transaksi (dipakai untuk menghapus / update status)
  final String uc; // contoh: '325 UC'
  final int ucTotal; // jumlah UC (angka) untuk statistik profil
  final String playerId;
  final int harga;
  final String metode;
  final DateTime waktu;
  String status; // 'Diproses' -> 'Berhasil' (berubah selama aplikasi berjalan = state)

  Transaksi({
    required this.id,
    required this.uc,
    required this.ucTotal,
    required this.playerId,
    required this.harga,
    required this.metode,
    required this.waktu,
    required this.status,
  });

  // Dibaca dari dokumen Firestore (users/{uid}/transactions/{id})
  factory Transaksi.fromMap(String id, Map<String, dynamic> data) {
    final waktu = data['waktu'];
    return Transaksi(
      id: id,
      uc: data['uc'] as String? ?? '',
      ucTotal: (data['ucTotal'] as num?)?.toInt() ?? 0,
      playerId: data['playerId'] as String? ?? '',
      harga: (data['harga'] as num?)?.toInt() ?? 0,
      metode: data['metode'] as String? ?? '',
      waktu: waktu is Timestamp ? waktu.toDate() : DateTime.now(),
      status: data['status'] as String? ?? 'Diproses',
    );
  }

  Map<String, dynamic> toMap() => {
        'uc': uc,
        'ucTotal': ucTotal,
        'playerId': playerId,
        'harga': harga,
        'metode': metode,
        'waktu': Timestamp.fromDate(waktu),
        'status': status,
      };

  bool get berhasil => status == 'Berhasil';

  // Kode pendek yang enak dibaca, contoh: TRX482913
  String get kode => 'TRX${id.substring(id.length - 6)}';
}
