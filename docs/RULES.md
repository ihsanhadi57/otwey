# Rules: OTWEY

Aturan ini berlaku untuk semua orang yang mengerjakan project ini. Kalau ada yang bertentangan dengan `docs/PRD.md`, PRD yang menang, lalu perbarui file ini.

## 1. Prinsip produk (tidak bisa ditawar)

1. **Rencana harus mungkin dijalani.** Tidak boleh ada itinerary yang membuat user telat ke tujuan berjam tetap atau ketinggalan kereta pulang.
2. **Tujuan Wajib tidak pernah dihapus diam diam.** Kalau tidak muat, user diberi pilihan.
3. **Dua arah.** Jangan pernah menulis "Bandung" secara mati di UI, logika, atau nama variabel. Pakai `destinationCity` / `{kota}`.
4. **Logika waktu deterministik.** Penjadwalan dijalankan di kode dan diuji unit test.
5. **Tidak mengarang data.** Jadwal kereta, jam buka, tarif harus dari tabel. Kalau kosong, tampilkan "belum ada data", jangan menebak.

## 2. Tech stack

| Bagian | Pilihan | Catatan |
| --- | --- | --- |
| SDK | **Flutter 3.50**, Dart 3.14 | `environment: sdk ^3.14.0, flutter >=3.50.0` |
| UI | `material_ui` | Flutter 3.50 men-deprecate `package:flutter/material.dart`. Selalu import `package:material_ui/material_ui.dart` |
| State | `flutter_riverpod` 3 | Tanpa code generation |
| Routing | `go_router` 18 | |
| Backend | `supabase_flutter` 2 | Tetap di v2 selama hackathon. Migrasi ke v3 nanti (`anonKey` jadi `publishableKey`, `order()` jadi ascending default) |
| SVG | `flutter_svg` | Untuk logo dan Oti |
| Font | Dibundel di `assets/fonts/` | **Tidak memakai `google_fonts`**: bisa offline dan menghindari bentrok tipe `TextTheme` antara `package:flutter/material.dart` dan `material_ui` |
| Animasi (nanti) | `rive` | Untuk Oti beranimasi, setelah MVP |

Aturan dependency:
* Jangan menambah package baru tanpa alasan tertulis di PR atau pesan commit.
* Package yang API publiknya memakai tipe Material lama (contoh menerima `TextTheme` atau `ColorScheme`) harus dicek dulu. Kalau belum mendukung `material_ui`, cari alternatif.
* `MaterialUiCompatibilityBridge` sudah dipasang di `MaterialApp.router(builder: ...)` untuk package yang hanya membaca `Theme.of(context)`.
* Selalu tulis arah urutan secara eksplisit di query Supabase: `.order('kolom', ascending: true)`.

## 3. Arsitektur Flutter

Clean architecture, feature first.

```
lib/
  main.dart
  app.dart
  core/
    assets/        # AppAssets, OtiMood: path aset brand
    config/        # AppConfig, Env (dart-define)
    theme/         # AppColors (ThemeExtension), AppTheme, AppTypography, AppSpacing, AppRadius
    router/        # go_router
    copy/          # AppCopy: semua teks UI
    utils/         # helper murni (waktu, format)
    widgets/       # widget umum lintas fitur, termasuk OtweyLogo dan Oti
  features/
    <fitur>/
      domain/        # entity, enum, repository interface, service murni (tanpa Flutter, tanpa Supabase)
      data/          # model DTO, datasource Supabase/HTTP, implementasi repository
      presentation/  # page, provider/notifier
        widgets/     # widget modular khusus fitur ini, terpisah dari page
```

Aturan:
* `domain` tidak boleh import `package:flutter` atau `package:supabase_flutter`.
* `presentation` tidak boleh memanggil Supabase langsung. Selalu lewat repository.
* Satu file satu kelas publik utama. Nama file `snake_case.dart`.
* Halaman diberi akhiran `Page`, widget potongan tanpa akhiran khusus, notifier `...Notifier`, provider `...Provider`.
* **Widget harus modular.** Pecah UI jadi widget kecil yang fokus satu tugas. Jangan menumpuk semua UI di file page. Page hanya menyusun widget dan membaca state.
* Widget khusus satu fitur disimpan di `features/<fitur>/presentation/widgets/`, satu file satu widget. Potongan UI yang dipakai lebih dari sekali wajib diekstrak ke widget sendiri, bukan disalin antar page.
* Widget yang dipakai lintas fitur tetap di `core/widgets/`. Kalau widget fitur mulai dipakai fitur lain, pindahkan ke `core/widgets/`.

### State management (Riverpod 3)
* Pakai `Provider`, `FutureProvider`, `NotifierProvider`, `AsyncNotifierProvider`. Hindari `StateProvider` dan `ChangeNotifierProvider` (legacy).
* State form setup trip disimpan di satu `TripDraftNotifier` supaya semua langkah membaca sumber yang sama.
* Tidak ada logika bisnis di widget. Widget hanya membaca state dan memanggil method notifier.

### Routing
* `go_router` dengan path satu kata huruf kecil: `/arah`, `/waktu`, `/tujuan`, `/vibes`, `/hasil`, `/tersimpan`.
* Nama path dan nama route didefinisikan sebagai konstanta di `AppRoutes`, tidak ditulis ulang sebagai string.

### Waktu
* Di domain, jam disimpan sebagai **menit sejak tengah malam (`int`)** agar perhitungan mudah dan bebas zona waktu. Konversi ke `TimeOfDay`/string hanya di presentation.
* Zona waktu tetap `Asia/Jakarta`.
* Format tampil `09.25` (titik, 24 jam). Durasi `45 mnt`, `2 j 10 mnt`.

### Konfigurasi dan rahasia
* Nilai rahasia lewat `--dart-define-from-file=.env`. `.env` masuk `.gitignore`, contoh di `.env.example`.
* **Google Maps / Routes API key tidak boleh ada di aplikasi.** Panggil lewat Supabase Edge Function.
* Yang boleh di aplikasi: `SUPABASE_URL` dan `SUPABASE_ANON_KEY` (memang publik, dilindungi RLS).

### Testing
* Setiap aturan planner (`docs/PRD.md` bagian 8) punya unit test di `test/features/planner/`.
* Skenario demo PRD bagian 12 wajib jadi satu test end to end di level domain.

## 4. Database (Supabase)

### Penamaan
| Prefix | Isi | Contoh |
| --- | --- | --- |
| `mst_` | Master / referensi, diisi admin | `mst_station`, `mst_place` |
| `trx_` | Transaksi milik user | `trx_plan`, `trx_plan_pin`, `trx_plan_item` |
| `cache_` | Data turunan, aman dihapus | `cache_travel_time` |
| `fn_` | Fungsi | `fn_place_open_near` |
| `trg_` | Trigger | `trg_trx_plan_updated` |

* Nama tabel dan kolom `snake_case`, tabel **singular**.
* PK master referensi kecil: `serial`/`smallserial` atau `code text`. PK transaksi: `uuid`.
* Semua tabel punya `created_at`. Tabel yang bisa diubah punya `updated_at` + trigger `set_updated_at()`.
* Master memakai `is_active` (soft delete), tidak dihapus fisik.
* Koordinat `geography(point, 4326)`.
* Jam operasional dan jadwal memakai tipe `time`, tanggal perjalanan `date`.

### Migrasi
* Semua perubahan skema lewat file baru di `supabase/migrations/`, format `YYYYMMDDHHMMSS_deskripsi.sql`. Jangan ubah migrasi yang sudah dijalankan.
* Seed data terpisah di `supabase/seed.sql`.

### Keamanan
* RLS aktif di semua tabel.
* `mst_`: baca publik, tulis hanya service role.
* `trx_`: hanya pemilik (`auth.uid() = user_id`).
* `cache_`: tanpa policy, hanya Edge Function.

## 5. Desain dan UI

Sumber kebenaran: `docs/DESIGN_SYSTEM.md`, `docs/BRAND.md`, dan `lib/core/theme/`.

* Warna hanya dari `AppColors` / `Theme.of(context).colorScheme`. **Dilarang hex langsung di widget.**
* Spasi dan radius hanya dari `AppSpacing` dan `AppRadius`.
* Font:
  * **Fredoka** hanya untuk judul bernuansa brand: `display` (headlineMedium) dan `title` (titleLarge), misalnya judul onboarding, judul hasil itinerary, judul sheet.
  * **Plus Jakarta Sans** untuk semua teks UI lain: nama tempat, isi, label, tombol, caption.
  * **JetBrains Mono** untuk jam, durasi, nomor kereta lewat `AppTypography.time` / `timeSm`.
  * Jangan memakai Fredoka untuk paragraf atau teks di bawah 17px.
* Logo dan Oti hanya lewat widget `OtweyLogo` dan `Oti` (`lib/core/widgets/brand.dart`). Jangan mewarnai ulang, memutar, atau meregangkan SVG.
* `logoOrange` dan `sun` hanya untuk ilustrasi dan latar dekoratif, **bukan** untuk teks atau tombol (kontras teks kurang). Tombol tetap `brand`.
* Ekspresi Oti mengikuti peta momen di `docs/BRAND.md` (contoh: `mepet` hanya saat waktu mepet atau konflik).
* Target sentuh ≥ 44px. CTA utama di bawah layar, lebar penuh.
* Status (aman, mepet, tidak keburu, prioritas) selalu ditulis sebagai teks, tidak hanya warna.
* Setiap layar yang memuat data punya state: loading, kosong, error, sukses.
* Uji di light dan dark, di layar kecil (360 x 640) dan besar.
* Hindari: gradien ungu biru, kartu dengan garis kiri berwarna, emoji di UI, ilustrasi stok generik.

## 6. Copy (gaya bahasa)

* Bahasa Indonesia santai gaya Gen Z, benchmark Gojek: pakai "kamu", kalimat pendek.
* **Jelas dulu, lucu belakangan.** Slang maksimal satu per kalimat, hanya yang umum (gas, sip, aman, mepet, santuy, healing, bocil, sultan, cus, kuy).
* Error, konflik, dan dialog hapus: tanpa candaan, langsung beri jalan keluar.
* Tombol diawali kata kerja, maksimal 3 kata.
* Tanpa emoji. Tanda seru maksimal satu per layar.
* Semua teks UI ada di `lib/core/copy/app_copy.dart`, tidak ditulis langsung di widget.
* Ikuti kamus istilah di `docs/DESIGN_SYSTEM.md` (contoh: selalu "itinerary", "kereta pulang", "tujuan kamu").

## 7. Git

* Branch: `main` (siap demo), `feat/<nama>`, `fix/<nama>`.
* Commit: Conventional Commits, contoh `feat(planner): lock fixed time pins`.
* Jangan commit `.env`, key, atau data pribadi.

## 8. Aturan mengerjakan project

1. Baca `docs/PRD.md`, `docs/RULES.md`, `docs/DESIGN_SYSTEM.md`, dan `docs/BRAND.md` sebelum mengerjakan apa pun.
2. Import Material selalu `package:material_ui/material_ui.dart`. Kalau menemukan `package:flutter/material.dart`, jalankan `dart fix --apply --code=migrate_design_widgets`.
3. Kerjakan bertahap sesuai tahap di PRD bagian 15. Satu tahap selesai dan bisa dijalankan sebelum lanjut.
4. Jangan menambah dependency baru tanpa alasan tertulis di pesan.
5. Jangan mengubah nama tabel, enum, atau token desain tanpa memperbarui dokumen terkait.
6. Kalau data atau keputusan belum ada (lihat PRD bagian 14), tanyakan atau tandai `TODO(hadi):`, jangan mengarang.
7. Tulis penjelasan singkat dan konkret, tanpa em dash.

## 9. Data (tambahan 18 Nov 2026)

* Rencana dan prioritas data: `docs/DATA_PLAN.md`.
* Data contoh hanya boleh ada di `lib/features/*/data/demo_*.dart` dan diberi `TODO(hadi):`. Jangan menyebar angka contoh ke widget atau domain.
* Jangan scraping Google Maps. Tempat diisi manual atau dari OpenStreetMap (atribusi ODbL), setiap baris punya `source` dan `source_ref`.
* Jadwal kereta cepat dan feeder hanya dari sumber resmi, dengan tanggal berlaku. `fn_generate_whoosh_trip` hanya untuk data dummy.
* Ongkos ojol dan waktu tempuh yang belum dari sumber nyata ditampilkan sebagai perkiraan ("±").
* Seed Supabase dan mode demo offline memakai file sumber yang sama (`supabase/seed/*.csv`), supaya demo tidak beda dengan database.

## 10. Komponen UI wajib (tambahan 18 Nov 2026)

* Ikon hanya lewat `OtwIconView`. Jangan memakai `Icons.*` bawaan Material.
* Input mengikuti aturan di `docs/DESIGN_SYSTEM.md` bagian "Aturan input, ikon, dan state": navy = dipilih, oranye = aksi.
* Feedback lewat `showOtwSnackBar` dan `showOtwConfirmDialog`. Jangan memakai `SnackBar` atau `AlertDialog` mentah.
