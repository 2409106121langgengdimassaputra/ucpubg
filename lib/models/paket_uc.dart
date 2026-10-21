// Model satu paket UC yang dijual.
// UC total = UC dasar + bonus (contoh: 300 + 25 = 325 UC).
class PaketUc {
  final int ucDasar;
  final int bonus;
  final int harga; // harga dalam rupiah
  final String? tag; // label kecil, contoh: 'Terlaris'

  const PaketUc({
    required this.ucDasar,
    this.bonus = 0,
    required this.harga,
    this.tag,
  });

  // Dibaca dari dokumen Firestore (koleksi 'products')
  factory PaketUc.fromMap(Map<String, dynamic> data) {
    final tag = data['tag'];
    return PaketUc(
      ucDasar: (data['ucDasar'] as num).toInt(),
      bonus: (data['bonus'] as num?)?.toInt() ?? 0,
      harga: (data['harga'] as num).toInt(),
      tag: (tag is String && tag.isNotEmpty) ? tag : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': nama,
        'ucDasar': ucDasar,
        'bonus': bonus,
        'harga': harga,
        'tag': tag ?? '',
      };

  int get total => ucDasar + bonus;
  String get nama => '$total UC'; // contoh: '325 UC'
  int get hargaPerUc => (harga / total).round(); // indikator kehematan
  bool get punyaBonus => bonus > 0;
}
