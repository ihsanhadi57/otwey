# PRD: OTWEY

| | |
| --- | --- |
| Status | Draft v0.3, untuk Hackathon Internal KCIC. UI App v2 sudah jalan dengan data contoh |
| Pemilik | Hadi |
| Platform | Mobile Android dan iOS: Flutter 3.50 (Dart 3.14), material_ui, Riverpod, go_router |
| Backend | Supabase (PostgreSQL + PostGIS, Edge Functions) |
| Tanggal | 18 November 2026 |

Nama aplikasi di kode hanya ada di satu konstanta (`AppConfig.appName`).

---

## 1. Ringkasan

### Brand

| Elemen | Isi |
| --- | --- |
| Nama | OTWEY (dibaca "ot-wei", dari OTW + way) |
| Kategori | Smart day trip planner |
| Kepribadian | Modern, playful, explorative, praktis |
| Target | Anak muda dan urban explorer yang jalan sehari antarkota |
| Janji inti | Maksimalkan waktu di kota tujuan tanpa khawatir ketinggalan kereta pulang |
| Tagline | Make every stop count. |
| Pendamping tagline (onboarding) | Kerjaan beres, main juga sempat, pulang tetap on time. |
| Maskot | Oti: makhluk bulat oranye bertopi kondektur dan ber-ransel, bentuknya huruf o di logo |
| Logo | Wordmark "otwey" dengan huruf o tersenyum dan huruf yang melompat (Fredoka Bold, sudah jadi path) |
| Font | Fredoka untuk judul bernuansa brand, Plus Jakarta Sans untuk teks UI, JetBrains Mono untuk jam |

Aset dan aturan pakai brand: `docs/BRAND.md`.

### Produk

OTWEY adalah perencana perjalanan sehari dengan Whoosh, **dua arah**: Jakarta ke Bandung atau Bandung ke Jakarta.

User mengisi:
1. Arah dan tanggal
2. Jam paling cepat berangkat dan jam paling telat sampai kembali
3. **Tujuan pasti** (kerjaan, janji temu, tempat incaran), boleh dengan **jam tetap** dan **prioritas**
4. **Vibes** untuk mengisi waktu kosong (kulineran, healing, belanja, dll)

Aplikasi menyusun itinerary lengkap: transportasi ke stasiun, kereta Whoosh pergi, feeder atau transportasi lanjutan, tujuan pasti user, rekomendasi tempat di sela waktunya, sampai kereta pulang. Prinsip utamanya: **rencana yang dihasilkan selalu mungkin dijalani dan user pasti sempat kembali ke stasiun.**

## 2. Latar belakang dan masalah

**Konteks.** Whoosh melayani empat stasiun: Halim, Karawang, Padalarang, dan Tegalluar Summarecon. Waktu tempuh Jakarta ke Bandung sekitar 40 menit, sehingga perjalanan pulang pergi di hari yang sama sangat mungkin. Perjalanan juga ramai di kedua arah: pada 31 Mei 2026 sekitar 50% penumpang bergerak dari Bandung ke Jakarta dan 42% dari Jakarta ke Bandung (sumber: KCIC via Sonora, lihat Referensi).

**Masalah yang dihadapi penumpang:**

| # | Masalah | Bukti / contoh |
| --- | --- | --- |
| P1 | Stasiun Whoosh di Bandung tidak berada di pusat kota, jadi perlu sambungan lanjutan | Dari Padalarang ada KA Feeder 19 menit ke Stasiun Bandung; dari Tegalluar ada DAMRI |
| P2 | Sulit menghitung sisa waktu setelah urusan utama selesai | Meeting 13.00 sampai 15.00 di Sudirman, kereta pulang 18.25: masih sempat ke mana? |
| P3 | Takut ketinggalan kereta pulang karena macet | KCIC rutin mengimbau penumpang memakai KA Feeder agar terhindar dari macet ke Padalarang |
| P4 | Informasi tersebar di banyak aplikasi | Jadwal kereta, feeder, Maps, dan rekomendasi kuliner dicek terpisah |

**Peluang untuk KCIC:**
* Mendorong perjalanan pulang pergi di hari yang sama (lebih banyak tiket per penumpang)
* Mempromosikan KA Feeder dan integrasi antarmoda
* Menjadi kanal untuk UMKM dan mitra di sekitar stasiun pada fase berikutnya

## 3. Tujuan dan metrik

### Tujuan produk
1. User bisa membuat itinerary sehari yang valid dalam waktu kurang dari 2 menit.
2. Tujuan wajib user selalu masuk ke rencana atau user diberi tahu dengan jelas kenapa tidak bisa.
3. Tidak ada rencana yang membuat user ketinggalan kereta pulang.

### Metrik untuk demo hackathon

| Metrik | Target |
| --- | --- |
| Waktu dari buka aplikasi sampai itinerary jadi (alur demo) | ≤ 90 detik |
| Waktu generate itinerary | ≤ 5 detik |
| Rencana yang melanggar jam tetap atau jam pulang | 0 |
| Jumlah tempat terkurasi per kota | ≥ 60 Bandung, ≥ 40 Jakarta |
| Alur demo berjalan offline dari seed data (fallback) | Ya |

### Metrik jika produk dilanjutkan
* Persentase rencana yang disimpan
* Persentase user yang membuat rencana kedua dalam 30 hari
* Klik "Beli tiket" menuju kanal resmi Whoosh

## 4. Persona

**Raka, 29, account manager di Jakarta.** Sering meeting klien di Bandung. Ingin berangkat pagi, meeting 13.00 sampai 15.00, makan siang dulu, beli oleh oleh, lalu pulang tanpa drama.
Kebutuhan: tujuan berjam tetap, prioritas wajib, peringatan kalau mepet.

**Nadia, 21, mahasiswa di Bandung.** Mau main ke Jakarta saat akhir pekan, nonton konser jam 19.00, sebelumnya jalan jalan dan ngopi.
Kebutuhan: arah Bandung ke Jakarta, tujuan berjam tetap di malam hari, rekomendasi sesuai budget hemat.

**Keluarga Budi, 4 orang.** Day trip ke Bandung bawa anak.
Kebutuhan: vibes keluarga, tempat ramah anak, jadwal tidak terlalu padat.

## 5. Ruang lingkup

### Masuk MVP (hackathon)
* Arah dua kota: Jakarta ⇄ Bandung, tukar dengan satu tombol
* Titik berangkat di kota asal (rumah, kantor, stasiun, atau cari alamat). Stasiun kereta cepat dipilih otomatis
* Tanggal, jam paling cepat berangkat dan paling telat sampai (picker, tanpa keyboard)
* Tujuan pasti: keperluan, jam tetap atau bebas jam, prioritas Wajib / Penting / Kalau sempat
* Vibes, sub kategori, budget, preferensi pindah antar tempat (Campur, Ojol, Transum)
* Generate itinerary: timeline dan peta rute bernomor
* Setiap perpindahan bisa dipilih ojol atau transum, transum menampilkan koridor dan langkahnya, total ongkos ikut berubah
* Detail stop di itinerary (alasan dipilih, tukar dengan alternatif)
* Jelajah tempat di kota tujuan, detail tempat untuk menjelajah, wishlist, masukkan tempat ke rencana
* Simpan trip, tab Trip, mode jalan hari H
* Status waktu: aman, mepet, tidak keburu
* State lengkap: loading dengan Oti bergerak, empty state, snackbar, dialog konfirmasi

### Di luar MVP
* Pembelian tiket di dalam aplikasi (cukup tautan ke kanal resmi)
* Data lalu lintas realtime dan notifikasi push saat harus berangkat
* Rencana menginap atau lebih dari satu hari
* Akun penuh, berbagi rencana, kolaborasi
* Stasiun Karawang sebagai tujuan wisata
* Review dan rating dari user
* Animasi Oti (Rive) dan widget home screen berisi status trip dengan ekspresi Oti (fase setelah hackathon, lihat `docs/BRAND.md`)

## 6. Alur utama

Navigasi bawah 4 tab: Beranda, Jelajah, Trip, Akun.

```
Onboarding (sekali)
  └─ Beranda: kartu rencana (kota asal ⇄ kota tujuan, titik berangkat, tanggal, jam)
        ├─ Pilih titik berangkat
        └─ Rencanain trip ──> Atur rencana (tujuan, vibes, budget, cara pindah)
                                 ├─ Tambah tujuan (peta, keperluan, jam, prioritas)
                                 └─ Gas ──> Menyusun (loading) ──> Hasil (peta + timeline)
                                                                    ├─ Pilih ojol / transum per perpindahan
                                                                    ├─ Detail stop ──> Tukar tempat
                                                                    └─ Simpan ──> Tab Trip ──> Mode jalan (hari H)
Jelajah / Beranda / Wishlist ──> Detail tempat ──> Simpan ke wishlist / Masukin ke rencana
```

## 7. Kebutuhan fungsional

### 7.1 Setup trip

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-01 | User memilih arah: Ke Bandung / Ke Jakarta. Kota tujuan menentukan semua label (`{kota}`) | Must |
| FR-02 | User memilih tanggal (default hari ini, maks 30 hari ke depan) | Must |
| FR-03 | User mengisi jam paling cepat berangkat dari asal dan jam paling telat sampai kembali di asal | Must |
| FR-04 | User mengisi titik asal: lokasi saat ini, cari alamat, atau langsung stasiun asal | Must |
| FR-05 | User memilih stasiun tujuan. Default: Padalarang untuk Bandung (feeder gratis ke pusat kota), Halim untuk Jakarta | Should |

### 7.2 Tujuan pasti (pin)

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-10 | User bisa menambah 0 sampai 5 tujuan | Must |
| FR-11 | Tujuan bisa dipilih dari daftar tempat (`mst_place`) atau dibuat custom (nama + alamat dari autocomplete) | Must |
| FR-12 | Tiap tujuan punya keperluan: Kerjaan, Janji, Main, Lainnya | Should |
| FR-13 | Tiap tujuan **jam tetap** (mulai dan selesai) atau **bebas jam** (durasi) | Must |
| FR-14 | Tiap tujuan punya prioritas: **Wajib**, **Penting**, **Kalau sempat**. Default Penting; tujuan berjam tetap dengan keperluan Kerjaan default Wajib | Must |
| FR-15 | Validasi saat input: jam selesai harus setelah jam mulai, jam tetap harus di dalam jendela waktu trip | Must |
| FR-16 | Dua tujuan berjam tetap yang tumpang tindih ditolak dengan pesan jelas | Must |

### 7.3 Vibes

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-20 | User memilih satu vibes: Kulineran, Healing, Nostalgia Kota, Mode Checkout, Family Trip, Campur Aduk (`mst_trip_type`) | Must |
| FR-21 | User bisa mempersempit kategori kuliner/wisata lewat chip (boleh lebih dari satu) | Should |
| FR-22 | User memilih budget: Hemat, Sedang, Sultan | Should |
| FR-23 | Toggle "Bawa bocil" memfilter tempat `ramah_anak` | Could |
| FR-24 | Langkah vibes boleh dilewati kalau tujuan pasti sudah mengisi seluruh waktu | Must |

### 7.4 Generate dan hasil

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-30 | Sistem memilih kereta pergi dan pulang yang paling pas dengan jendela waktu dan tujuan | Must |
| FR-31 | Sistem menyusun timeline: asal → stasiun → Whoosh → feeder → tempat → ... → stasiun → Whoosh → asal | Must |
| FR-32 | Setiap segmen menampilkan mode, jam mulai, durasi, dan tarif bila ada | Must |
| FR-33 | Kartu TimeBudget menampilkan total waktu luang, kereta pulang, dan status waktu | Must |
| FR-34 | User bisa menukar satu tempat rekomendasi dengan 3 alternatif terdekat yang muat di slot yang sama | Should |
| FR-35 | Jika tujuan Wajib tidak terkejar, sistem menawarkan: ganti kereta, ubah jam, atau ubah prioritas. Tujuan Wajib tidak pernah dihapus diam diam | Must |
| FR-36 | Tujuan "Kalau sempat" yang dilepas ditampilkan dengan pesan singkat | Must |
| FR-37 | Tombol "Beli tiket" membuka kanal resmi pembelian tiket Whoosh | Could |

### 7.5 Simpan

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-40 | User menyimpan itinerary tanpa registrasi (Supabase anonymous sign in) | Should |
| FR-41 | Daftar trip tersimpan, urut tanggal terdekat | Should |
| FR-42 | Hapus trip dengan dialog konfirmasi | Should |

## 8. Aturan planner

Semua aturan waktu dijalankan di kode (deterministik) dan diuji unit test.

### 8.1 Konstanta

| Konstanta | Nilai default | Alasan |
| --- | --- | --- |
| `bufferBeforeTrain` | 30 menit | Tiba di stasiun paling lambat 30 menit sebelum berangkat, sesuai anjuran pembelian tiket di stasiun |
| `bufferAfterTrain` | 10 menit | Turun kereta dan keluar stasiun |
| `bufferBetweenStops` | 10 menit | Parkir, antre, cari jalan |
| `maxWalkMinutes` | 15 menit | Di atas ini pakai ojol/taksi |
| `minFreeSlot` | 45 menit | Celah lebih pendek tidak diisi rekomendasi |
| `warningThreshold` | 30 menit | Sisa waktu sebelum harus jalan ke stasiun → status mepet |
| `freeBlockMinutes` | 30 menit | Jeda tanpa agenda sepanjang ini tampil sebagai blok "Waktu luang" |
| `earlierReturnMinutes` | 60 menit | Kereta pulang lebih awal ditawarkan kalau minimal selisih segini |
| Tempo `maxStops` | Santai 2, Pas 4 (default), Padat 6, custom 0 sampai 8 | Batas rekomendasi planner. Tujuan user tidak dihitung |

### 8.2 Urutan langkah

1. **Hitung jendela waktu.** `berangkat_paling_cepat` + waktu ke stasiun asal, sampai `sampai_paling_telat` dikurangi waktu dari stasiun asal ke rumah.
2. **Pilih kereta pergi.** Kereta paling awal yang bisa dikejar dari asal (`bufferBeforeTrain`). Jika ada tujuan berjam tetap, pilih kereta paling akhir yang tetap membuat user tiba tepat waktu di tujuan pertama, supaya tidak menunggu terlalu lama.
3. **Pilih kereta pulang.** Kereta paling akhir yang membuat user tetap sampai sebelum `sampai_paling_telat`.
4. **Sambungkan feeder.** Untuk Padalarang, pakai jadwal `mst_feeder_schedule` yang menyambung kereta tersebut (`connects_trip_id`) atau jadwal terdekat.
5. **Kunci tujuan berjam tetap** (`is_locked = true`).
6. **Sisipkan tujuan bebas jam** urut prioritas (Wajib, Penting, Kalau sempat), di celah yang muat termasuk waktu perjalanan.
7. **Isi celah tersisa** dengan rekomendasi dari `mst_place` yang:
   * buka sepanjang slot kunjungan (`mst_place_opening_hour`)
   * cocok dengan kategori vibes (diberi bobot `mst_trip_type_category.weight`)
   * cocok dengan budget dan atribut
   * dekat dengan titik sebelum dan sesudahnya (skor jarak)
   Batas: berhenti saat jumlah rekomendasi mencapai tempo. Skor = waktu tempuh, ditambah penalti kategori yang sudah dipakai. Makan besar diutamakan di jam makan (11.00 sampai 13.30, 17.30 sampai 20.00) dan tidak boleh berjarak kurang dari 3 jam dari makan besar lain. Kalau tiba sebelum tempat buka, kunjungan menunggu jam buka.
8. **Validasi akhir.** Setiap item harus selesai sebelum item berikutnya dimulai, dan kedatangan di stasiun pulang ≥ `bufferBeforeTrain` sebelum kereta.
9. **Status.** Aman jika validasi lolos dengan sisa ≥ `warningThreshold`. Mepet jika kurang. Tidak keburu jika ada tujuan Wajib yang gagal.

### 8.3 Konflik

| Kondisi | Perilaku | Copy |
| --- | --- | --- |
| Tujuan Wajib berjam tetap tidak terkejar dari kereta mana pun | Tidak generate, tampilkan pilihan | "Meeting 13.00 nggak kekejar dari kereta 12.25. Ganti ke kereta lebih pagi?" |
| Tujuan Penting tidak muat | Generate tanpa tujuan itu, tampilkan banner | "Waktunya nggak cukup buat {nama}. Mau ganti jam pulang?" |
| Tujuan Kalau sempat tidak muat | Lepas, info singkat | "Waktunya nggak cukup, jadi {nama} kita lepas dulu." |
| Tempat tutup di jam slot | Cari tempat lain atau geser urutan | "Tutup jam 17.00, jadi kita taruh di awal" |

### 8.3a Edit hasil

Semua edit lewat draft, lalu planner dijalankan ulang, jadi jam selalu dihitung ulang dan rencana tetap valid.

| Aksi | Perilaku |
| --- | --- |
| Hapus rekomendasi | Masuk daftar `excludedPlaceIds`. Rekomendasi lain dipertahankan (`keptPlaceIds`) dengan urutan sama, tanpa pengganti otomatis. Sisa waktu jadi blok "Waktu luang". Ada aksi Batal |
| Hapus tujuan user | Wajib konfirmasi dialog. Rekomendasi lain dipertahankan |
| Isi 1 tempat lagi | Muncul kalau masih ada kandidat yang muat. Menambah satu tanpa mengganti yang ada |
| Pulang lebih awal | Muncul kalau ada kereta pulang ≥ `earlierReturnMinutes` lebih cepat yang tetap memuat semua tempat (dicek dengan menjalankan ulang planner) |
| Ubah setup (tanggal, jam, vibes, budget, tempo, tambah tujuan) | Edit hasil di-reset |

### 8.4 Waktu perjalanan antar titik

1. Cek `cache_travel_time`
2. Jika tidak ada, panggil Google Routes API **lewat Supabase Edge Function** (API key tidak pernah ada di aplikasi), simpan ke cache
3. Jika API gagal, estimasi jarak garis lurus × 1,4 dengan kecepatan 20 km/jam (kota) dan tandai "perkiraan"

## 9. Data

Rencana lengkap, prioritas, dan checklist: **`docs/DATA_PLAN.md`**. Skema: `supabase/migrations/`.
Template isian: `supabase/seed/*.csv`.

| Data | Sumber | Cara isi | Status |
| --- | --- | --- | --- |
| Stasiun kereta cepat dan feeder | Internal KCIC | Seed manual | Seed ada |
| Jadwal kereta cepat | Jadwal resmi KCIC | CSV, bukan generator pola | Belum (masih asumsi) |
| Jadwal KA Feeder | KCIC / KAI | CSV | Belum |
| Rute akses transum ke stasiun | Situs resmi operator | CSV `access_route` | Contoh di kode |
| Tempat dan jam buka (40 sampai 60, zona demo) | Manual + OpenStreetMap, tanpa scraping Google Maps | CSV `place` | 8 contoh |
| Waktu tempuh | Dihitung sekali lalu disimpan di `cache_travel_time`; runtime hanya leg dari titik user | Edge Function | Belum |
| Ongkos ojol | Ketentuan tarif resmi, tampil sebagai perkiraan | `mst_fare_rule` | Contoh |
| Rencana user, wishlist | App | `trx_plan*`, `trx_wishlist` | State lokal |

Konvensi tabel: `mst_` master, `trx_` transaksi, `cache_` data turunan. Detail di `docs/RULES.md`.

## 10. Kebutuhan non fungsional

| Area | Kebutuhan |
| --- | --- |
| Performa | Generate ≤ 5 detik; layar pertama tampil ≤ 2 detik |
| Ketersediaan demo | Ada mode demo memakai seed data lokal bila internet atau API gagal |
| Keamanan | API key pihak ketiga hanya di Edge Function; RLS aktif di semua tabel; user hanya bisa baca/tulis trx miliknya |
| Aksesibilitas | Kontras teks ≥ 4.5:1 di kedua tema; target sentuh ≥ 44px; status tidak hanya dibedakan warna |
| Bahasa | Bahasa Indonesia santai gaya Gen Z, mengikuti `docs/DESIGN_SYSTEM.md` |
| Tema | Light dan dark |
| Privasi | Lokasi hanya dipakai saat menyusun rencana, tidak disimpan kecuali rencana disimpan |
| Offline | Font dan aset brand dibundel di aplikasi, tidak diunduh saat runtime |

## 11. Daftar layar

Desain: canvas "OTWEY App Screens" halaman App v2. Kode: `lib/features/*/presentation/`.

| Layar | Kode | Catatan |
| --- | --- | --- |
| Onboarding | `trip_setup/.../onboarding_page.dart` | Oti melayang |
| Beranda | `home/.../home_page.dart` | Kartu rencana, trip berikutnya, tempat incaran, ide trip |
| Pilih titik berangkat | `trip_setup/.../origin_picker_page.dart` | |
| Atur rencana | `trip_setup/.../plan_setup_page.dart` | Tujuan + isi waktu luang dalam satu layar |
| Tambah tujuan | `trip_setup/.../add_pin_page.dart` | Time picker bottom sheet |
| Menyusun | `planner/.../generating_page.dart` | Loading berulang dengan Oti |
| Hasil | `planner/.../result_page.dart` | Ojol vs transum per perpindahan |
| Detail stop | `planner/.../stop_detail_page.dart` | Dari timeline, tukar tempat |
| Jelajah | `places/.../explore_page.dart` | Peta + daftar + loading skeleton |
| Detail tempat | `places/.../place_detail_page.dart` | Untuk menjelajah, slot foto menyusul |
| Wishlist | `places/.../wishlist_page.dart` | Per kota, empty state |
| Trip | `saved_trips/.../saved_trips_page.dart` | Kartu tiket, empty state Oti tidur |
| Mode jalan | `live/.../live_trip_page.dart` | Hari H |
| Akun | `account/.../account_page.dart` | |
| Konflik | belum | Pakai `showOtwConfirmDialog` varian mepet |

## 12. Skenario demo (3 menit)

1. Buka aplikasi, pilih **Ke Bandung**, besok.
2. Berangkat dari Tebet jam 07.00, harus sampai lagi jam 21.00.
3. Tambah tujuan: "Kantor klien, Jl. Ir. H. Juanda (Dago)", **13.00 sampai 15.00**, Kerjaan, **Wajib**.
4. Tambah tujuan bebas jam: "Kopi incaran", 45 menit, **Kalau sempat**.
5. Pilih vibes **Kulineran**, budget Hemat.
6. Generate: tampil Whoosh 09.25, KA Feeder, makan siang dekat kantor klien, meeting terkunci, jajan, oleh oleh, kopi, kereta pulang 18.25.
7. Ubah jam sampai ke 19.00 untuk menunjukkan **"Kopi incaran" dilepas** dan status **Mepet**.
8. Ganti arah ke **Ke Jakarta** untuk menunjukkan aplikasi dua arah.

## 13. Risiko

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Jadwal Whoosh dan feeder di seed tidak akurat | Rencana salah | Ambil data resmi internal, tandai sumber dan tanggal berlaku |
| Data tempat kurang atau jam buka salah | Rekomendasi buruk | Kurasi manual 100 tempat, `is_verified` |
| Kuota atau kegagalan Google API saat demo | Demo gagal | Cache + mode demo offline |
| Algoritma terlalu kompleks untuk waktu hackathon | Tidak selesai | Greedy sederhana dulu, optimasi belakangan |
| Data tempat dan jadwal belum siap saat demo | Rencana terlihat palsu | Sempitkan ke zona demo, kerjakan Data P0 dulu, mode demo pakai seed lokal yang sama dengan Supabase |
| Nama produk bentrok merek lain | Ganti nama setelah presentasi | Cek Play Store, App Store, PDKI sebelum final |

## 14. Pertanyaan terbuka

1. Hasil cek merek OTWEY di PDKI (kelas 9, 39, 42), store, domain, dan media sosial.
2. Pola jadwal Whoosh yang tepat: setiap 2 jam di menit 00 dan 25, atau setiap jam?
3. Apakah ada data internal jumlah penumpang pulang pergi di hari yang sama untuk memperkuat pitch?
4. Apakah boleh menautkan langsung ke kanal pembelian tiket resmi?
5. Kriteria penilaian hackathon.
6. Siapa di internal yang bisa memberi jadwal kereta cepat dan KA Feeder resmi, dan boleh dipakai untuk demo?
7. Tanggal demo, supaya urutan Data P0 bisa dijadwalkan mundur.

## 15. Rencana kerja bertahap

| Tahap | Hasil | Status |
| --- | --- | --- |
| 0 | Brand, logo, Oti, design system, aset | Selesai |
| 1 | Setup Flutter 3.50 + desain App v2 | Selesai |
| 2 | Semua layar App v2 dengan data contoh, widget modular, animasi | Selesai, perlu uji di perangkat |
| 3 | **Data P0** (DATA_PLAN): jadwal resmi, feeder, rute akses, 40 sampai 60 tempat | Berikutnya |
| 4 | Migrasi kedua + seed dari CSV + repository Supabase menggantikan `demo_*.dart` | Berikutnya |
| 5 | Planner greedy di Dart (PRD 8) + unit test, menggantikan `DemoItinerary` | Berikutnya |
| 6 | Konflik dan status mepet di UI, waktu tempuh dari cache + Edge Function | |
| 7 | Simpan trip ke Supabase (login anonim), mode demo offline, polishing, latihan demo | |

## Referensi

* Sebaran arah penumpang 31 Mei 2026: https://www.sonora.id/read/424383905/arus-balik-penumpang-whoosh-momen-long-weekend-mulai-meningkat
* KA Feeder terintegrasi dengan jadwal Whoosh: https://megapolitan.antaranews.com/berita/517334/kcic-imbau-penumpang-whoosh-gunakan-ka-feeder-pada-arus-balik
* Waktu tempuh KA Feeder Padalarang ke Bandung 19 menit: https://momsmoney.kontan.co.id/news/kai-sediakan-kereta-feeder-dukung-konektivitas-whoosh-ini-jadwalnya
* Akses transportasi dari stasiun Whoosh: https://ekonomi.bisnis.com/read/20231209/98/1722450/ini-akses-transportasi-ke-kota-bandung-dari-stasiun-kereta-cepat/1
* Anjuran tiba 30 menit sebelum keberangkatan: https://dealls.com/pengembangan-karir/cara-beli-tiket-whoosh
