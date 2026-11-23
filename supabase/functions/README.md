# Edge Functions OTWEY

API key Google hanya ada di sini, sebagai secret Supabase `GOOGLE_MAPS_API_KEY`.
Aplikasi tidak pernah memegang key Google (docs/RULES.md).

| Function | Google API | Isi | Disimpan |
| --- | --- | --- | --- |
| `place-lookup` | Places API (New) Text Search, field mask `places.id` (SKU IDs only) | Cari `place_id`. Mode batch mengisi `mst_place.google_place_id`. | `google_place_id` (diizinkan permanen) |
| `place-details` | Places API (New) Place Details | Rating, jumlah ulasan, jam buka, status usaha, link Google Maps | Tidak. Cache memori 1 jam |
| `transit-route` | Routes API `computeRoutes` mode `TRANSIT` | Langkah jalan kaki, MRT, LRT, TransJakarta, KRL, bus | `cache_transit_route`, 3 hari |

## Deploy

```bash
supabase login
supabase link --project-ref fhhknuwwrudnvgyolofb
supabase db push                       # migrasi termasuk 20261121000000_google_places.sql
# lalu jalankan isi supabase/seed.sql di SQL Editor (db push tidak menjalankan seed)
supabase secrets set GOOGLE_MAPS_API_KEY=isi_key_di_sini
supabase functions deploy place-lookup
supabase functions deploy place-details
supabase functions deploy transit-route
```

Isi `google_place_id` semua tempat (sekali, pakai service role key dari
Dashboard > Project Settings > API, jangan disimpan di repo):

```bash
curl -X POST https://fhhknuwwrudnvgyolofb.supabase.co/functions/v1/place-lookup \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  -d '{"batch": true, "limit": 120}'
```

Hasilnya `{checked, filled, missed}`. Tempat di `missed` dicek manual.

## Uji cepat

```bash
curl -X POST https://fhhknuwwrudnvgyolofb.supabase.co/functions/v1/transit-route \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"origin":{"lat":-6.2443,"lng":106.8000},"destination":{"lat":-6.1950,"lng":106.8230},"departureTime":"2026-11-25T08:00:00+07:00"}'
```

## Biaya

Batasi kuota harian per API di Google Cloud Console (APIs & Services > Quotas)
dan pasang budget alert, supaya pemakaian berhenti sebelum keluar dari kuota gratis.
