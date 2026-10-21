# TopUp UC PUBGM

Aplikasi simulasi top up UC PUBG Mobile yang dibuat dengan **Flutter**, memakai **Provider** untuk state management dan **Firebase** (Authentication + Cloud Firestore) sebagai backend.

> Aplikasi ini dibuat untuk pembelajaran. Pembayaran dan pengiriman UC hanya **simulasi**. Tidak berafiliasi dengan PUBG MOBILE, KRAFTON, atau Tencent.

---

## 1. Tentang Aplikasi

TopUp UC PUBGM adalah aplikasi untuk membeli UC (mata uang di dalam game) dengan alur yang mirip toko top up sungguhan:

1. Pengguna mendaftar atau login.
2. Memasukkan **Player ID**, lalu aplikasi "memeriksa" akun dan menampilkan nickname (simulasi).
3. Memilih nominal UC.
4. Memilih metode pembayaran, lalu menekan **Bayar**.
5. Transaksi tersimpan di database dan statusnya berubah dari **Diproses** menjadi **Berhasil**.
6. Riwayat transaksi bisa dilihat kapan saja, bahkan dari perangkat lain dengan akun yang sama.

### Fitur

- Registrasi, login, dan logout (Firebase Authentication, Email/Password)
- Reset password lewat email
- Daftar paket UC dibaca **realtime** dari Firestore (harga bisa diubah dari Firebase Console tanpa update aplikasi)
- Pencarian paket, pemeriksaan Player ID, dan konfirmasi pembayaran
- Riwayat transaksi tersimpan per akun, bisa difilter, dihapus (dengan tombol Urungkan), dan dilihat detailnya
- Profil: nama, Player ID, level member berdasarkan total belanja, pengaturan notifikasi
- Pesan error login dalam bahasa Indonesia
- Tema gelap bergaya game

### Teknologi

| Bagian | Teknologi |
|---|---|
| Framework | Flutter (Dart) |
| State management | Provider |
| Login | Firebase Authentication |
| Database | Cloud Firestore |
| Platform | Android dan Web |

---

## 2. Struktur Folder

```
lib/
├── main.dart                  # Titik awal: menyalakan Firebase lalu menjalankan aplikasi
├── auth_gate.dart             # Pemantau status login (login -> app, belum -> halaman login)
├── firebase_options.dart      # Konfigurasi project Firebase (dibuat oleh flutterfire configure)
├── models/
│   ├── paket_uc.dart          # Model paket UC (fromMap / toMap untuk Firestore)
│   └── transaksi.dart         # Model transaksi (fromMap / toMap untuk Firestore)
├── providers/
│   └── topup_provider.dart    # State bersama + semua komunikasi ke Firestore
├── pages/
│   ├── login_page.dart        # Login dan registrasi
│   ├── main_shell.dart        # Kerangka dengan navigasi bawah
│   ├── home_page.dart         # Top up: Player ID dan pilih paket
│   ├── confirm_page.dart      # Pilih metode dan bayar
│   ├── sukses_page.dart       # Halaman sukses dan pelacak status
│   ├── riwayat_page.dart      # Riwayat transaksi
│   └── profil_page.dart       # Profil dan logout
├── theme/ widgets/ utils/     # Tema, komponen UI, dan fungsi bantu
firestore.rules                # Aturan keamanan Firestore
```

---

## 3. Cara Kerja Aplikasi

### Alur umum

```
Buka aplikasi
   |
   v
main.dart  -> Firebase.initializeApp (sambung ke project Firebase)
   |
   v
AuthGate   -> cek status login lewat authStateChanges()
   |-- belum login -> LoginPage -> login / daftar -> (AuthGate otomatis pindah ke aplikasi)
   |-- sudah login -> MainShell (tab Top Up, Riwayat, Profil)
                        |
                        |-- baca paket UC     (koleksi products, realtime)
                        |-- baca profil       (users/{uid})
                        |-- baca riwayat      (users/{uid}/transactions, realtime)
                        |
Tekan "Bayar" -> simpan transaksi ke Firestore (status "Diproses")
              -> 3 detik kemudian status diubah menjadi "Berhasil"
Tekan "Keluar akun" -> signOut -> AuthGate kembali ke LoginPage
```

### Penjelasan bagian penting

- **Firebase.initializeApp** di `main.dart` menyambungkan aplikasi ke project Firebase. Harus dijalankan sebelum `runApp`.
- **AuthGate** memakai `FirebaseAuth.instance.authStateChanges()`, yaitu stream yang berubah otomatis saat pengguna login, daftar, atau logout. Karena itu tidak perlu menulis kode pindah halaman manual.
- **TopUpProvider** menyimpan state bersama dan berhubungan dengan Firestore. Provider dibuat **per pengguna** (berdasarkan uid) dan dipasang **di atas MaterialApp** supaya halaman yang dibuka lewat `Navigator.push` (Konfirmasi dan Sukses) tetap bisa memakainya.
- **snapshots()** membuat listener realtime. Saat data di Firestore berubah (misalnya harga diubah di Console), tampilan ikut berubah tanpa refresh.
- Jika koleksi `products` masih kosong atau gagal dibaca, aplikasi memakai daftar paket bawaan di kode (cadangan), sehingga aplikasi tetap bisa dipakai.

---

## 4. Struktur Database (Cloud Firestore)

```
products/                      <- data bersama, dibaca semua pengguna yang login
   {id}:  name, ucDasar, bonus, harga, tag

users/
   {uid}/                      <- data pribadi tiap akun (uid dari Authentication)
        nama, email, notifAktif, playerId
        transactions/
             {id}:  uc, ucTotal, playerId, harga, metode, waktu, status
```

### Aturan keamanan (`firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /products/{productId} {
      allow read: if request.auth != null;   // hanya yang sudah login boleh baca
      allow write: if false;                 // tidak boleh ditulis dari aplikasi
    }

    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /transactions/{trxId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

Artinya: paket hanya bisa dibaca pengguna yang login, dan setiap pengguna hanya bisa membaca dan menulis datanya sendiri.

---

## 5. Cara Menghubungkan ke Database (Firebase)

### a. Siapkan alat (sekali saja)

1. Install **Node.js** (LTS) dari https://nodejs.org
2. Install Firebase CLI:
   ```
   npm install -g firebase-tools
   ```
3. Login:
   ```
   firebase login
   ```
4. Install FlutterFire CLI:
   ```
   dart pub global activate flutterfire_cli
   ```

### b. Buat project Firebase

1. Buka https://console.firebase.google.com lalu klik **Create a project**.
2. Isi nama project, Google Analytics boleh dimatikan, lalu **Create project**.
3. Catat **Project ID** (Project settings, tab General).

### c. Hubungkan aplikasi Flutter ke project

Di terminal, di folder proyek:

```
flutter pub get
dart pub global run flutterfire_cli:flutterfire configure --project=ISI_PROJECT_ID --platforms=android,web
```

Perintah ini membuat otomatis `lib/firebase_options.dart` (berisi konfigurasi project) dan `android/app/google-services.json`. Ganti `ISI_PROJECT_ID` dengan Project ID milikmu. Kalau perintah `flutterfire` dikenali langsung di terminal, boleh dipakai tanpa awalan `dart pub global run flutterfire_cli:`.

### d. Aktifkan Authentication

Firebase Console, **Build > Authentication > Get started > Sign-in method > Email/Password > Enable > Save**.

### e. Buat Cloud Firestore

Firebase Console, **Build > Firestore Database > Create database**. Pilih lokasi terdekat (misalnya `asia-southeast2` Jakarta) dan mode **Production**, lalu **Create**.

### f. Pasang Rules

Buka tab **Rules** di Firestore, hapus isinya, tempel isi file `firestore.rules`, lalu **Publish**.

### g. Isi data paket (opsional)

Tanpa langkah ini aplikasi memakai paket bawaan. Untuk mengisi koleksi `products`:

1. Ubah rules sementara agar `products` boleh ditulis oleh pengguna yang login (`allow read, write: if request.auth != null;`), lalu Publish.
2. Jalankan aplikasi dalam mode debug, login, buka tab **Profil**, lalu ketuk **Seed paket ke Firestore (debug)**.
3. **Kembalikan rules** ke isi `firestore.rules` lalu Publish lagi.

Atau isi manual lewat Console: buat koleksi `products`, lalu tambah dokumen dengan field `name` (string), `ucDasar`, `bonus`, `harga` (number), dan `tag` (string, boleh kosong).

---

## 6. Menjalankan Aplikasi

```
flutter pub get
flutter run -d chrome     # web
flutter run               # Android (emulator atau HP dengan USB debugging)
```

## 7. Build APK

```
flutter build apk --release
```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 8. Fitur Opsional: Email Notifikasi ke Pemilik

Notifikasi email saat ada transaksi baru dapat ditambahkan memakai layanan gratis **EmailJS** (paket `http` dan file `lib/services/email_notifier.dart`). Fitur ini hanya aktif jika Service ID, Template ID, dan Public Key EmailJS sudah diisi.

---

## 9. Catatan

- Pembayaran, pengecekan nickname, dan pengiriman UC hanya simulasi.
- Pastikan Rules sudah dipasang dan Email/Password sudah diaktifkan, jika tidak login atau penyimpanan data akan gagal.
