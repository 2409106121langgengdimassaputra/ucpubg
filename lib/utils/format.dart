// Helper format rupiah: 1525000 -> 'Rp1.525.000'
String formatRupiah(int angka) => 'Rp${formatRibuan(angka)}';

// Sisipkan titik ribuan: 8100 -> '8.100'
String formatRibuan(int angka) {
  return angka.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
}

// Format tanggal sederhana tanpa package intl: '15 Okt 2026, 14:05'
String formatTanggal(DateTime t) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final jam = t.hour.toString().padLeft(2, '0');
  final menit = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${bulan[t.month - 1]} ${t.year}, $jam:$menit';
}
