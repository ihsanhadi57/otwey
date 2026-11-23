-- =====================================================================
-- Integrasi Google Places + Routes (lewat Edge Function, key tidak di aplikasi).
--
-- * mst_place.google_place_id: satu-satunya data Google yang boleh disimpan
--   permanen (ketentuan Google Maps Platform). Rating, jam buka, dan detail
--   lain diambil langsung lewat Edge Function place-details.
-- * cache_transit_route: hasil Routes API mode TRANSIT yang sudah dinormalisasi,
--   dengan masa berlaku pendek. Hanya Edge Function (service role) yang menulis.
-- =====================================================================

alter table mst_place add column google_place_id text;
create unique index mst_place_google_place_id_idx on mst_place (google_place_id)
  where google_place_id is not null;

create table cache_transit_route (
  id            uuid primary key default gen_random_uuid(),
  -- Kunci: koordinat dibulatkan 3 desimal (sekitar 100 m), hari ISO, dan jam
  -- berangkat dibulatkan ke 15 menit (menit sejak tengah malam).
  origin_key    text not null,
  dest_key      text not null,
  day_of_week   smallint not null check (day_of_week between 1 and 7),
  depart_slot   smallint not null check (depart_slot between 0 and 1439),
  payload       jsonb not null,  -- {minutes, distanceMeters, steps:[...]} atau {steps:[]} kalau tidak ada rute
  created_at    timestamptz not null default now(),
  expires_at    timestamptz not null,
  unique (origin_key, dest_key, day_of_week, depart_slot)
);
create index cache_transit_route_expires_idx on cache_transit_route (expires_at);

alter table cache_transit_route enable row level security;

-- Boleh dibaca publik (isinya bukan data pribadi). Tidak ada policy tulis:
-- hanya service role (Edge Function) yang bisa insert/update.
create policy "public read" on cache_transit_route for select using (expires_at > now());
