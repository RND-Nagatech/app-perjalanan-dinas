# Trips Apps

Aplikasi Flutter untuk pengelolaan perjalanan dinas, pengeluaran, dan riwayat aktivitas perjalanan.

## Menjalankan Proyek

1. Pastikan Flutter SDK sudah terpasang.
2. Install dependency:
   - `flutter pub get`
3. Jalankan aplikasi:
   - `flutter run`
4. Validasi statik:
   - `flutter analyze`

## Struktur Arsitektur

Setiap feature mengikuti pola Clean Architecture:

- `data/`
  - datasource remote/local
  - model/mapper
  - repository implementation
- `domain/`
  - entity
  - repository abstraction
  - usecase
  - failure
- `presentation/`
  - bloc/cubit + event/state
  - page/widget
- `injection/`
  - registrasi dependency khusus feature

## Aturan Dependency (Wajib)

1. `presentation` hanya akses `usecase`/abstraksi domain, bukan datasource.
2. `domain` tidak boleh import `data` atau `flutter` package.
3. `data` implement repository domain, tidak boleh akses UI layer.
4. `GetIt` dipakai di composition root (router/main/injection), bukan di logic inti BLoC/Cubit.

## Standar Error Handling

Gunakan alur berikut di semua feature:

1. Data source melempar `RemoteException` dengan message yang jelas.
2. Repository menangkap `RemoteException` lalu melempar `Failure` domain.
3. BLoC/Cubit menangkap `Failure` dan emit state error yang ramah user.

Pola ini membuat pesan error konsisten, mudah diuji, dan menjaga batas layer tetap bersih.

## Konvensi Implementasi

- Hindari penggunaan `Map<String, dynamic>` sebagai kontrak domain jika bisa ditipekan dengan entity.
- Gunakan constructor injection untuk dependency BLoC/Cubit.
- Jangan melakukan `close()` pada singleton BLoC yang dikelola DI global.
- Semua perubahan harus lolos `flutter analyze`.

## Catatan Tim

Jika menambah feature baru, ikuti struktur folder yang sama agar maintainability tetap tinggi dan proses review lebih cepat.

## Distribusi Update APK (Tanpa Play Store)

Panduan lengkap setup update via GitHub Release ada di:

- [deploy/update/README-GITHUB-RELEASE.md](deploy/update/README-GITHUB-RELEASE.md)

Template manifest update:

- [deploy/update/app-update-manifest.template.json](deploy/update/app-update-manifest.template.json)
