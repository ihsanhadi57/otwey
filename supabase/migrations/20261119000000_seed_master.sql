-- =====================================================================
-- OTWEY seed master: data asli bersumber, siap dijalankan di SQL editor
-- Supabase (Dashboard > SQL Editor > New query > paste semua > Run).
--
-- Sifat:
--   * Idempoten: aman dijalankan berulang (upsert on conflict).
--   * Satu transaksi: kalau ada bagian gagal, semua di-rollback.
--   * Tidak mengarang: setiap angka punya sumber di komentar. Data yang
--     belum tersedia ditandai TODO(hadi) dan TIDAK diisi angka karangan.
--   * is_verified = false untuk tempat: koordinat sudah dicek via OSM,
--     tapi konten/jam belum diverifikasi lapangan. Set true setelah cek.
--
-- Sumber utama:
--   * Jadwal Whoosh: SK DJKA KP-DJKA 2 Tahun 2025 (GAPEKA KA Cepat
--     Jakarta-Bandung), berlaku 1 Feb 2025, skenario reguler 62 kereta.
--     https://djka.kemenhub.go.id/uploads/202501/KP-DJKA%202%20Tahun%202025_GAPEKA%20KA%20KECEPATAN%20TINGGI%20JAKARTA%20-%20BANDUNG.pdf
--   * Integrasi Whoosh + KA Feeder: infografis KCIC "Update 120326"
--     (dibaca via Traveloka, 25 Mei 2026). Whoosh kembali normal 62
--     perjalanan/hari mulai 14 Mar 2026 (siaran pers KCIC 12 Mar 2026).
--     https://www.traveloka.com/id-id/explore/activities/ka-feeder-whoosh-simak-segala-hal-yang-perlu-diketahui/383760
--     https://kcic.co.id/kcic-siaran-pers/momen-angkutan-lebaran-mulai-14-maret-2026-operasional-whoosh-kembali-normal-62-perjalanan-per-hari/
--   * Koordinat stasiun & tempat: OpenStreetMap (Nominatim/Photon),
--     dicek silang Wikipedia. Bukan Google Maps.
--   * Tarif LRT: KM 67/2023, tarif normal berlaku 1 Jun 2024.
--     https://lrtjabodebek.kai.id/informasi-tarif
--   * Tarif ojol: Kepmenhub KP 667/2022 jo. KP 1001/2022 (batas per km
--     dan biaya jasa minimal per zona). Batas bawah dipakai sebagai
--     perkiraan; aplikasi menampilkan ±.
--
-- TODO(hadi) sebelum produksi:
--   1. Verifikasi ulang jadwal Whoosh/feeder setelah 1 Des 2026 di
--      https://ticket.kcic.co.id dan https://kcic.co.id (siaran pers).
--   2. Kereta tambahan "F" (G1001F/G1002F/G1065F-G1068F) tidak di-seed:
--      hari operasi tidak dipublikasikan dan tidak termasuk 62/hari.
--   3. Jam buka 13 tempat masih kosong (lihat daftar di bagian tempat).
--      Planner melewati tempat tanpa jam buka, jadi isi dulu jam resmi.
--   4. Menit jalan LRT Halim <-> Whoosh Halim (JPO) belum dipublikasikan.
--   5. Akses TransJakarta ke Halim dan akses kota dari Padalarang /
--      Tegalluar / Stasiun Bandung belum punya menit resmi (lihat TODO
--      di bagian akses).
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. STASIUN: isi koordinat (migrasi pertama sudah insert barisnya).
--    Sumber: OSM, dicek silang Wikipedia. Bukan stasiun Karawang lama.
-- ---------------------------------------------------------------------
update mst_station set location = st_makepoint(106.8844875, -6.2456352)::geography where code = 'HLM'; -- OSM node 5851224882
update mst_station set location = st_makepoint(107.2193565, -6.3644378)::geography where code = 'KRW'; -- OSM way 917251096 (stasiun cepat, bukan stasiun lama)
update mst_station set location = st_makepoint(107.4969093, -6.8422655)::geography where code = 'PDL'; -- OSM node 10693460259
update mst_station set location = st_makepoint(107.7146978, -6.9638120)::geography where code = 'TGL'; -- OSM node 5851210256
update mst_station set location = st_makepoint(107.6021243, -6.9142580)::geography where code = 'BD';  -- OSM node 10693460294
update mst_station set location = st_makepoint(107.5361568, -6.8857909)::geography where code = 'CMI'; -- OSM way 257233123

-- ---------------------------------------------------------------------
-- 2. WHOOSH: 62 kereta reguler GAPEKA 2025 (G1003-G1064).
--    Semua kereta Halim <-> Tegalluar, berhenti di Padalarang (3 menit).
--    Karawang selektif: kalau kereta tidak berhenti, baris KRW dihilangkan
--    (bukan dibuat arr=dep, supaya planner tidak mengira bisa naik di sana).
--    G1003/G1005/G1007 (jkt->bdg) dan G1004/G1006/G1008 (bdg->jkt)
--    beroperasi Senin-Sabtu saja (titik oranye infografis KCIC).
--    stop_sequence dihitung ulang per kereta lewat row_number, jadi
--    kereta tanpa berhenti Karawang punya seq 1,2,3 (HLM,PDL,TGL).
-- ---------------------------------------------------------------------

-- 2a. Jakarta -> Bandung (HLM dep, KRW arr/dep, PDL arr/dep, TGL arr).
with src(train_no, days, hlm, krw_a, krw_d, pdl_a, pdl_d, tgl) as (
  values
    ('G1003','{1,2,3,4,5,6}','06:25','06:40','06:42','07:02','07:05','07:19'),
    ('G1005','{1,2,3,4,5,6}','07:00','','','07:30','07:33','07:47'),
    ('G1007','{1,2,3,4,5,6}','07:25','07:40','07:42','08:02','08:05','08:19'),
    ('G1009','{1,2,3,4,5,6,7}','08:00','','','08:30','08:33','08:47'),
    ('G1011','{1,2,3,4,5,6,7}','08:25','08:40','08:42','09:02','09:05','09:19'),
    ('G1013','{1,2,3,4,5,6,7}','09:00','','','09:30','09:33','09:47'),
    ('G1015','{1,2,3,4,5,6,7}','09:25','09:40','09:42','10:02','10:05','10:19'),
    ('G1017','{1,2,3,4,5,6,7}','10:00','','','10:30','10:33','10:47'),
    ('G1019','{1,2,3,4,5,6,7}','10:25','10:40','10:42','11:02','11:05','11:19'),
    ('G1021','{1,2,3,4,5,6,7}','11:00','','','11:30','11:33','11:47'),
    ('G1023','{1,2,3,4,5,6,7}','11:25','11:40','11:42','12:02','12:05','12:19'),
    ('G1025','{1,2,3,4,5,6,7}','12:00','','','12:30','12:33','12:47'),
    ('G1027','{1,2,3,4,5,6,7}','12:25','12:40','12:42','13:02','13:05','13:19'),
    ('G1029','{1,2,3,4,5,6,7}','13:00','','','13:30','13:33','13:47'),
    ('G1031','{1,2,3,4,5,6,7}','13:25','13:40','13:42','14:02','14:05','14:19'),
    ('G1033','{1,2,3,4,5,6,7}','14:00','','','14:30','14:33','14:47'),
    ('G1035','{1,2,3,4,5,6,7}','14:25','14:40','14:42','15:02','15:05','15:19'),
    ('G1037','{1,2,3,4,5,6,7}','15:00','','','15:30','15:33','15:47'),
    ('G1039','{1,2,3,4,5,6,7}','15:25','15:40','15:42','16:02','16:05','16:19'),
    ('G1041','{1,2,3,4,5,6,7}','16:00','','','16:30','16:33','16:47'),
    ('G1043','{1,2,3,4,5,6,7}','16:25','16:40','16:42','17:02','17:05','17:19'),
    ('G1045','{1,2,3,4,5,6,7}','17:00','','','17:30','17:33','17:47'),
    ('G1047','{1,2,3,4,5,6,7}','17:25','17:40','17:42','18:02','18:05','18:19'),
    ('G1049','{1,2,3,4,5,6,7}','18:00','','','18:30','18:33','18:47'),
    ('G1051','{1,2,3,4,5,6,7}','18:25','18:40','18:42','19:02','19:05','19:19'),
    ('G1053','{1,2,3,4,5,6,7}','19:00','','','19:30','19:33','19:47'),
    ('G1055','{1,2,3,4,5,6,7}','19:25','19:40','19:42','20:02','20:05','20:19'),
    ('G1057','{1,2,3,4,5,6,7}','20:00','','','20:30','20:33','20:47'),
    ('G1059','{1,2,3,4,5,6,7}','20:25','20:40','20:42','21:02','21:05','21:19'),
    ('G1061','{1,2,3,4,5,6,7}','21:00','','','21:30','21:33','21:47'),
    ('G1063','{1,2,3,4,5,6,7}','21:25','21:40','21:42','22:02','22:05','22:19')
),
trip as (
  insert into mst_whoosh_trip (train_no, direction, service_days, valid_from)
  select train_no, 'jakarta_to_bandung', days::smallint[], date '2025-02-01' from src
  on conflict (train_no, direction, valid_from) where train_no is not null
  do update set service_days = excluded.service_days, is_active = true
  returning id, train_no
)
insert into mst_whoosh_trip_stop (trip_id, station_id, stop_sequence, arrival_time, departure_time)
select t.id, s.id,
       row_number() over (partition by t.id order by x.ord)::smallint,
       x.arr, x.dep
from trip t
join src on src.train_no = t.train_no
cross join lateral (values
  (1, 'HLM', null::time, src.hlm::time),
  (2, 'KRW', nullif(src.krw_a, '')::time, nullif(src.krw_d, '')::time),
  (3, 'PDL', src.pdl_a::time, src.pdl_d::time),
  (4, 'TGL', src.tgl::time, null::time)
) as x(ord, code, arr, dep)
join mst_station s on s.code = x.code
where x.arr is not null or x.dep is not null
on conflict (trip_id, stop_sequence) do update
set station_id = excluded.station_id,
    arrival_time = excluded.arrival_time,
    departure_time = excluded.departure_time;

-- 2b. Bandung -> Jakarta (TGL dep, PDL arr/dep, KRW arr/dep, HLM arr).
with src(train_no, days, tgl, pdl_a, pdl_d, krw_a, krw_d, hlm) as (
  values
    ('G1004','{1,2,3,4,5,6}','06:05','06:20','06:23','','','06:52'),
    ('G1006','{1,2,3,4,5,6}','06:35','06:50','06:53','07:12','07:14','07:29'),
    ('G1008','{1,2,3,4,5,6}','07:05','07:20','07:23','','','07:52'),
    ('G1010','{1,2,3,4,5,6,7}','07:35','07:50','07:53','08:12','08:14','08:29'),
    ('G1012','{1,2,3,4,5,6,7}','08:05','08:20','08:23','','','08:52'),
    ('G1014','{1,2,3,4,5,6,7}','08:35','08:50','08:53','09:12','09:14','09:29'),
    ('G1016','{1,2,3,4,5,6,7}','09:05','09:20','09:23','','','09:52'),
    ('G1018','{1,2,3,4,5,6,7}','09:35','09:50','09:53','10:12','10:14','10:29'),
    ('G1020','{1,2,3,4,5,6,7}','10:05','10:20','10:23','','','10:52'),
    ('G1022','{1,2,3,4,5,6,7}','10:35','10:50','10:53','11:12','11:14','11:29'),
    ('G1024','{1,2,3,4,5,6,7}','11:05','11:20','11:23','','','11:52'),
    ('G1026','{1,2,3,4,5,6,7}','11:35','11:50','11:53','12:12','12:14','12:29'),
    ('G1028','{1,2,3,4,5,6,7}','12:05','12:20','12:23','','','12:52'),
    ('G1030','{1,2,3,4,5,6,7}','12:35','12:50','12:53','13:12','13:14','13:29'),
    ('G1032','{1,2,3,4,5,6,7}','13:05','13:20','13:23','','','13:52'),
    ('G1034','{1,2,3,4,5,6,7}','13:35','13:50','13:53','14:12','14:14','14:29'),
    ('G1036','{1,2,3,4,5,6,7}','14:05','14:20','14:23','','','14:52'),
    ('G1038','{1,2,3,4,5,6,7}','14:35','14:50','14:53','15:12','15:14','15:29'),
    ('G1040','{1,2,3,4,5,6,7}','15:05','15:20','15:23','','','15:52'),
    ('G1042','{1,2,3,4,5,6,7}','15:35','15:50','15:53','16:12','16:14','16:29'),
    ('G1044','{1,2,3,4,5,6,7}','16:05','16:20','16:23','','','16:52'),
    ('G1046','{1,2,3,4,5,6,7}','16:35','16:50','16:53','17:12','17:14','17:29'),
    ('G1048','{1,2,3,4,5,6,7}','17:05','17:20','17:23','','','17:52'),
    ('G1050','{1,2,3,4,5,6,7}','17:35','17:50','17:53','18:12','18:14','18:29'),
    ('G1052','{1,2,3,4,5,6,7}','18:05','18:20','18:23','','','18:52'),
    ('G1054','{1,2,3,4,5,6,7}','18:35','18:50','18:53','19:12','19:14','19:29'),
    ('G1056','{1,2,3,4,5,6,7}','19:05','19:20','19:23','','','19:52'),
    ('G1058','{1,2,3,4,5,6,7}','19:35','19:50','19:53','20:12','20:14','20:29'),
    ('G1060','{1,2,3,4,5,6,7}','20:05','20:20','20:23','','','20:52'),
    ('G1062','{1,2,3,4,5,6,7}','20:35','20:50','20:53','21:12','21:14','21:29'),
    ('G1064','{1,2,3,4,5,6,7}','21:05','21:20','21:23','','','21:52')
),
trip as (
  insert into mst_whoosh_trip (train_no, direction, service_days, valid_from)
  select train_no, 'bandung_to_jakarta', days::smallint[], date '2025-02-01' from src
  on conflict (train_no, direction, valid_from) where train_no is not null
  do update set service_days = excluded.service_days, is_active = true
  returning id, train_no
)
insert into mst_whoosh_trip_stop (trip_id, station_id, stop_sequence, arrival_time, departure_time)
select t.id, s.id,
       row_number() over (partition by t.id order by x.ord)::smallint,
       x.arr, x.dep
from trip t
join src on src.train_no = t.train_no
cross join lateral (values
  (1, 'TGL', null::time, src.tgl::time),
  (2, 'PDL', src.pdl_a::time, src.pdl_d::time),
  (3, 'KRW', nullif(src.krw_a, '')::time, nullif(src.krw_d, '')::time),
  (4, 'HLM', src.hlm::time, null::time)
) as x(ord, code, arr, dep)
join mst_station s on s.code = x.code
where x.arr is not null or x.dep is not null
on conflict (trip_id, stop_sequence) do update
set station_id = excluded.station_id,
    arrival_time = excluded.arrival_time,
    departure_time = excluded.departure_time;

-- ---------------------------------------------------------------------
-- 3. KA FEEDER Padalarang - Cimahi - Bandung (gratis pemegang tiket Whoosh).
--    Waktu tempuh ujung-ke-ujung 18 menit (infografis KCIC Update 120326).
--    Cimahi dilalui (PDL +7 menit arah Bandung, BD +12 menit arah PDL)
--    tapi skema feeder hanya menyimpandeparture/arrival ujung, jadi
--    Cimahi dicatat di notes, bukan baris jadwal terpisah.
--    Sambungan: feeder PDL dep = Whoosh PDL arr + 9 menit (arah Bandung);
--    Whoosh PDL dep = feeder PDL arr + 19 menit (arah Jakarta).
--    3 keberangkatan pertama tiap arah Senin-Sabtu (ikut kereta G1003-G1008).
-- ---------------------------------------------------------------------

-- 3a. Padalarang -> Bandung, sambung G1003,G1005,...,G1063.
with route as (
  insert into mst_feeder_route
    (name, mode, origin_station_id, destination_station_id, duration_minutes, fare, free_for_whoosh, notes)
  values (
    'KA Feeder Padalarang - Bandung', 'ka_feeder',
    (select id from mst_station where code = 'PDL'),
    (select id from mst_station where code = 'BD'),
    18, 0, true,
    'Via Cimahi (PDL+7 mnt). Gratis untuk pemegang tiket Whoosh. Transfer di Padalarang tanpa keluar stasiun; pintu tutup 5 menit sebelum berangkat.'
  )
  on conflict (name) do update set
    duration_minutes = excluded.duration_minutes, fare = excluded.fare,
    free_for_whoosh = excluded.free_for_whoosh, notes = excluded.notes, is_active = true
  returning id
),
src(dep, days, train_no) as (
  values
    ('07:11','{1,2,3,4,5,6}','G1003'), ('07:41','{1,2,3,4,5,6}','G1005'), ('08:11','{1,2,3,4,5,6}','G1007'),
    ('08:41','{1,2,3,4,5,6,7}','G1009'), ('09:11','{1,2,3,4,5,6,7}','G1011'), ('09:41','{1,2,3,4,5,6,7}','G1013'),
    ('10:11','{1,2,3,4,5,6,7}','G1015'), ('10:41','{1,2,3,4,5,6,7}','G1017'), ('11:11','{1,2,3,4,5,6,7}','G1019'),
    ('11:41','{1,2,3,4,5,6,7}','G1021'), ('12:11','{1,2,3,4,5,6,7}','G1023'), ('12:41','{1,2,3,4,5,6,7}','G1025'),
    ('13:11','{1,2,3,4,5,6,7}','G1027'), ('13:41','{1,2,3,4,5,6,7}','G1029'), ('14:11','{1,2,3,4,5,6,7}','G1031'),
    ('14:41','{1,2,3,4,5,6,7}','G1033'), ('15:11','{1,2,3,4,5,6,7}','G1035'), ('15:41','{1,2,3,4,5,6,7}','G1037'),
    ('16:11','{1,2,3,4,5,6,7}','G1039'), ('16:41','{1,2,3,4,5,6,7}','G1041'), ('17:11','{1,2,3,4,5,6,7}','G1043'),
    ('17:41','{1,2,3,4,5,6,7}','G1045'), ('18:11','{1,2,3,4,5,6,7}','G1047'), ('18:41','{1,2,3,4,5,6,7}','G1049'),
    ('19:11','{1,2,3,4,5,6,7}','G1051'), ('19:41','{1,2,3,4,5,6,7}','G1053'), ('20:11','{1,2,3,4,5,6,7}','G1055'),
    ('20:41','{1,2,3,4,5,6,7}','G1057'), ('21:11','{1,2,3,4,5,6,7}','G1059'), ('21:41','{1,2,3,4,5,6,7}','G1061'),
    ('22:11','{1,2,3,4,5,6,7}','G1063')
)
insert into mst_feeder_schedule (route_id, departure_time, arrival_time, connects_trip_id, service_days)
select r.id, src.dep::time, (src.dep::time + interval '18 minutes')::time, t.id, src.days::smallint[]
from route r
cross join src
left join mst_whoosh_trip t
  on t.train_no = src.train_no and t.direction = 'jakarta_to_bandung' and t.valid_from = date '2025-02-01'
on conflict (route_id, departure_time) do update set
  arrival_time = excluded.arrival_time, connects_trip_id = excluded.connects_trip_id,
  service_days = excluded.service_days, is_active = true;

-- 3b. Bandung -> Padalarang, sambung G1004,G1006,...,G1064.
with route as (
  insert into mst_feeder_route
    (name, mode, origin_station_id, destination_station_id, duration_minutes, fare, free_for_whoosh, notes)
  values (
    'KA Feeder Bandung - Padalarang', 'ka_feeder',
    (select id from mst_station where code = 'BD'),
    (select id from mst_station where code = 'PDL'),
    18, 0, true,
    'Via Cimahi (BD+12 mnt). Gratis untuk pemegang tiket Whoosh. Sambung ke Whoosh arah Jakarta di Padalarang.'
  )
  on conflict (name) do update set
    duration_minutes = excluded.duration_minutes, fare = excluded.fare,
    free_for_whoosh = excluded.free_for_whoosh, notes = excluded.notes, is_active = true
  returning id
),
src(dep, days, train_no) as (
  values
    ('05:46','{1,2,3,4,5,6}','G1004'), ('06:16','{1,2,3,4,5,6}','G1006'), ('06:46','{1,2,3,4,5,6}','G1008'),
    ('07:16','{1,2,3,4,5,6,7}','G1010'), ('07:46','{1,2,3,4,5,6,7}','G1012'), ('08:16','{1,2,3,4,5,6,7}','G1014'),
    ('08:46','{1,2,3,4,5,6,7}','G1016'), ('09:16','{1,2,3,4,5,6,7}','G1018'), ('09:46','{1,2,3,4,5,6,7}','G1020'),
    ('10:16','{1,2,3,4,5,6,7}','G1022'), ('10:46','{1,2,3,4,5,6,7}','G1024'), ('11:16','{1,2,3,4,5,6,7}','G1026'),
    ('11:46','{1,2,3,4,5,6,7}','G1028'), ('12:16','{1,2,3,4,5,6,7}','G1030'), ('12:46','{1,2,3,4,5,6,7}','G1032'),
    ('13:16','{1,2,3,4,5,6,7}','G1034'), ('13:46','{1,2,3,4,5,6,7}','G1036'), ('14:16','{1,2,3,4,5,6,7}','G1038'),
    ('14:46','{1,2,3,4,5,6,7}','G1040'), ('15:16','{1,2,3,4,5,6,7}','G1042'), ('15:46','{1,2,3,4,5,6,7}','G1044'),
    ('16:16','{1,2,3,4,5,6,7}','G1046'), ('16:46','{1,2,3,4,5,6,7}','G1048'), ('17:16','{1,2,3,4,5,6,7}','G1050'),
    ('17:46','{1,2,3,4,5,6,7}','G1052'), ('18:16','{1,2,3,4,5,6,7}','G1054'), ('18:46','{1,2,3,4,5,6,7}','G1056'),
    ('19:16','{1,2,3,4,5,6,7}','G1058'), ('19:46','{1,2,3,4,5,6,7}','G1060'), ('20:16','{1,2,3,4,5,6,7}','G1062'),
    ('20:46','{1,2,3,4,5,6,7}','G1064')
)
insert into mst_feeder_schedule (route_id, departure_time, arrival_time, connects_trip_id, service_days)
select r.id, src.dep::time, (src.dep::time + interval '18 minutes')::time, t.id, src.days::smallint[]
from route r
cross join src
left join mst_whoosh_trip t
  on t.train_no = src.train_no and t.direction = 'bandung_to_jakarta' and t.valid_from = date '2025-02-01'
on conflict (route_id, departure_time) do update set
  arrival_time = excluded.arrival_time, connects_trip_id = excluded.connects_trip_id,
  service_days = excluded.service_days, is_active = true;

-- ---------------------------------------------------------------------
-- 4. AKSES TRANSUM ke/dari stasiun.
--    Hanya rute yang menit & tarifnya bersumber yang di-seed.
--    LRT Jabodebek Bekasi Line melayani Halim (terhubung JPO ke Whoosh).
--    Menit 27 = diturunkan dari jadwal resmi (Dukuh Atas 06:05 -> Halim
--    06:32), bukan angka karangan. Tarif 13400 = puncak Dukuh Atas-Halim;
--    luar puncak/akhir pekan 10000 (KM 67/2023, berlaku 1 Jun 2024).
--    Sumber: https://lrtjabodebek.kai.id/jadwal-keberangkatan dan
--    https://lrtjabodebek.kai.id/informasi-tarif
--
--    TODO(hadi): tambah langkah jalan JPO LRT Halim <-> Whoosh Halim
--    setelah menitnya terukur (belum dipublikasikan). Sementara rute
--    hanya berisi langkah LRT; planner menghitung jalan dari titik user.
--    TODO(hadi): rute TransJakarta 7W (Cawang - St KCIC Halim, 05:00-22:00,
--    Rp3.500) dan Koridor 10 (24 jam) belum punya menit antar-halte resmi.
--   Sumber: https://smk.transjakarta.co.id/aset/berkas/rute/7W-20260606.jpeg
--    TODO(hadi): akses kota dari Padalarang (MJT K2, Rp4.900), Tegalluar
--    (shuttle DAMRI, tarif/hari operasi belum terverifikasi Nov 2026),
--    dan Stasiun Bandung (MJT K4 / angkot) belum punya menit resmi.
--    Sumber: https://transportforbandung.org/peta/metro-jabar-trans
-- ---------------------------------------------------------------------
insert into mst_access_route (code, station_code, direction, name, source) values
  ('dukuh_atas_halim', 'HLM', 'to_station', 'LRT Jabodebek Dukuh Atas - Halim', 'https://lrtjabodebek.kai.id/jadwal-keberangkatan'),
  ('halim_dukuh_atas', 'HLM', 'from_station', 'LRT Jabodebek Halim - Dukuh Atas', 'https://lrtjabodebek.kai.id/jadwal-keberangkatan')
on conflict (code) do update set
  station_code = excluded.station_code, direction = excluded.direction,
  name = excluded.name, source = excluded.source, is_active = true;

insert into mst_access_step
  (route_code, step_seq, mode, service, corridor, from_stop, to_stop, minutes, fare, operating_hours, source)
values
  ('dukuh_atas_halim', 1, 'commuter_line', 'LRT Jabodebek', 'Bekasi Line',
   'Dukuh Atas BNI', 'Halim', 27, 13400,
   'Dukuh Atas hari kerja 06:05-23:02, akhir pekan 06:21-22:39. Tarif puncak 13400, luar puncak 10000.',
   'https://lrtjabodebek.kai.id/informasi-tarif'),
  ('halim_dukuh_atas', 1, 'commuter_line', 'LRT Jabodebek', 'Bekasi Line',
   'Halim', 'Dukuh Atas BNI', 27, 13400,
   'Halim hari kerja 05:34-23:23, akhir pekan 05:48-23:00. Tarif puncak 13400, luar puncak 10000.',
   'https://lrtjabodebek.kai.id/informasi-tarif')
on conflict (route_code, step_seq) do update set
  mode = excluded.mode, service = excluded.service, corridor = excluded.corridor,
  from_stop = excluded.from_stop, to_stop = excluded.to_stop, minutes = excluded.minutes,
  fare = excluded.fare, operating_hours = excluded.operating_hours, source = excluded.source;

-- ---------------------------------------------------------------------
-- 5. TARIF OJOL (motor). Batas BAWAH resmi per zona dipakai sebagai
--    perkiraan: estimate(km) = max(min_fare, per_km * km).
--    Jakarta = Zona 2 (Jabodetabek): Rp2.550-2.800/km, minimal 4 km
--    pertama Rp10.200-11.200. Bandung = Zona 1 (Jawa non-Jabodetabek):
--    Rp2.000-2.500/km, minimal Rp8.000-10.000.
--    Sumber: Kepmenhub KP 667/2022 jo. KP 1001/2022.
--    TODO(hadi): base fare dinamis Gojek/Grab tidak dipublikasikan;
--    angka di sini batas regulasi, bukan tarif aplikasi persis.
-- ---------------------------------------------------------------------
insert into mst_fare_rule (code, mode, city, base_fare, per_km_fare, min_fare, source) values
  ('motor_jakarta', 'two_wheeler', 'Jakarta', 0, 2550, 10200,
   'Kepmenhub KP 667/2022 jo. KP 1001/2022 Zona 2 batas bawah (atas: 2800/km, min 11200)'),
  ('motor_bandung', 'two_wheeler', 'Bandung', 0, 2000, 8000,
   'Kepmenhub KP 667/2022 jo. KP 1001/2022 Zona 1 batas bawah (atas: 2500/km, min 10000)')
on conflict (code) do update set
  mode = excluded.mode, city = excluded.city, base_fare = excluded.base_fare,
  per_km_fare = excluded.per_km_fare, min_fare = excluded.min_fare,
  source = excluded.source, is_active = true;

-- ---------------------------------------------------------------------
-- 6. TEMPAT (22: 12 Bandung, 10 Jakarta). Koordinat OSM, bukan Google.
--    source_ref = id OSM (node/way/relation). is_verified = false sampai
--    dicek lapangan. visit_minutes = saran durasi kunjungan (config app).
--    Jam buka HANYA dari sumber resmi; yang belum ada dibiarkan kosong
--    dan planner akan melewatkannya sampai jam diisi (lihat TODO bawah).
-- ---------------------------------------------------------------------
insert into mst_place
  (name, city, area, address, location, description, price_range, visit_minutes,
   source, source_ref, classification_confidence, is_verified)
values
  -- Bandung
  ('Jalan Braga', 'Bandung', 'Braga', 'Jl. Braga, Kec. Sumur Bandung',
   st_makepoint(107.608965, -6.916126)::geography,
   'Jalan ikonik era kolonial dengan bangunan art-deco, kafe, galeri, dan pedagang kaki lima; pusat foto wisata Bandung.',
   'murah', 45, 'osm', 'way/786136444', 'medium', false),
  ('Warung Nasi Ibu Imas', 'Bandung', 'Balonggede', 'Jl. Balonggede No. 48, Regol',
   st_makepoint(107.607174, -6.927347)::geography,
   'Warung nasi Sunda legendaris: nasi hangat, ayam goreng/bakar, jeroan, lalapan, dan sambal dadak yang diracik di depan pembeli.',
   'murah', 60, 'osm', 'way/1293529661', 'medium', false),
  ('Kartika Sari Pusat (Kebon Kawung)', 'Bandung', 'Pasir Kaliki', 'Jl. H. Akbar No. 4, Pasir Kaliki',
   st_makepoint(107.599788, -6.911656)::geography,
   'Toko oleh-oleh legendaris Bandung, terkenal dengan pisang bolen; cabang pusat paling dekat dari Stasiun Bandung.',
   'sedang', 30, 'osm', 'node/4256421918', 'medium', false),
  ('Prima Rasa (Pasirkaliki)', 'Bandung', 'Pasirkaliki', 'Jl. Pasirkaliki No. 168',
   st_makepoint(107.597373, -6.902813)::geography,
   'Bakery & pastry sejak 1986, populer untuk brownies dan bolen sebagai oleh-oleh.',
   'sedang', 30, 'osm', 'node/3818319845', 'medium', false),
  ('Kopi Aroma', 'Bandung', 'Banceuy', 'Jl. Banceuy No. 51',
   st_makepoint(107.606233, -6.917474)::geography,
   'Toko/roastery kopi legendaris sejak 1930; menjual biji kopi robusta/arabika yang di-roasting dengan mesin tua, populer sebagai oleh-oleh.',
   'murah', 30, 'osm', 'way/376628479', 'medium', false),
  ('Gedung Sate', 'Bandung', 'Diponegoro', 'Jl. Diponegoro No. 22',
   st_makepoint(107.6187750, -6.9024981)::geography,
   'Gedung pemerintahan ikonis tahun 1920 dengan ornamen tusuk sate; museum interaktif di dalamnya menceritakan sejarah pembangunan gedung.',
   'murah', 60, 'osm', 'way/634270768', 'medium', false),
  ('Museum Konferensi Asia Afrika', 'Bandung', 'Asia Afrika', 'Jl. Asia Afrika No. 65 (Gedung Merdeka)',
   st_makepoint(107.609645, -6.921073)::geography,
   'Museum di Gedung Merdeka, lokasi Konferensi Asia Afrika 1955; diorama dan arsip sejarah diplomasi Indonesia. Gratis.',
   'murah', 60, 'osm', 'way/166968559', 'medium', false),
  ('Saung Angklung Udjo', 'Bandung', 'Padasuka', 'Jl. Padasuka No. 118',
   st_makepoint(107.655297, -6.898269)::geography,
   'Sanggar budaya angklung dengan pertunjukan harian interaktif (penonton ikut memainkan angklung), wayang golek, dan workshop bambu. Pertunjukan reguler 15:30.',
   'sedang', 90, 'osm', 'way/167064114', 'medium', false),
  ('Masjid Raya Al Jabbar', 'Bandung', 'Gedebage', 'Jl. Cimincrang No. 14, Gedebage',
   st_makepoint(107.703504, -6.948094)::geography,
   'Masjid terapung di atas danau reten Gedebage dengan taman lanskap luas; dibuka untuk publik sejak 1 Januari 2023. Gratis.',
   'murah', 60, 'osm', 'way/761092783', 'medium', false),
  ('Pasar Baru Trade Center', 'Bandung', 'Kebon Jeruk', 'Jl. Pasar Selatan, Kompleks Pasar Baru',
   st_makepoint(107.603928, -6.918103)::geography,
   'Kompleks pasar tekstil/pakaian bersejarah (berakar sejak 1906), favorit berburu kain dan busana murah; dekat Stasiun Bandung.',
   'murah', 60, 'osm', 'node/4373163702', 'medium', false),
  ('Farmhouse Susu Lembang', 'Bandung', 'Lembang', 'Jl. Raya Lembang No. 108',
   st_makepoint(107.605751, -6.832170)::geography,
   'Taman rekreasi bertema Eropa dengan peternakan mini, spot foto, dan jajanan susu segar khas Lembang. Catatan: +/-10 km utara stasiun, lalu lintas padat.',
   'sedang', 120, 'osm', 'way/635545036', 'medium', false),
  ('Sudirman Street Day', 'Bandung', 'Sudirman', 'Jl. Jendral Sudirman No. 91',
   st_makepoint(107.600202, -6.920400)::geography,
   'Jalan kuliner malam dengan puluhan stan Chinese-Indonesian dan lokal. Catatan: sebagian stan non-halal.',
   'murah', 60, 'osm', 'node/4321036011', 'medium', false),
  -- Jakarta
  ('Museum Fatahillah', 'Jakarta', 'Kota Tua', 'Jl. Taman Fatahillah No. 1, Pinangsia',
   st_makepoint(106.813289, -6.135155)::geography,
   'Museum sejarah Jakarta di bekas balai kota Batavia (1710) di alun-alun Kota Tua; koleksi era kolonial hingga kemerdekaan.',
   'murah', 60, 'osm', 'node/4243812179', 'medium', false),
  ('Monas (Monumen Nasional)', 'Jakarta', 'Gambir', 'Jl. Silang Monas, Gambir',
   st_makepoint(106.827169, -6.175402)::geography,
   'Tugu nasional 132 m dengan museum sejarah di dasar dan dek observasi di puncak; simbol Jakarta.',
   'murah', 90, 'osm', 'way/1159084257', 'medium', false),
  ('Masjid Istiqlal', 'Jakarta', 'Sawah Besar', 'Jl. Taman Wijaya Kusuma, Sawah Besar',
   st_makepoint(106.831006, -6.170240)::geography,
   'Masjid terbesar di Asia Tenggara; kunjungan wisata difasilitasi lewat registrasi pengunjung di situs resmi. Gratis.',
   'murah', 45, 'osm', 'relation/9627236', 'medium', false),
  ('M Bloc Space', 'Jakarta', 'Blok M', 'Jl. Panglima Polim Raya No. 37, Melawai',
   st_makepoint(106.798763, -6.241689)::geography,
   'Creative hub di bekas kompleks rumah dinas Peruri: gigs, toko kreatif, dan F&B; populer untuk nongkrong sore-malam. Dekat MRT Blok M BCA.',
   'sedang', 90, 'osm', 'way/754440792', 'medium', false),
  ('Pasar Santa', 'Jakarta', 'Kebayoran Baru', 'Jl. Cisanggiri I, Kebayoran Baru',
   st_makepoint(106.811324, -6.239700)::geography,
   'Pasar tradisional yang lantai atasnya berkembang jadi skena indie: kedai kopi, piringan hitam, dan barang vintage.',
   'murah', 60, 'osm', 'node/6957804086', 'medium', false),
  ('Petak Enam', 'Jakarta', 'Glodok', 'Jl. Pancoran No. 43, Jakarta Barat',
   st_makepoint(106.812483, -6.141271)::geography,
   'Pusat kuliner Chinese-Indonesian di deretan ruko heritage Glodok; aneka jajanan dan makanan legendaris kawasan Pecinan. Catatan: ada stan non-halal.',
   'sedang', 60, 'osm', 'node/12164751801', 'medium', false),
  ('Soto Betawi Globe H Oji', 'Jakarta', 'Pasar Baru', 'Jl. Samanhudi No. 4, Pasar Baru',
   st_makepoint(106.833100, -6.161177)::geography,
   'Soto Betawi legendaris sejak era 1980-an, kuah susu/santan dengan daging dan jeroan; dekat kawasan Pasar Baru.',
   'sedang', 45, 'osm', 'node/9754082020', 'medium', false),
  ('Ragusa Es Italia', 'Jakarta', 'Veteran', 'Jl. Veteran I No. 10',
   st_makepoint(106.829951, -6.169614)::geography,
   'Toko es krim gaya Italia sejak 1932, terkenal dengan spaghetti ice cream; interior klasik tak banyak berubah. Dekat Monas.',
   'sedang', 45, 'osm', 'node/5691741721', 'medium', false),
  ('Toko Merah', 'Jakarta', 'Kota Tua', 'Jl. Kali Besar Barat, Tambora',
   st_makepoint(106.811131, -6.135984)::geography,
   'Mansion kolonial merah tahun 1730 di tepi Kali Besar, salah satu bangunan tertua Jakarta; spot foto eksterior (interior jarang dibuka untuk umum).',
   'murah', 20, 'osm', 'way/491984853', 'medium', false),
  ('Pelabuhan Sunda Kelapa', 'Jakarta', 'Penjaringan', 'Jl. Raya Baruna, Penjaringan',
   st_makepoint(106.810294, -6.121587)::geography,
   'Pelabuhan bersejarah abad ke-12 yang masih aktif, dermaga kapal layar pinisi; spot foto matahari terbenam, +/-2 km utara Kota Tua.',
   'murah', 45, 'osm', 'way/1433576940', 'medium', false)
on conflict (source, source_ref) do update set
  name = excluded.name, city = excluded.city, area = excluded.area, address = excluded.address,
  location = excluded.location, description = excluded.description, price_range = excluded.price_range,
  visit_minutes = excluded.visit_minutes, classification_confidence = excluded.classification_confidence,
  is_active = true;

-- 6a. Kategori tempat (is_primary = kategori utama).
insert into mst_place_category (place_id, category_code, is_primary)
select p.id, x.code, x.is_main
from mst_place p
join (values
  ('way/786136444','sejarah_budaya',true), ('way/786136444','jajanan',false),
  ('way/1293529661','makanan_berat',true),
  ('node/4256421918','oleh_oleh',true),
  ('node/3818319845','oleh_oleh',true),
  ('way/376628479','kopi_kafe',true), ('way/376628479','oleh_oleh',false),
  ('way/634270768','sejarah_budaya',true),
  ('way/166968559','sejarah_budaya',true),
  ('way/167064114','seni_kreatif',true), ('way/167064114','sejarah_budaya',false),
  ('way/761092783','religi',true),
  ('node/4373163702','belanja',true), ('node/4373163702','oleh_oleh',false),
  ('way/635545036','keluarga',true), ('way/635545036','alam',false),
  ('node/4321036011','jajanan',true), ('node/4321036011','makanan_berat',false),
  ('node/4243812179','sejarah_budaya',true),
  ('way/1159084257','sejarah_budaya',true), ('way/1159084257','keluarga',false),
  ('relation/9627236','religi',true),
  ('way/754440792','seni_kreatif',true), ('way/754440792','kopi_kafe',false),
  ('node/6957804086','kopi_kafe',true), ('node/6957804086','belanja',false),
  ('node/12164751801','jajanan',true), ('node/12164751801','makanan_berat',false),
  ('node/9754082020','makanan_berat',true),
  ('node/5691741721','manis',true),
  ('way/491984853','sejarah_budaya',true),
  ('way/1433576940','sejarah_budaya',true)
) as x(ref, code, is_main) on x.ref = p.source_ref
where p.source = 'osm'
on conflict (place_id, category_code) do update set is_primary = excluded.is_primary;

-- 6b. Atribut tempat.
insert into mst_place_attribute (place_id, attribute_code)
select p.id, x.code
from mst_place p
join (values
  ('way/786136444','outdoor'), ('way/786136444','spot_foto'), ('way/786136444','legendaris'),
  ('way/1293529661','halal'), ('way/1293529661','legendaris'), ('way/1293529661','budget_murah'),
  ('node/4256421918','indoor'), ('node/4256421918','cocok_hujan'), ('node/4256421918','halal'), ('node/4256421918','legendaris'),
  ('node/3818319845','indoor'), ('node/3818319845','cocok_hujan'), ('node/3818319845','halal'), ('node/3818319845','legendaris'),
  ('way/376628479','indoor'), ('way/376628479','legendaris'), ('way/376628479','budget_murah'),
  ('way/634270768','spot_foto'), ('way/634270768','ramah_anak'),
  ('way/166968559','indoor'), ('way/166968559','cocok_hujan'), ('way/166968559','ramah_anak'), ('way/166968559','budget_murah'),
  ('way/167064114','ramah_anak'), ('way/167064114','cocok_hujan'), ('way/167064114','spot_foto'),
  ('way/761092783','outdoor'), ('way/761092783','indoor'), ('way/761092783','spot_foto'), ('way/761092783','ramah_anak'), ('way/761092783','budget_murah'),
  ('node/4373163702','indoor'), ('node/4373163702','cocok_hujan'), ('node/4373163702','budget_murah'),
  ('way/635545036','outdoor'), ('way/635545036','ramah_anak'), ('way/635545036','spot_foto'),
  ('node/4321036011','outdoor'), ('node/4321036011','budget_murah'),
  ('node/4243812179','indoor'), ('node/4243812179','cocok_hujan'), ('node/4243812179','ramah_anak'), ('node/4243812179','budget_murah'),
  ('way/1159084257','outdoor'), ('way/1159084257','indoor'), ('way/1159084257','ramah_anak'), ('way/1159084257','spot_foto'),
  ('relation/9627236','indoor'), ('relation/9627236','cocok_hujan'), ('relation/9627236','spot_foto'), ('relation/9627236','budget_murah'),
  ('way/754440792','outdoor'), ('way/754440792','indoor'), ('way/754440792','spot_foto'),
  ('node/6957804086','indoor'), ('node/6957804086','cocok_hujan'), ('node/6957804086','budget_murah'),
  ('node/12164751801','indoor'), ('node/12164751801','cocok_hujan'), ('node/12164751801','legendaris'),
  ('node/9754082020','indoor'), ('node/9754082020','halal'), ('node/9754082020','legendaris'),
  ('node/5691741721','indoor'), ('node/5691741721','legendaris'), ('node/5691741721','ramah_anak'),
  ('way/491984853','outdoor'), ('way/491984853','spot_foto'), ('way/491984853','legendaris'),
  ('way/1433576940','outdoor'), ('way/1433576940','spot_foto')
) as x(ref, code) on x.ref = p.source_ref
where p.source = 'osm'
on conflict (place_id, attribute_code) do nothing;

-- 6c. Jam buka HANYA yang bersumber resmi. day_of_week ISO 1=Senin..7=Minggu.
--    generate_series(ds,de) memperluas rentang hari jadi baris per hari.
--    Sumber per tempat:
--      Kartika Sari 07-18 tiap hari: https://www.kartikasari.com/id/stores/
--      Prima Rasa 06-20 tiap hari: bio IG resmi @primarasabakeryandpastry
--      Ragusa 10-21 tiap hari: bio IG resmi @ragusa.jkt
--      Al Jabbar 24 jam: https://masjidrayaaljabbar.com/ (ditulis 00:00-23:59)
--      Jalan Braga: jalan publik, selalu bisa diakses (bukan jam usaha)
--      Museum KAA: https://mkaa.kemlu.go.id/ (Rabu/Kamis/Sabtu 09-12 & 13-15,
--        Jumat 09-11:30 & 13:30-15:30; tutup Minggu/Senin/Selasa + libur nasional)
--      Saung Angklung Udjo: https://angklung-udjo.co.id/pertunjukan (Sen-Jum 08-17, Sab-Min 08-17:30)
--      Farmhouse: bio IG resmi @farmhouselembang (Sen-Jum 09-18, akhir pekan 08-19)
--      M Bloc: bio IG resmi @mblocspace (weekday 07-23, weekend 07-24 -> ditulis 23:59)
--      Museum Fatahillah: https://m.beritajakarta.id/read/144576 (Sab-Min 09-20; weekday belum resmi)
--      Monas (tugu): FB resmi monumennasionaljakarta (Sel-Jum 08-18, loket tutup 17; Senin tutup; akhir pekan belum pasti)
--      Museum Gedung Sate: https://jabarprov.go.id/layanan/museumgedungsate (Sen-Kam 09:30-16; Jum-Min belum terkonfirmasi)
insert into mst_place_opening_hour (place_id, day_of_week, open_time, close_time)
select p.id, g.d, x.o::time, x.c::time
from mst_place p
join (values
  ('node/4256421918',1,7,'07:00','18:00'),
  ('node/3818319845',1,7,'06:00','20:00'),
  ('node/5691741721',1,7,'10:00','21:00'),
  ('way/761092783',1,7,'00:00','23:59'),
  ('way/786136444',1,7,'00:00','23:59'),
  ('way/166968559',3,4,'09:00','12:00'),
  ('way/166968559',3,4,'13:00','15:00'),
  ('way/166968559',6,6,'09:00','12:00'),
  ('way/166968559',6,6,'13:00','15:00'),
  ('way/166968559',5,5,'09:00','11:30'),
  ('way/166968559',5,5,'13:30','15:30'),
  ('way/167064114',1,5,'08:00','17:00'),
  ('way/167064114',6,7,'08:00','17:30'),
  ('way/635545036',1,5,'09:00','18:00'),
  ('way/635545036',6,7,'08:00','19:00'),
  ('way/754440792',1,5,'07:00','23:00'),
  ('way/754440792',6,7,'07:00','23:59'),
  ('node/4243812179',6,7,'09:00','20:00'),
  ('way/1159084257',2,5,'08:00','18:00'),
  ('way/634270768',1,4,'09:30','16:00')
) as x(ref, ds, de, o, c) on x.ref = p.source_ref
cross join lateral generate_series(x.ds, x.de) as g(d)
where p.source = 'osm'
on conflict (place_id, day_of_week, open_time) do update set close_time = excluded.close_time;

-- ---------------------------------------------------------------------
-- TODO(hadi): jam buka resmi belum ditemukan untuk tempat ini, jadi
-- belum di-seed dan planner akan melewatkannya. Cari di situs/IG resmi
-- lalu tambahkan baris mst_place_opening_hour (jangan mengarang):
--   Bandung: Warung Nasi Ibu Imas, Kopi Aroma, Pasar Baru Trade Center,
--            Sudirman Street Day.
--   Jakarta: Masjid Istiqlal (situs resmi 403), Pasar Santa, Petak Enam,
--            Soto Betawi Globe H Oji, Toko Merah, Pelabuhan Sunda Kelapa.
--   Parsial (lengkapi hari yang kurang): Museum Fatahillah (weekday),
--            Monas (tugu akhir pekan), Museum Gedung Sate (Jum-Min).
-- Catatan: Museum KAA tutup hari libur nasional; skema belum memodelkan
--   hari libur, jadi cek manual kalau trip jatuh di tanggal merah.
-- ---------------------------------------------------------------------

commit;