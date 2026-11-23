-- =====================================================================
-- Titik ujung rute akses di sisi kota (contoh: Stasiun LRT Dukuh Atas).
-- Planner memakainya untuk menghitung jalan kaki atau ojol dari asal user
-- ke awal rute transum. Rute tanpa titik ini tidak dipakai planner.
-- =====================================================================
alter table mst_access_route
  add column anchor_lat double precision,
  add column anchor_lng double precision;
