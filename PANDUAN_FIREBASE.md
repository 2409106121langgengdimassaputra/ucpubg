# Panduan Firebase — TopUp UC PUBGM

Yang sudah saya kerjakan di kode (tinggal kamu hubungkan ke project Firebase-mu):

| Modul | Di proyek ini |
|---|---|
| pubspec: firebase_core, firebase_auth, cloud_firestore | `pubspec.yaml` ✅ |
| `Firebase.initializeApp` | `lib/main.dart` ✅ |
| AuthGate (`authStateChanges`) | `lib/auth_gate.dart` ✅ |
| Login & Registrasi | `lib/pages/login_page.dart` ✅ |
| Logout (`signOut`) | tombol "Keluar akun" di `lib/pages/profil_page.dart` ✅ |
| Baca data realtime (`snapshots()`) | `lib/providers/topup_provider.dart` (koleksi `products`) ✅ |
| Rules | `firestore.rules` ✅ |

Fitur tambahan: reset password, nama tampilan, riwayat transaksi & profil tersimpan per akun di Firestore
(sinkron realtime, tetap ada walau logout/ganti HP), pesan error bahasa Indonesia, fallback data paket bawaan.

> `lib/firebase_options.dart` saat ini hanya placeholder. **Langkah 3 akan menimpanya** dengan file asli.

---
## LANGKAH 1 — Siapkan alat (sekali saja, Windows)
1. Install Node.js (nodejs.org), lalu di terminal:
   `npm install -g firebase-tools`
2. `firebase login` (login Google di browser)
3. `dart pub global activate flutterfire_cli`
4. Pastikan `%LOCALAPPDATA%\Pub\Cache\bin` ada di PATH (kalau tidak, pakai perintah cadangan `dart pub global run flutterfire_cli:flutterfire ...` di Langkah 3).

## LANGKAH 2 — Buat project Firebase
1. Buka https://console.firebase.google.com → **Create a project**.
2. Beri nama (mis. `ppb26`), Google Analytics boleh dimatikan.
3. Catat **Project ID** (Project settings → General), mis. `ppb26-dcd38`.

## LANGKAH 3 — Hubungkan Flutter ke Firebase
Buka terminal **di folder proyek `ucpubg`**:
```
flutter pub get
flutterfire configure --project=ISI_PROJECT_ID --platforms=android,web
```
Jika `flutterfire` tidak dikenali:
```
dart pub global run flutterfire_cli:flutterfire configure --project=ISI_PROJECT_ID --platforms=android,web
```
Hasilnya: `lib/firebase_options.dart` terisi asli + `android/app/google-services.json` + plugin google-services otomatis ditambahkan ke Gradle.
Ganti `ISI_PROJECT_ID` dengan Project ID-mu (bukan nama project).

## LANGKAH 4 — Aktifkan Authentication
Console → **Build → Authentication → Get started → Sign-in method → Email/Password → Enable → Save**.

## LANGKAH 5 — Buat Firestore
Console → **Build → Firestore Database → Create database** → pilih lokasi terdekat (mis. `asia-southeast2` Jakarta) → **Production mode** → Create.

## LANGKAH 6 — Pasang Rules
Firestore → tab **Rules** → hapus isinya, tempel isi file **`firestore.rules`** → **Publish**.

⚠️ Di modul tertulis `allow read: if request.auth = null;` — itu typo (error sintaks & artinya terbalik). Yang benar `request.auth != null` (hanya user login yang boleh baca). Itu yang saya pakai.

## LANGKAH 7 — Isi data paket (koleksi `products`) — opsional tapi disarankan
App tetap jalan tanpa langkah ini (memakai paket bawaan), tapi agar data benar-benar dari Firestore:

**Cara mudah (seed lewat app):**
1. Firestore → Rules → tempel isi **`firestore.rules.seed-sementara`** → Publish.
2. `flutter run` (mode debug), login, buka tab **Profil** → ketuk **"Seed paket ke Firestore (debug)"** → muncul "6 paket ditulis".
3. **PENTING:** kembalikan Rules ke isi `firestore.rules` → Publish lagi.

**Cara manual:** Firestore → Start collection `products` → 6 dokumen dengan field `ucDasar`(number), `bonus`(number), `harga`(number), `tag`(string, boleh kosong), `name`(string). Contoh: ucDasar 300, bonus 25, harga 75000.

Setelah itu coba ubah `harga` di Console → harga di app berubah **tanpa refresh** (itu `snapshots()`).

## LANGKAH 8 — Jalankan
```
flutter run -d chrome     # web
flutter run               # android (emulator / HP USB debugging)
```
Tes: Daftar akun → masuk ke app → top up → cek tab Riwayat → Profil → Keluar akun → kembali ke Login.
Cek di Console: Authentication → Users (akun muncul), Firestore → `users/{uid}/transactions` (transaksi muncul).

---
## Troubleshooting
| Gejala | Solusi |
|---|---|
| `firebase_options.dart belum di-generate` | Jalankan Langkah 3 |
| `flutterfire` tidak dikenali | Pakai `dart pub global run flutterfire_cli:flutterfire configure ...` |
| `operation-not-allowed` | Langkah 4 belum (Email/Password belum Enable) |
| `permission-denied` | Rules belum dipublish (Langkah 6) atau belum login |
| Paket tidak berubah dari Firestore | Koleksi `products` kosong → app pakai data bawaan (Langkah 7) |
| Gradle error `google-services` / `minSdk` | Jalankan ulang Langkah 3; pastikan `android/app/google-services.json` ada; `flutter clean` lalu `flutter pub get` |
| Web: layar putih | `flutter clean`, jalankan ulang; cek Console browser (F12) |
| Build Android lama pertama kali | Normal (download Gradle/Firebase SDK), tunggu |

## Catatan penamaan
Modul memakai `authGate.dart` / `loginPage.dart`; di proyek ini saya pakai `auth_gate.dart` / `pages/login_page.dart`
agar konsisten dengan penamaan snake_case file lain di proyekmu (aturan lint Dart). Fungsinya sama.
