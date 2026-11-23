-- =====================================================================
-- OTWEY: day trip planner untuk penumpang Whoosh
-- Database schema (Supabase / PostgreSQL + PostGIS)
--
-- Konvensi penamaan
--   mst_    : data master / referensi. Jarang berubah, diisi admin.
--   trx_    : data transaksi. Dibuat user setiap kali memakai aplikasi.
--   cache_  : data turunan yang boleh dihapus kapan saja (hasil API).
--   Nama tabel singular (mst_station, bukan mst_stations).
--   Semua tabel punya created_at; tabel yang bisa diedit punya updated_at.
-- =====================================================================

create extension if not exists postgis;
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------
create type station_type   as enum ('whoosh', 'feeder', 'hub');
create type trip_direction as enum ('jakarta_to_bandung', 'bandung_to_jakarta');
create type transport_mode as enum (
  'whoosh', 'ka_feeder', 'commuter_line', 'damri', 'bus',
  'walk', 'drive', 'two_wheeler', 'transit'
);
create type category_group as enum ('kuliner', 'wisata');
create type price_range    as enum ('murah', 'sedang', 'mahal');
create type data_source    as enum ('google', 'osm', 'foursquare', 'manual');
create type plan_status    as enum ('draft', 'generated', 'saved');
create type plan_item_type as enum ('whoosh', 'feeder', 'travel', 'place', 'buffer');
create type pin_priority   as enum ('wajib', 'penting', 'opsional');   -- UI: Wajib / Penting / Kalau sempat
create type pin_purpose    as enum ('kerja', 'janji', 'main', 'lainnya');

-- Trigger umum untuk updated_at
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- =====================================================================
-- MASTER: STASIUN & TRANSPORTASI
-- =====================================================================

create table mst_station (
  id          smallserial primary key,
  code        text unique not null,          -- HLM, KRW, PDL, TGL, BD, CMI
  name        text not null,
  city        text not null,
  type        station_type not null,
  location    geography(point, 4326),        -- isi koordinat sebelum dipakai planner
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Satu baris = satu perjalanan kereta Whoosh
create table mst_whoosh_trip (
  id            serial primary key,
  train_no      text,                         -- contoh: G1211 (opsional)
  direction     trip_direction not null,
  service_days  smallint[] not null default '{1,2,3,4,5,6,7}',  -- ISO: 1 Senin ... 7 Minggu
  valid_from    date not null default current_date,
  valid_to      date,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Pemberhentian tiap perjalanan (model seperti GTFS stop_times)
create table mst_whoosh_trip_stop (
  trip_id         int not null references mst_whoosh_trip(id) on delete cascade,
  station_id      smallint not null references mst_station(id),
  stop_sequence   smallint not null,
  arrival_time    time,                       -- null di stasiun awal
  departure_time  time,                       -- null di stasiun akhir
  created_at      timestamptz not null default now(),
  primary key (trip_id, stop_sequence)
);
create index mst_whoosh_trip_stop_dep_idx on mst_whoosh_trip_stop (station_id, departure_time);
create index mst_whoosh_trip_stop_arr_idx on mst_whoosh_trip_stop (station_id, arrival_time);

-- Rute lanjutan dari stasiun Whoosh / feeder menuju kota
create table mst_feeder_route (
  id                      serial primary key,
  name                    text not null,      -- contoh: KA Feeder Padalarang - Bandung
  mode                    transport_mode not null,
  origin_station_id       smallint not null references mst_station(id),
  destination_station_id  smallint not null references mst_station(id),
  duration_minutes        smallint not null,
  fare                    int not null default 0,   -- rupiah
  free_for_whoosh         boolean not null default false,
  notes                   text,
  is_active               boolean not null default true,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create table mst_feeder_schedule (
  id                serial primary key,
  route_id          int not null references mst_feeder_route(id) on delete cascade,
  departure_time    time not null,
  arrival_time      time not null,
  connects_trip_id  int references mst_whoosh_trip(id),   -- perjalanan Whoosh yang disambung
  service_days      smallint[] not null default '{1,2,3,4,5,6,7}',
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index mst_feeder_schedule_route_dep_idx on mst_feeder_schedule (route_id, departure_time);

-- =====================================================================
-- MASTER: TEMPAT WISATA & KULINER
-- =====================================================================

create table mst_category (
  code        text primary key,
  name        text not null,                  -- label yang tampil di aplikasi
  grp         category_group not null,
  icon        text,                           -- nama ikon Material Symbols
  sort_order  smallint not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table mst_attribute (
  code        text primary key,
  name        text not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table mst_place (
  id                         uuid primary key default gen_random_uuid(),
  name                       text not null,
  city                       text not null,   -- Bandung / Jakarta
  area                       text,            -- Braga, Dago, Lembang, Kota Tua
  address                    text,
  location                   geography(point, 4326) not null,
  description                text,
  price_range                price_range,
  visit_minutes              smallint not null default 60,
  photo_url                  text,
  source                     data_source not null default 'manual',
  source_ref                 text,            -- place_id Google / id OSM
  classification_confidence  text check (classification_confidence in ('high', 'medium', 'low')),
  is_verified                boolean not null default false,
  is_active                  boolean not null default true,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now(),
  unique (source, source_ref)
);
create index mst_place_location_idx on mst_place using gist (location);
create index mst_place_city_idx on mst_place (city) where is_active;

create table mst_place_category (
  place_id       uuid not null references mst_place(id) on delete cascade,
  category_code  text not null references mst_category(code),
  is_primary     boolean not null default false,
  created_at     timestamptz not null default now(),
  primary key (place_id, category_code)
);

create table mst_place_attribute (
  place_id        uuid not null references mst_place(id) on delete cascade,
  attribute_code  text not null references mst_attribute(code),
  created_at      timestamptz not null default now(),
  primary key (place_id, attribute_code)
);

-- Boleh lebih dari satu baris per hari (contoh: buka 10-14 lalu 17-22)
create table mst_place_opening_hour (
  id           serial primary key,
  place_id     uuid not null references mst_place(id) on delete cascade,
  day_of_week  smallint not null check (day_of_week between 1 and 7),
  open_time    time not null,
  close_time   time not null,
  created_at   timestamptz not null default now()
);
create index mst_place_opening_hour_idx on mst_place_opening_hour (place_id, day_of_week);

-- =====================================================================
-- MASTER: TIPE TRIP
-- =====================================================================

create table mst_trip_type (
  code         text primary key,
  name         text not null,
  description  text,
  icon         text,
  sort_order   smallint not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

create table mst_trip_type_category (
  trip_type_code  text not null references mst_trip_type(code) on delete cascade,
  category_code   text not null references mst_category(code),
  weight          numeric(3,2) not null default 1.0,   -- prioritas kategori dalam tipe trip
  primary key (trip_type_code, category_code)
);

-- =====================================================================
-- TRANSAKSI: RENCANA PERJALANAN
-- =====================================================================

create table trx_plan (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid references auth.users(id) on delete cascade,
  direction           trip_direction not null,
  origin_label        text,                   -- contoh: "Rumah, Tebet"
  origin_location     geography(point, 4326),
  travel_date         date not null,
  earliest_departure  time not null,          -- paling cepat berangkat dari lokasi asal
  latest_return       time not null,          -- paling lambat tiba kembali
  arrival_station_id  smallint references mst_station(id),
  trip_type_code      text references mst_trip_type(code),
  budget              price_range,
  with_kids           boolean not null default false,
  status              plan_status not null default 'draft',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index trx_plan_user_idx on trx_plan (user_id, created_at desc);

-- Tujuan yang dipilih sendiri oleh user (kerjaan, janji, tempat incaran)
-- Planner mengunci pin berjam tetap lebih dulu, lalu pin tanpa jam sesuai
-- prioritas, baru sisa waktu diisi rekomendasi dari mst_place.
create table trx_plan_pin (
  id                uuid primary key default gen_random_uuid(),
  plan_id           uuid not null references trx_plan(id) on delete cascade,
  -- tempat dari master ATAU tempat custom (kantor klien, rumah teman)
  place_id          uuid references mst_place(id),
  custom_name       text,
  custom_address    text,
  custom_location   geography(point, 4326),
  google_place_id   text,                     -- kalau user pilih dari autocomplete
  purpose           pin_purpose not null default 'main',
  priority          pin_priority not null default 'penting',
  fixed_start       time,                     -- diisi = jam tetap, kosong = bebas jam
  fixed_end         time,
  duration_minutes  smallint,                 -- dipakai kalau tidak ada jam tetap
  note              text,
  sort_order        smallint not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint trx_plan_pin_place_chk check (
    place_id is not null
    or (custom_name is not null and custom_location is not null)
  ),
  constraint trx_plan_pin_time_chk check (
    (fixed_start is null and fixed_end is null and duration_minutes is not null)
    or (fixed_start is not null and fixed_end is not null and fixed_end > fixed_start)
  )
);
create index trx_plan_pin_plan_idx on trx_plan_pin (plan_id, priority);

-- Urutan kegiatan dalam satu rencana (hasil susunan planner)
create table trx_plan_item (
  id                  uuid primary key default gen_random_uuid(),
  plan_id             uuid not null references trx_plan(id) on delete cascade,
  seq                 smallint not null,
  item_type           plan_item_type not null,
  start_time          time not null,
  end_time            time not null,
  pin_id              uuid references trx_plan_pin(id) on delete set null,   -- terisi kalau item berasal dari pin user
  is_locked           boolean not null default false,  -- true = jam tetap, tidak boleh digeser planner
  place_id            uuid references mst_place(id),
  whoosh_trip_id      int references mst_whoosh_trip(id),
  feeder_schedule_id  int references mst_feeder_schedule(id),
  travel_mode         transport_mode,
  note                text,
  created_at          timestamptz not null default now(),
  unique (plan_id, seq)
);

-- =====================================================================
-- CACHE: hasil Google Routes API supaya hemat kuota
-- =====================================================================

create table cache_travel_time (
  from_key          text not null,            -- 'place:<uuid>' atau 'station:<code>'
  to_key            text not null,
  mode              transport_mode not null,
  duration_minutes  smallint not null,
  distance_meters   int,
  fetched_at        timestamptz not null default now(),
  primary key (from_key, to_key, mode)
);

-- =====================================================================
-- TRIGGER updated_at
-- =====================================================================

create trigger trg_mst_station_updated         before update on mst_station         for each row execute function set_updated_at();
create trigger trg_mst_whoosh_trip_updated     before update on mst_whoosh_trip     for each row execute function set_updated_at();
create trigger trg_mst_feeder_route_updated    before update on mst_feeder_route    for each row execute function set_updated_at();
create trigger trg_mst_feeder_schedule_updated before update on mst_feeder_schedule for each row execute function set_updated_at();
create trigger trg_mst_place_updated           before update on mst_place           for each row execute function set_updated_at();
create trigger trg_trx_plan_updated            before update on trx_plan            for each row execute function set_updated_at();
create trigger trg_trx_plan_pin_updated        before update on trx_plan_pin        for each row execute function set_updated_at();

-- =====================================================================
-- FUNGSI BANTU
-- =====================================================================

-- Tempat yang buka pada jendela waktu tertentu dan berada dalam radius
create or replace function fn_place_open_near(
  p_lat         double precision,
  p_lng         double precision,
  p_radius_m    int,
  p_day         smallint,          -- ISO 1..7
  p_from        time,
  p_to          time,
  p_categories  text[] default null
)
returns setof mst_place
language sql stable as $$
  select p.*
  from mst_place p
  where p.is_active
    and st_dwithin(p.location, st_makepoint(p_lng, p_lat)::geography, p_radius_m)
    and exists (
      select 1 from mst_place_opening_hour h
      where h.place_id = p.id
        and h.day_of_week = p_day
        and h.open_time <= p_from
        and h.close_time >= p_to
    )
    and (
      p_categories is null
      or exists (
        select 1 from mst_place_category pc
        where pc.place_id = p.id and pc.category_code = any(p_categories)
      )
    );
$$;

-- Generator jadwal Whoosh berpola tetap
--   p_station_codes : urutan stasiun, contoh '{HLM,KRW,PDL,TGL}'
--   p_offsets_min   : menit TIBA di tiap stasiun dihitung dari keberangkatan awal
--                     (sudah termasuk waktu berhenti di stasiun sebelumnya)
--   p_dwell_min     : lama berhenti di stasiun antara
--   p_every_hours   : 1 = setiap jam, 2 = setiap 2 jam
--   p_minutes       : menit keberangkatan, contoh '{0,25}'
create or replace function fn_generate_whoosh_trip(
  p_direction      trip_direction,
  p_station_codes  text[],
  p_offsets_min    int[],
  p_dwell_min      int,
  p_first_hour     int,
  p_last_hour      int,
  p_every_hours    int,
  p_minutes        int[]
)
returns int
language plpgsql as $$
declare
  v_hour    int := p_first_hour;
  v_minute  int;
  v_start   time;
  v_trip    int;
  v_last    int := array_length(p_station_codes, 1);
  v_count   int := 0;
  i         int;
begin
  while v_hour <= p_last_hour loop
    foreach v_minute in array p_minutes loop
      v_start := make_time(v_hour, v_minute, 0);

      insert into mst_whoosh_trip (direction) values (p_direction)
      returning id into v_trip;

      for i in 1..v_last loop
        insert into mst_whoosh_trip_stop (trip_id, station_id, stop_sequence, arrival_time, departure_time)
        select
          v_trip, s.id, i,
          case when i = 1 then null
               else v_start + make_interval(mins => p_offsets_min[i]) end,
          case when i = v_last then null
               when i = 1 then v_start
               else v_start + make_interval(mins => p_offsets_min[i] + p_dwell_min) end
        from mst_station s
        where s.code = p_station_codes[i];
      end loop;

      v_count := v_count + 1;
    end loop;
    v_hour := v_hour + p_every_hours;
  end loop;

  return v_count;
end $$;

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================

alter table mst_station             enable row level security;
alter table mst_whoosh_trip         enable row level security;
alter table mst_whoosh_trip_stop    enable row level security;
alter table mst_feeder_route        enable row level security;
alter table mst_feeder_schedule     enable row level security;
alter table mst_category            enable row level security;
alter table mst_attribute           enable row level security;
alter table mst_place               enable row level security;
alter table mst_place_category      enable row level security;
alter table mst_place_attribute     enable row level security;
alter table mst_place_opening_hour  enable row level security;
alter table mst_trip_type           enable row level security;
alter table mst_trip_type_category  enable row level security;
alter table trx_plan                enable row level security;
alter table trx_plan_pin            enable row level security;
alter table trx_plan_item           enable row level security;
alter table cache_travel_time       enable row level security;

-- Master: semua boleh baca, tulis hanya lewat service role / dashboard
create policy "public read" on mst_station             for select using (is_active);
create policy "public read" on mst_whoosh_trip         for select using (is_active);
create policy "public read" on mst_whoosh_trip_stop    for select using (true);
create policy "public read" on mst_feeder_route        for select using (is_active);
create policy "public read" on mst_feeder_schedule     for select using (is_active);
create policy "public read" on mst_category            for select using (is_active);
create policy "public read" on mst_attribute           for select using (is_active);
create policy "public read" on mst_place               for select using (is_active);
create policy "public read" on mst_place_category      for select using (true);
create policy "public read" on mst_place_attribute     for select using (true);
create policy "public read" on mst_place_opening_hour  for select using (true);
create policy "public read" on mst_trip_type           for select using (is_active);
create policy "public read" on mst_trip_type_category  for select using (true);

-- Transaksi: hanya pemilik (pakai Supabase anonymous sign in untuk demo tanpa login)
create policy "own plan" on trx_plan
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own plan pin" on trx_plan_pin
  for all using (
    exists (select 1 from trx_plan p where p.id = plan_id and p.user_id = auth.uid())
  ) with check (
    exists (select 1 from trx_plan p where p.id = plan_id and p.user_id = auth.uid())
  );

create policy "own plan item" on trx_plan_item
  for all using (
    exists (select 1 from trx_plan p where p.id = plan_id and p.user_id = auth.uid())
  ) with check (
    exists (select 1 from trx_plan p where p.id = plan_id and p.user_id = auth.uid())
  );

-- cache_travel_time: tanpa policy, hanya diakses Edge Function dengan service role

-- =====================================================================
-- SEED DATA (master)
-- =====================================================================

insert into mst_station (code, name, city, type) values
  ('HLM', 'Stasiun Halim',                'Jakarta',  'whoosh'),
  ('KRW', 'Stasiun Karawang',             'Karawang', 'whoosh'),
  ('PDL', 'Stasiun Padalarang',           'Bandung',  'whoosh'),
  ('TGL', 'Stasiun Tegalluar Summarecon', 'Bandung',  'whoosh'),
  ('BD',  'Stasiun Bandung',              'Bandung',  'hub'),
  ('CMI', 'Stasiun Cimahi',               'Cimahi',   'feeder');

-- Label kategori memakai gaya bahasa aplikasi (casual)
insert into mst_category (code, name, grp, icon, sort_order) values
  ('makanan_berat',  'Makan Kenyang',     'kuliner', 'rice_bowl',        1),
  ('jajanan',        'Jajan Jajan',       'kuliner', 'tapas',            2),
  ('manis',          'Manis Manis',       'kuliner', 'icecream',         3),
  ('kopi_kafe',      'Ngopi',             'kuliner', 'coffee',           4),
  ('makanan_barat',  'Burger & Western',  'kuliner', 'lunch_dining',     5),
  ('oleh_oleh',      'Oleh Oleh',         'kuliner', 'shopping_bag',     6),
  ('alam',           'Healing di Alam',   'wisata',  'forest',           7),
  ('sejarah_budaya', 'Sejarah & Budaya',  'wisata',  'account_balance',  8),
  ('belanja',        'Belanja',           'wisata',  'storefront',       9),
  ('seni_kreatif',   'Seni & Kreatif',    'wisata',  'palette',         10),
  ('religi',         'Wisata Religi',     'wisata',  'mosque',          11),
  ('keluarga',       'Bareng Keluarga',   'wisata',  'family',          12);

insert into mst_attribute (code, name) values
  ('indoor',        'Indoor'),
  ('outdoor',       'Outdoor'),
  ('cocok_hujan',   'Aman pas hujan'),
  ('ramah_anak',    'Ramah bocil'),
  ('halal',         'Halal'),
  ('legendaris',    'Legend'),
  ('spot_foto',     'Spot foto'),
  ('budget_murah',  'Hemat'),
  ('budget_sedang', 'Sedang'),
  ('budget_mahal',  'Sultan');

insert into mst_trip_type (code, name, description, icon, sort_order) values
  ('kulineran', 'Kulineran',       'Datang lapar, pulang kenyang',      'restaurant',      1),
  ('alam',      'Healing',         'Cari udara seger, otak adem',       'forest',          2),
  ('budaya',    'Nostalgia Kota',  'Gedung tua, museum, cerita lama',   'account_balance', 3),
  ('belanja',   'Mode Checkout',   'FO, pasar, sama oleh oleh',         'shopping_bag',    4),
  ('keluarga',  'Family Trip',     'Seru dan aman buat bocil',          'family',          5),
  ('campuran',  'Campur Aduk',     'Dikit dikit dari semuanya',         'auto_awesome',    6);

insert into mst_trip_type_category (trip_type_code, category_code, weight) values
  ('kulineran', 'makanan_berat', 1.0), ('kulineran', 'jajanan', 1.0),
  ('kulineran', 'manis', 0.8),         ('kulineran', 'kopi_kafe', 0.6),
  ('kulineran', 'makanan_barat', 0.5), ('kulineran', 'oleh_oleh', 0.5),
  ('alam', 'alam', 1.0),               ('alam', 'kopi_kafe', 0.6),
  ('budaya', 'sejarah_budaya', 1.0),   ('budaya', 'seni_kreatif', 0.8),
  ('budaya', 'religi', 0.6),
  ('belanja', 'belanja', 1.0),         ('belanja', 'oleh_oleh', 0.9),
  ('keluarga', 'keluarga', 1.0),       ('keluarga', 'alam', 0.6),
  ('campuran', 'makanan_berat', 0.8),  ('campuran', 'sejarah_budaya', 0.8),
  ('campuran', 'alam', 0.7),           ('campuran', 'belanja', 0.6),
  ('campuran', 'manis', 0.6);

-- ---------------------------------------------------------------------
-- Contoh generate jadwal Whoosh
-- PENTING: offset menit di bawah hanya contoh. Ganti dengan jadwal resmi.
-- ---------------------------------------------------------------------
-- select fn_generate_whoosh_trip(
--   'jakarta_to_bandung', '{HLM,KRW,PDL,TGL}', '{0,15,35,47}', 2,
--   6, 20, 2, '{0,25}'
-- );
-- select fn_generate_whoosh_trip(
--   'bandung_to_jakarta', '{TGL,PDL,KRW,HLM}', '{0,12,32,47}', 2,
--   6, 20, 2, '{0,25}'
-- );

-- ---------------------------------------------------------------------
-- Contoh isi feeder (silakan lengkapi)
-- ---------------------------------------------------------------------
-- insert into mst_feeder_route
--   (name, mode, origin_station_id, destination_station_id, duration_minutes, fare, free_for_whoosh)
-- values (
--   'KA Feeder Padalarang - Bandung', 'ka_feeder',
--   (select id from mst_station where code = 'PDL'),
--   (select id from mst_station where code = 'BD'),
--   19, 0, true
-- );
