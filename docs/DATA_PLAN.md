# Rencana Data: OTWEY

Status 18 Nov 2026. Semua layar sudah jalan, tapi seluruh datanya masih contoh di
`lib/features/*/data/demo_*.dart`. Dokumen ini menjawab: data apa yang dibutuhkan,
dari mana, berapa banyak, dan urutan mengisinya.

## Sumber kebenaran data

`supabase/seed/*.csv` adalah satu-satunya sumber data master. Dari CSV ini:
* aplikasi membaca data saat mode offline (`SeedCatalog`)
* `dart run tool/seed_import.dart` menghasilkan `supabase/seed.sql` untuk Supabase

Migrasi `20261119000000_seed_master.sql` adalah impor awal yang sudah dipindah ke CSV.
Perubahan data berikutnya dilakukan di CSV, bukan di migrasi.
Kolom `service_days` (`1;2;3;4;5;6`, kosong = tiap hari) ada di `whoosh_trip.csv` dan
`feeder_schedule.csv`. `test/features/real_seed_test.dart` menjaga CSV tetap valid.

## Prinsip

1. **Sempitkan wilayah, perdalam data.** Demo tidak butuh seluruh Bandung dan Jakarta.
   Cukup 2 zona per kota yang datanya benar.
2. **Jadwal resmi dulu, tempat belakangan.** Rencana yang salah jam keretanya lebih fatal
   daripada rekomendasi tempat yang kurang banyak.
3. **Tidak scraping Google Maps.** Ketentuan Google Maps Platform melarang scraping dan
   membatasi penyimpanan konten Places. Isi tempat secara manual dengan sumber dicatat,
   atau pakai OpenStreetMap (lisensi ODbL, wajib atribusi).
4. **Setiap baris punya sumber dan tanggal.** Kolom `source`, `source_ref`, `is_verified`
   sudah ada di `mst_place`. Untuk jadwal, catat tanggal berlaku.
5. **Angka perkiraan diberi label.** Ongkos ojol dan waktu tempuh tanpa data nyata tampil
   dengan kata "perkiraan" atau "±".

## Zona demo

| Kota | Zona | Alasan |
| --- | --- | --- |
| Bandung | Braga, Asia Afrika, Alun-alun | Jalan kaki antar tempat, dekat Stasiun Bandung (ujung KA Feeder) |
| Bandung | Dago | Kafe dan kantor, contoh perpindahan ojol vs Metro Jabar Trans |
| Jakarta | Kota Tua | Wisata sejarah, contoh arah Bandung ke Jakarta |
| Jakarta | Blok M dan sekitar | Kuliner, terhubung MRT dan TransJakarta |

Titik berangkat user (rumah, kantor) boleh di mana saja di kota asal. Yang perlu data
hanya rute dari titik itu ke stasiun kereta cepat.

## Daftar data

Prioritas: **P0** wajib sebelum demo, **P1** sangat membantu, **P2** setelah hackathon.

| # | Data | Tabel | Jumlah minimal | Sumber | Prioritas | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Stasiun kereta cepat dan stasiun feeder | `mst_station` | 4 + 2 | Internal KCIC | P0 | Seed ada, cek koordinat |
| 2 | Jadwal kereta cepat dua arah, satu hari kerja | `mst_whoosh_trip`, `mst_whoosh_trip_stop` | Semua perjalanan 1 hari | Jadwal resmi KCIC (internal) | P0 | Masih pola asumsi menit 00 dan 25 |
| 3 | Jadwal KA Feeder Padalarang ⇄ Bandung | `mst_feeder_route`, `mst_feeder_schedule` | Semua perjalanan 1 hari | KCIC atau KAI | P0 | Belum |
| 4 | Rute akses ke dan dari stasiun (transum) | tabel baru `mst_access_route` + `mst_access_step` | 3 sampai 5 rute per stasiun | Situs resmi operator (LRT Jabodebek, TransJakarta, Metro Jabar Trans, DAMRI) | P0 | Masih contoh di `demo_itinerary.dart` |
| 5 | Tempat (nama, koordinat, alamat, kategori, atribut, harga, durasi kunjung, deskripsi) | `mst_place` dan relasinya | 40 sampai 60 (10 sampai 15 per zona) | Manual + OSM, cek ke situs atau akun resmi tempat | P0 | 8 contoh |
| 6 | Jam buka per hari | `mst_place_opening_hour` | Semua tempat di #5 | Situs atau akun resmi tempat, OSM `opening_hours` | P0 | Contoh |
| 7 | Waktu tempuh antar titik (jalan kaki, motor, transum) | `cache_travel_time` | Matriks antar tempat di zona yang sama + ke stasiun | Dihitung sekali (OpenRouteService atau Google Routes lewat Edge Function), disimpan | P1 | Belum |
| 8 | Aturan ongkos ojol (dasar + per km, per zona) | tabel baru `mst_fare_rule` | 2 baris (motor, mobil) | Ketentuan tarif resmi yang berlaku | P1 | Masih angka contoh |
| 9 | Alasan rekomendasi per tempat ("Kenapa ini?") | dihasilkan planner | - | Template kalimat dari aturan planner | P1 | Contoh |
| 10 | Foto tempat | `mst_place.photo_url` | 1 per tempat | Foto sendiri atau berlisensi | P2 | Belum |
| 11 | Wishlist user | tabel baru `trx_wishlist` | - | Aplikasi | P1 | State lokal |

## Cara isi tiap data

### Jadwal kereta cepat (#2)
* Minta jadwal resmi yang berlaku ke tim internal. Catat nomor kereta, jam berangkat
  dan tiba di setiap stasiun, dan tanggal berlaku.
* Isi lewat CSV `supabase/seed/whoosh_trip.csv`, bukan `fn_generate_whoosh_trip` (fungsi itu
  hanya untuk data dummy).

### KA Feeder dan rute akses (#3, #4)
* Satu rute akses = urutan langkah: jalan kaki, naik koridor, turun, jalan kaki.
* Yang perlu dicatat per langkah: moda, nama layanan dan koridor, titik naik dan turun,
  durasi, tarif, jam operasi, sumber.
* Cukup rute dari halte atau stasiun transum terdekat ke stasiun kereta cepat. Bagian
  "rumah ke halte" dihitung sebagai jalan kaki atau ojol dari koordinat user.
* Template: `supabase/seed/access_route.csv`.

### Tempat (#5, #6)
* Kandidat otomatis: `dart run tool/osm_candidates.dart` menarik tempat dari Overpass
  (OSM) untuk 4 zona demo ke `supabase/seed/candidates/osm_candidates.csv`, lengkap
  dengan `opening_hours` mentah dan hasil parse. File itu bukan seed.
* Pilih baris yang layak, tulis deskripsi, lalu salin ke `place.csv` dan
  `place_opening_hour.csv`, kemudian `dart run tool/seed_import.dart`.
* Status 20 Nov 2026: 104 tempat (Bandung 56, Jakarta 48; zona Jakarta ditambah Thamrin, Menteng, Gambir, SCBD, Kemang lewat `--kota=Jakarta`). 59 di antaranya dari kandidat
  OSM yang punya jam buka. Deskripsinya singkat, ditulis dari tag OSM, dan
  `is_verified = false`, jadi perlu dicek dan dipercantik. 10 tempat lama masih tanpa jam buka.
* Mulai dari OpenStreetMap (Overpass) untuk daftar kandidat dan koordinat di zona demo,
  lalu pilih dan lengkapi manual.
* Deskripsi ditulis sendiri, 1 sampai 3 kalimat, gaya bahasa sesuai DESIGN_SYSTEM.
* Isi `source` (`osm` / `manual`), `source_ref` (id OSM atau URL sumber), `is_verified`.
* Template: `supabase/seed/place.csv` dan `supabase/seed/place_opening_hour.csv`.

### Rute transum dalam kota (offline)
* `dart run tool/city_transit.dart` (atau `make transit`) menghitung rute transum antar
  semua tempat Jakarta dan Stasiun Halim, hasilnya `supabase/seed/derived/city_transit_jakarta.json`
  (data turunan, jangan diedit tangan). Planner memakainya untuk opsi transum.
* Bus: GTFS TransJakarta resmi dari Mobility Database (id 1909), diunduh otomatis ke
  `.dart_tool/otwey/`. Berisi BRT, Angkutan Umum Integrasi, Mikrotrans, Royaltrans.
* Rel: MRT, LRT Jabodebek, LRT Jakarta, KRL tidak punya GTFS publik. Urutan stasiun ditulis di
  `tool/data/rail_stations.csv`, koordinat dari OSM, headway/kecepatan/tarif di
  `tool/data/rail_lines.csv` masih estimasi (lihat kolom `source`).
* Model berbasis frekuensi: tunggu = setengah headway, bukan jadwal per menit. Jam operasional
  belum dipertimbangkan. Bandung belum punya data GTFS.
* Status 20 Nov 2026: 2.122 rute antar 49 titik Jakarta, median 41 menit.
* Akses stasiun dari titik bebas (lokasi user): 280 titik ujung (stasiun rel dan halte BRT)
  dengan rute ke dan dari Stasiun Halim. Planner memilih ujung dengan total waktu terkecil
  (jalan kaki atau ojol ke ujung, lalu rute transum).

### Waktu tempuh (#7)
* Hitung sekali untuk semua pasangan titik dalam satu zona plus ke stasiun terdekat
  (60 tempat, sekitar beberapa ribu pasangan), simpan di `cache_travel_time`.
* Saat aplikasi jalan, hanya leg dari titik berangkat user yang perlu dihitung langsung.
  Kalau gagal, pakai fallback PRD 8.4 (garis lurus × 1,4) dan tandai perkiraan.

## Perubahan skema yang dibutuhkan (migrasi kedua)

| Perubahan | Untuk fitur |
| --- | --- |
| `trx_plan.travel_mode` (`campur`, `ojol`, `transum`) | Preferensi pindah antar tempat |
| `trx_plan.origin_kind`, `origin_address` | Titik berangkat |
| `trx_plan_item.leg_mode` (`ojol`, `transum`) dan `reason` | Pilihan per perpindahan dan alasan stop |
| `mst_access_route`, `mst_access_step` | Koridor transum ke stasiun |
| `mst_fare_rule` | Perkiraan ongkos ojol |
| `trx_wishlist (user_id, place_id, created_at)` + RLS | Wishlist |
| `trx_saved_origin` (opsional) | Titik tersimpan Rumah, Kantor |

## Checklist minimum sebelum demo

- [x] Jadwal kereta cepat resmi 1 hari, dua arah (GAPEKA 2025)
- [x] Jadwal KA Feeder 1 hari, dua arah
- [ ] 1 rute akses transum per stasiun yang dipakai demo (Halim, Padalarang)
- [x] 15 tempat di zona Braga/Asia Afrika/Dago dengan jam buka (dari OSM, belum dicek lapangan)
- [ ] 8 tempat di Kota Tua untuk arah sebaliknya (baru 4 berjam buka + Fatahillah akhir pekan; Blok M 12)
- [ ] Skenario demo PRD bagian 12 menghasilkan rencana yang masuk akal dengan data asli
