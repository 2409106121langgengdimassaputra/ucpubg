import 'package:flutter_test/flutter_test.dart';
import 'package:ucpubg/models/paket_uc.dart';
import 'package:ucpubg/utils/format.dart';

// Tes unit sederhana (tidak butuh Firebase).
void main() {
  test('PaketUc.fromMap membaca data dokumen Firestore', () {
    final p = PaketUc.fromMap({
      'ucDasar': 300,
      'bonus': 25,
      'harga': 75000,
      'tag': '',
    });
    expect(p.total, 325);
    expect(p.nama, '325 UC');
    expect(p.tag, isNull);
  });

  test('formatRupiah', () {
    expect(formatRupiah(1525000), 'Rp1.525.000');
  });
}
