# TopUp UC PUBGM (versi redesign)

Aplikasi Flutter simulasi top up UC PUBG Mobile dengan state management **Provider**.
Versi ini fokus pada perbaikan UI/UX; arsitektur Provider tetap sama.

## Yang berubah di UI/UX
- Tema gelap bergaya game (`lib/theme/app_theme.dart`), Material 3, tanpa aset gambar
- Home berbentuk alur langkah: 1) Player ID (tempel, cek nickname simulasi) -> 2) pilih nominal
- Kartu paket menampilkan UC dasar + bonus, harga, harga per UC, dan label (Terlaris/Hemat/Best Value)
- Bar checkout selalu terlihat, ada petunjuk kenapa tombol belum aktif
- Pembayaran: kartu metode (DANA, OVO, GoPay, QRIS, Transfer Bank), halaman Sukses dengan pelacak status
- Riwayat: filter berhitung, geser untuk hapus + Urungkan, ketuk untuk detail struk
- Profil: level member (Bronze..Diamond) dari total belanja, total UC, salin Player ID
- Navigasi bawah Material 3 dengan badge jumlah transaksi diproses

## Struktur
```
lib/
  main.dart
  theme/       app_theme.dart
  models/      paket_uc.dart, transaksi.dart
  providers/   topup_provider.dart
  widgets/     uc_coin, status_badge, detail_row, step_title, paket_card
  pages/       main_shell, home_page, confirm_page, sukses_page, riwayat_page, profil_page
  utils/       format.dart
```

## Menjalankan
```
flutter clean
flutter pub get
flutter run
```
Catatan: harga, bonus, dan nickname bersifat simulasi. Tidak ada transaksi nyata.
