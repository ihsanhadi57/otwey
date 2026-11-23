-- =====================================================================
-- OTWEY migrasi kedua: kebutuhan App v2 (docs/DATA_PLAN.md "Perubahan skema")
--   * preferensi moda dan titik berangkat di trx_plan
--   * pilihan moda per perpindahan dan alasan stop di trx_plan_item
--   * koridor transum ke dan dari stasiun (mst_access_route + mst_access_step)
--   * aturan ongkos ojol (mst_fare_rule)
--   * wishlist dan titik berangkat tersimpan (trx_wishlist, trx_saved_origin)
--   * index unik supaya seed CSV bisa upsert idempoten (tool/seed_import.dart)
-- Migrasi pertama tidak diubah.
-- =====================================================================

-- ---------------------------------------------------------------------
-- ENUMS baru
-- ---------------------------------------------------------------------
create type travel_mode as enum ('campur', 'ojol', 'transum');
create type leg_mode as enum ('ojol', 'transum');
create type origin_kind as enum ('home', 'work', 'station', 'other');
create type access_direction as enum ('to_station', 'from_station');

-- ---------------------------------------------------------------------
-- TRANSAKSI: kolom tambahan
-- ---------------------------------------------------------------------
alter table trx_plan
  add column travel_mode travel_mode not null default 'campur',
  add column origin_kind origin_kind,
  add column origin_address text;

alter table trx_plan_item
  add column leg_mode leg_mode,
  add column reason text;

-- ---------------------------------------------------------------------
-- MASTER: rute akses transum ke dan dari stasiun kereta cepat
-- Satu rute = urutan langkah (jalan, naik koridor, turun, jalan).
-- Bagian "rumah ke halte" dihitung planner dari koordinat user.
-- ---------------------------------------------------------------------
create table mst_access_route (
  code        text primary key,              -- contoh: cikoko_halim
  station_code text not null references mst_station(code),
  direction   access_direction not null,
  name        text not null,
  source      text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table mst_access_step (
  route_code      text not null references mst_access_route(code) on delete cascade,
  step_seq        smallint not null,
  mode            transport_mode not null,
  service         text,                      -- nama layanan, contoh: LRT Jabodebek
  corridor        text,                      -- nama koridor, contoh: Koridor 1
  from_stop       text,
  to_stop         text,
  minutes         smallint not null check (minutes > 0),
  fare            int not null default 0 check (fare >= 0),
  operating_hours text,
  source          text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  primary key (route_code, step_seq)
);

-- ---------------------------------------------------------------------
-- MASTER: aturan ongkos ojol (dasar + per km). Angka resmi, tampil ±.
-- ---------------------------------------------------------------------
create table mst_fare_rule (
  code        text primary key,              -- motor, mobil
  mode        transport_mode not null,
  city        text,                          -- null = berlaku semua kota
  base_fare   int not null check (base_fare >= 0),
  per_km_fare int not null check (per_km_fare >= 0),
  min_fare    int not null default 0 check (min_fare >= 0),
  source      text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- TRANSAKSI: wishlist dan titik berangkat tersimpan
-- ---------------------------------------------------------------------
create table trx_wishlist (
  user_id     uuid not null references auth.users(id) on delete cascade,
  place_id    uuid not null references mst_place(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, place_id)
);

create table trx_saved_origin (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  city        text not null,
  label       text not null,
  address     text not null,
  kind        origin_kind not null default 'home',
  location    geography(point, 4326),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index trx_saved_origin_user_idx on trx_saved_origin (user_id, city);

-- ---------------------------------------------------------------------
-- TRIGGER updated_at
-- ---------------------------------------------------------------------
create trigger trg_mst_access_route_updated  before update on mst_access_route  for each row execute function set_updated_at();
create trigger trg_mst_access_step_updated   before update on mst_access_step   for each row execute function set_updated_at();
create trigger trg_mst_fare_rule_updated     before update on mst_fare_rule     for each row execute function set_updated_at();
create trigger trg_trx_saved_origin_updated  before update on trx_saved_origin  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- Index unik kunci alami supaya seed.sql bisa on conflict (idempoten).
-- mst_place sudah punya unique (source, source_ref) dari migrasi pertama.
-- ---------------------------------------------------------------------
create unique index mst_whoosh_trip_seed_key
  on mst_whoosh_trip (train_no, direction, valid_from)
  where train_no is not null;

create unique index mst_feeder_route_name_key
  on mst_feeder_route (name);

create unique index mst_feeder_schedule_dep_key
  on mst_feeder_schedule (route_id, departure_time);

create unique index mst_place_opening_hour_key
  on mst_place_opening_hour (place_id, day_of_week, open_time);

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table mst_access_route   enable row level security;
alter table mst_access_step    enable row level security;
alter table mst_fare_rule      enable row level security;
alter table trx_wishlist       enable row level security;
alter table trx_saved_origin   enable row level security;

create policy "public read" on mst_access_route for select using (is_active);
create policy "public read" on mst_access_step  for select using (true);
create policy "public read" on mst_fare_rule    for select using (is_active);

create policy "own wishlist" on trx_wishlist
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own saved origin" on trx_saved_origin
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);