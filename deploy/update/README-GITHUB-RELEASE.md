# App Update via GitHub Release (Android)

Panduan ini untuk distribusi APK tanpa Play Store, dengan notifikasi update otomatis dari file manifest JSON.

## Prasyarat

1. Repository GitHub bersifat publik (atau link raw/asset bisa diakses user).
2. App dibuild dengan `--dart-define=APP_UPDATE_MANIFEST_URL=...`.
3. File manifest publik ada di path tetap, disarankan:
   - `deploy/update/app-update.json`

## Rilis Pertama (Bridge Release)

Rilis ini wajib sekali untuk memastikan semua user punya APK yang sudah tahu URL manifest.

### 1) Set versi aplikasi

Update `pubspec.yaml` menggunakan format:

- `version: 1.0.2+1`

Catatan:

- `1.0.2` = versi yang dibandingkan untuk popup update
- `+1` = build number internal Android

### 2) Pastikan manifest live sudah ada

Gunakan file live:

- `deploy/update/app-update.json`

Jangan pakai file template untuk URL produksi.

### 3) Build APK release dengan manifest URL

```bash
flutter build apk --release --dart-define=APP_UPDATE_MANIFEST_URL=https://raw.githubusercontent.com/<owner>/<repo>/main/deploy/update/app-update.json
```

Output default:

- `build/app/outputs/flutter-apk/app-release.apk`

### 4) Buat GitHub Release

1. Buat tag, contoh `v1.0.2`
2. Buat release dari tag itu
3. Upload asset `app-release.apk`

Contoh URL asset:

- `https://github.com/<owner>/<repo>/releases/download/v1.0.2/app-release.apk`

### 5) Update manifest live

Edit `deploy/update/app-update.json` agar menunjuk release terbaru, contoh:

```json
{
  "latest_version": "1.0.2",
  "min_supported_version": "1.0.0",
  "force_update": false,
  "title": "Update Tersedia",
  "message": "Versi terbaru aplikasi sudah tersedia.",
  "changelog": "- Perbaikan bug\n- Peningkatan performa",
  "apk_url": "https://github.com/<owner>/<repo>/releases/download/v1.0.2/app-release.apk"
}
```

Lalu commit + push.

## Rilis Berikutnya (Setiap Ada Fitur Baru)

1. Naikkan versi di `pubspec.yaml` (mis. `1.0.3+2`).
2. Build APK dengan command `--dart-define` yang sama.
3. Buat tag/release baru (mis. `v1.0.3`) dan upload APK.
4. Update `deploy/update/app-update.json`:
   - `latest_version`: `1.0.3` (tanpa huruf `v`)
   - `apk_url`: URL release asset versi baru
   - sesuaikan `force_update` / `min_supported_version`
5. Commit + push manifest.

User dengan versi lama akan melihat popup update saat membuka Home.

## Validasi Cepat

1. Buka URL manifest dari browser HP:
   - harus `200 OK`
   - harus JSON valid
2. Buka `apk_url` dari browser HP:
   - file APK bisa diunduh
3. Cek versi user lama < `latest_version` di manifest.

## Troubleshooting Umum

- Popup tidak muncul:
  - APK user lama belum dibuild dengan `APP_UPDATE_MANIFEST_URL`
  - URL manifest salah/404/private
  - `latest_version` sama dengan versi terpasang
- Tombol update tidak jalan:
  - `apk_url` salah atau asset release tidak ada
- Manifest sudah diubah tapi app belum baca versi baru:
  - file belum di-push
  - URL mengarah ke path/file yang berbeda
