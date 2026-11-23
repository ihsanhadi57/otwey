-- =====================================================================
-- OTWEY: snapshot trip tersimpan per user (PRD FR-40/41)
-- trx_plan tetap menyimpan kolom ringkas; itinerary_json memuat timeline
-- lengkap supaya trip tersimpan bisa dipulihkan persis tanpa dijadwal ulang.
-- =====================================================================

alter table trx_plan
  add column itinerary_json jsonb,
  add column choices_json jsonb not null default '{}'::jsonb;

comment on column trx_plan.itinerary_json is
  'Snapshot Itinerary lengkap (timeline, rute, status) saat trip disimpan.';
comment on column trx_plan.choices_json is
  'Pilihan moda per id leg saat trip disimpan.';

create index trx_plan_saved_user_idx
  on trx_plan (user_id, created_at desc)
  where status = 'saved';