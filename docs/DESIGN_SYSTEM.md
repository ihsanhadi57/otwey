# Design System: OTWEY

Versi interaktif ada di artifact Design System. File ini ringkasan yang dipakai saat coding. Implementasi Flutter: `lib/core/theme/`.

## Konsep visual

Dua benda dari perjalanan kereta:
* **Tiket**: angka jam tegas, latar krem hangat, sobekan setengah lingkaran di sisi kartu
* **Garis waktu**: rute berurutan dengan rel berwarna per mode transportasi

Kesan: hangat, ceria, bisa dipercaya soal waktu. Bukan korporat, bukan aplikasi travel generik.

Logo, maskot Oti, ikon aplikasi, dan aturan pakainya ada di `docs/BRAND.md`.

## Warna

| Token | Light | Dark | Peran |
| --- | --- | --- | --- |
| `surface-100` | `#fbf7f2` | `#12142a` | Latar halaman |
| `surface-200` | `#ffffff` | `#1b1e38` | Kartu, sheet, input |
| `surface-300` | `#f1ebe3` | `#252948` | Area cekung, chip off, track |
| `line` | `#e6ded3` | `#2c3052` | Garis pemisah |
| `line-strong` | `#8a8576` | `#6f7396` | Border kontrol (3:1) |
| `ink` | `#1b1f3b` | `#f4efe8` | Teks utama |
| `ink-muted` | `#5b5f78` | `#a9acc4` | Teks sekunder |
| `brand` | `#c93e17` | `#ff7a4d` | Senja: CTA, tempat di timeline |
| `brand-strong` | `#a8320f` | `#ff9a75` | Teks brand di tint, pressed |
| `brand-tint` | `#fce3d8` | `#3a2230` | Chip/kartu terpilih |
| `on-brand` | `#ffffff` | `#12142a` | Teks di atas brand |
| `accent` | `#1f7a55` | `#4cc38a` | Kebun teh: status aman |
| `accent-tint` | `#e8f5ee` | `#15332a` | Latar badge aman |
| `mode-whoosh` | `#1b1f3b` | `#c3caff` | Rel kereta Whoosh |
| `mode-feeder` | `#5a8ae6` | `#5b86e5` | Rel feeder, bus (garis saja) |
| `mode-walk` | `#a7aabb` | `#565a78` | Rel jalan kaki, putus putus |
| `warning` | `#b45309` | `#f5a524` | Waktu mepet |
| `danger` | `#b42318` | `#ff6b5e` | Error, tidak keburu |
| `logo-orange` | `#ff6b2c` | `#ff6b2c` | Logo, Oti, ilustrasi. Bukan untuk teks atau tombol |
| `sun` | `#ffc83d` | `#ffc83d` | Latar ilustrasi, ikon aplikasi, aksen ceria. Teks di atasnya `ink` |

Semua pasangan teks lolos 4.5:1 di kedua tema. `logo-orange` dan `sun` tidak dipakai sebagai warna teks.

## Tipografi

| Style | Font | Size / line | Weight | Pakai untuk |
| --- | --- | --- | --- | --- |
| display | **Fredoka** | 32 / 38 | 700 | Judul onboarding, judul hasil itinerary |
| title | **Fredoka** | 22 / 28 | 600 | Judul layar, judul sheet |
| heading | Plus Jakarta Sans | 17 / 24 | 700 | Nama tempat |
| body | Plus Jakarta Sans | 15 / 22 | 400 | Isi |
| label | Plus Jakarta Sans | 13 / 18 | 600 | Tombol, chip |
| caption | Plus Jakarta Sans | 12 / 16 | 500 | Info tambahan (ink-muted) |
| time | JetBrains Mono | 20 / 24 | 600 | Jam di timeline dan tiket |
| time-sm | JetBrains Mono | 14 / 18 | 500 | Nomor kereta, durasi |

Kenapa campuran, bukan Fredoka semua: Fredoka membawa rasa logo ke judul sehingga aplikasi terasa satu keluarga dengan brand, tapi bentuknya yang bulat kurang nyaman untuk teks panjang dan angka kecil. Plus Jakarta Sans tetap untuk teks UI supaya mudah dibaca sambil jalan. Semua font dibundel di `assets/fonts/` (lisensi OFL).

## Spasi dan radius

* Spasi (grid 4): `4, 8, 12, 16, 24, 32`. Gutter layar 16.
* Radius: `sm 8` badge, `md 14` tombol dan kartu, `lg 22` kartu tiket dan sheet, `pill 999` chip.
* Bayangan: hanya `shadow-card` untuk kartu di atas peta.

## Ikon

Material Symbols Rounded, 20 atau 24. Mode: `train`, `tram`, `directions_bus`, `directions_walk`, `two_wheeler`. Kategori: kolom `icon` di `mst_category`.

## Komponen

| Komponen | Inti |
| --- | --- |
| Button | Tinggi 48, radius md. Primary `brand`, secondary outline `line-strong`, ghost teks `brand-strong` |
| CategoryChip | Pill 40, multi select. Terpilih `brand-tint` + border `brand` |
| PinCard | Tujuan user: nama, alamat, jam tetap/bebas jam, keperluan, badge prioritas, segmented control prioritas |
| TimelineStop | Kolom jam mono 56, rel 24 berwarna mode, kartu tempat dengan badge kategori dan durasi |
| TimeBudget | Kartu radius lg: waktu luang besar (mono 32), bar perjalanan/luang/jaga jaga, pill kereta pulang dan status |

### Prioritas

| Prioritas | Badge | Perilaku |
| --- | --- | --- |
| Wajib | Fill `brand`, teks `on-brand`, ikon `lock` jika jam tetap | Dikunci duluan, tidak pernah dihapus diam diam |
| Penting | `brand-tint`, teks `brand-strong` | Masuk setelah wajib, user diberi tahu jika tidak muat |
| Kalau sempat | `surface-300`, border `line-strong`, teks `ink-muted` | Dilepas pertama jika waktu kurang |

## Suara dan bahasa

Benchmark Gojek. Akrab, pakai "kamu", kalimat pendek, slang secukupnya. **Jelas dulu, lucu belakangan.** Error dan konflik tanpa candaan.

### Nada per momen

| Momen | Contoh |
| --- | --- |
| Sukses | "Sip, itinerary kamu udah aman tersimpan." |
| Info | "KA Feeder 10.45, gratis buat penumpang Whoosh." |
| Peringatan | "Mepet nih. Cus ke stasiun dalam 25 mnt biar nggak ketinggalan." |
| Error | "Rutenya belum bisa dimuat. Cek koneksi kamu, terus coba lagi ya." |
| Kosong | "Belum ada rencana. Pilih tanggal dulu, sisanya biar kita yang atur." |

### Kamus istilah

| Pakai | Jangan |
| --- | --- |
| itinerary / rencana | jadwal perjalanan, agenda |
| kereta pulang | keberangkatan kembali |
| waktu luang | durasi eksplorasi |
| vibes trip | tipe perjalanan |
| tujuan kamu | destinasi pilihan, pin |
| jam tetap / bebas jam | waktu terkunci / fleksibel |
| Wajib / Penting / Kalau sempat | prioritas tinggi / sedang / rendah |
| feeder | angkutan pengumpan |
| mepet | waktu terbatas |

### Microcopy inti

| Elemen | Copy |
| --- | --- |
| Onboarding judul | Jakarta ⇄ Bandung, sehari kelar |
| Onboarding sub | Kerjaan beres, main juga sempat, pulang tetap on time |
| Pilih arah | Mau ke mana hari ini? · [Ke Bandung] [Ke Jakarta] |
| Jam berangkat | Mau berangkat jam berapa? |
| Jam sampai | Paling telat sampai rumah jam berapa? |
| Tujuan kamu, judul | Udah ada tujuan pasti? |
| Tujuan kamu, sub | Kerjaan, janji, atau tempat incaran. Sisanya biar kita isi. |
| Tambah tujuan | Tambah tujuan |
| Jam tujuan | Jam tetap · Bebas jam |
| Prioritas | Wajib · Penting · Kalau sempat |
| Vibes | Sisa waktunya mau diisi apa? |
| CTA generate | Gas, bikin itinerary |
| Loading | Lagi nyusun rute terbaik buat kamu... |
| Hasil judul | {kota}, here we go |
| Ringkasan waktu | Waktu luang kamu 3 j 40 mnt |
| Status aman | Aman, masih sempat |
| Status mepet | Mepet nih · 25 mnt lagi |
| Tidak keburu | Nggak keburu. Coba kereta pulang yang lebih malam ya |
| Wajib bentrok | Meeting 13.00 nggak kekejar dari kereta 12.25. Ganti ke kereta lebih pagi? · [Ganti kereta] [Ubah jam] |
| Kalau sempat dilepas | Waktunya nggak cukup, jadi "{nama}" kita lepas dulu. |
| Tempat tutup | Tutup jam 17.00, jadi kita taruh di awal |
| Tukar tempat | Tukar tempat |
| Simpan | Simpan itinerary |
| Hapus | Hapus itinerary ini? Rencananya hilang dan nggak bisa dibalikin. · [Hapus] [Nggak jadi] |
| Empty tersimpan | Belum ada trip tersimpan. Yuk bikin yang pertama. |
| Error koneksi | Koneksi lagi putus nyambung. Cek internet kamu, terus coba lagi ya. |

## Aturan input, ikon, dan state (v2, 18 Nov 2026)

Implementasi: `lib/core/widgets/`.

* Navy berarti dipilih, oranye berarti aksi. Oranye penuh hanya untuk tombol aksi utama.
* Pilih 1 dari 2 atau 3 opsi teks: `OtwSegmented` (terpilih navy penuh).
* Pilih 1 dari 3 sampai 6 opsi berikon: `OtwChoiceGrid` (tanpa scroll; terpilih latar putih, garis navy 2 px, ikon fill navy).
* Pilih banyak: `OtwCheckRow` (centang navy). Ya/tidak: `OtwSwitchRow`.
* Jam: field yang membuka `showOtwTimePicker`, tidak pernah keyboard.
* Perbandingan moda (ojol vs transum): `OtwModeToggle`.
* Ikon: `OtwIconView` (55 ikon, grid 24, garis 2 px, varian line dan fill). Naikkan `play` saat dipilih supaya ikon bergerak sebentar. Ikon tidak pernah diberi kotak atau lingkaran warna di belakangnya, kecuali tombol bulat di atas peta (`OtwRoundButton`).
* Navbar: tab aktif = ikon fill oranye, tanpa pill.
* Feedback: `showOtwSnackBar` (sukses, info, peringatan, gagal; 4 detik, maks satu aksi), `showOtwConfirmDialog` (merah untuk hapus), `OtwEmptyState`, `OtwSkeleton`.
* Oti bergerak: `AnimatedOti` (bob, breathe, sniff, worry). Semua gerak diam saat "kurangi gerakan" aktif.
* Tinggi kontrol minimal 44 px.
