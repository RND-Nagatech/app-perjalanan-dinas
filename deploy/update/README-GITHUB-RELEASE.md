# App Update via GitHub Release (Android)

Dokumen ini menyiapkan alur update APK tanpa Play Store.

## 1) Build APK terbaru

```bash
flutter build apk --release
```

Output default:

- `build/app/outputs/flutter-apk/app-release.apk`

## 2) Buat GitHub Release

1. Buat tag versi, contoh: `v1.0.1`
2. Buat release dari tag tersebut
3. Upload asset APK: `app-release.apk`

Contoh URL APK di release:

- `https://github.com/<owner>/<repo>/releases/download/v1.0.1/app-release.apk`

## 3) Publish manifest update (JSON)

1. Salin `deploy/update/app-update-manifest.template.json`
2. Ubah nilai sesuai release terbaru
3. Simpan sebagai file publik, contoh:
   - GitHub Pages: `https://<owner>.github.io/<repo>/app-update.json`
   - Raw branch publik: `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/deploy/update/app-update.json`

Field penting:

- `latest_version`: versi app terbaru (contoh `1.0.1`)
- `apk_url`: link APK dari GitHub Release
- `force_update`: `true` jika wajib update
- `min_supported_version`: versi minimal yang masih diizinkan

## 4) Jalankan app dengan URL manifest

Saat run/debug:

```bash
flutter run --dart-define=APP_UPDATE_MANIFEST_URL=https://<manifest-url>/app-update.json
```

Saat build release:

```bash
flutter build apk --release --dart-define=APP_UPDATE_MANIFEST_URL=https://<manifest-url>/app-update.json
```

## 5) Cara rilis berikutnya

1. Update versi di `pubspec.yaml` (mis. `1.0.2+3`)
2. Build APK
3. Upload ke GitHub Release tag `v1.0.2`
4. Update `app-update.json`:
   - `latest_version` jadi `1.0.2`
   - `apk_url` ke release terbaru
   - sesuaikan `force_update` jika perlu

Aplikasi user lama akan membaca manifest saat masuk Home dan menampilkan popup update otomatis bila ada versi baru.
