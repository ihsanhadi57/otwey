// place-lookup: cari place_id Google untuk satu tempat, atau isi semua tempat (batch).
//
// Memakai Places API (New) Text Search dengan field mask `places.id` saja
// (SKU "IDs only"). place_id boleh disimpan permanen menurut ketentuan Google.
//
// Satu tempat (anon key boleh):
//   POST { "name": "Gedung Joang 45", "lat": -6.186, "lng": 106.838, "city": "Jakarta" }
//   -> { "placeId": "ChIJ..." | null }
//
// Batch (wajib service role key di header Authorization):
//   POST { "batch": true, "limit": 50, "city": "Jakarta" }
//   -> { "checked": 50, "filled": 47, "missed": ["Nama", ...] }

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders, error, googleError, googleFetch, isLat, isLng, json, readJson } from '../_shared/http.ts';

const SEARCH_URL = 'https://places.googleapis.com/v1/places:searchText';

async function lookup(name: string, lat: number, lng: number, city?: string): Promise<string | null> {
  const res = await googleFetch(SEARCH_URL, {
    method: 'POST',
    fieldMask: 'places.id',
    body: {
      textQuery: city ? `${name}, ${city}` : name,
      languageCode: 'id',
      regionCode: 'ID',
      pageSize: 1,
      locationBias: { circle: { center: { latitude: lat, longitude: lng }, radius: 300 } },
    },
  });
  const places = res['places'];
  if (!Array.isArray(places) || places.length === 0) return null;
  const id = (places[0] as Record<string, unknown>)['id'];
  return typeof id === 'string' ? id : null;
}

/// Ambil koordinat dari kolom geography (GeoJSON atau WKT "POINT(lng lat)").
function point(location: unknown): { lat: number; lng: number } | null {
  if (location && typeof location === 'object') {
    const c = (location as { coordinates?: unknown }).coordinates;
    if (Array.isArray(c) && c.length === 2) return { lng: Number(c[0]), lat: Number(c[1]) };
  }
  if (typeof location === 'string') {
    const m = location.match(/POINT\(([-\d.]+) ([-\d.]+)\)/i);
    if (m) return { lng: Number(m[1]), lat: Number(m[2]) };
  }
  return null;
}

async function batch(req: Request, body: Record<string, unknown>): Promise<Response> {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceKey) return error(500, 'missing_env', 'SUPABASE_URL / SERVICE_ROLE_KEY tidak tersedia.');
  if (req.headers.get('Authorization') !== `Bearer ${serviceKey}`) {
    return error(403, 'forbidden', 'Mode batch hanya untuk service role key.');
  }
  const limit = typeof body.limit === 'number' ? Math.min(Math.max(1, body.limit), 200) : 50;
  const db = createClient(url, serviceKey, { auth: { persistSession: false } });
  let query = db
    .from('mst_place')
    .select('id, name, city, location')
    .is('google_place_id', null)
    .eq('is_active', true)
    .limit(limit);
  if (typeof body.city === 'string') query = query.eq('city', body.city);
  const { data, error: dbError } = await query;
  if (dbError) return error(500, 'db_failed', dbError.message);

  let filled = 0;
  const missed: string[] = [];
  for (const row of data ?? []) {
    const p = point(row.location);
    if (!p) {
      missed.push(row.name);
      continue;
    }
    try {
      const id = await lookup(row.name, p.lat, p.lng, row.city);
      if (!id) {
        missed.push(row.name);
        continue;
      }
      const { error: upErr } = await db.from('mst_place').update({ google_place_id: id }).eq('id', row.id);
      if (upErr) missed.push(`${row.name} (${upErr.message})`);
      else filled++;
    } catch (e) {
      missed.push(`${row.name} (${e instanceof Error ? e.message.slice(0, 80) : e})`);
    }
  }
  return json({ checked: data?.length ?? 0, filled, missed });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return error(405, 'method', 'Pakai POST.');
  const body = await readJson(req);
  if (!body) return error(400, 'bad_json', 'Body harus JSON.');

  if (body.batch === true) return batch(req, body);

  const { name, lat, lng, city } = body;
  if (typeof name !== 'string' || name.trim().length < 2) return error(400, 'bad_name', 'name wajib diisi.');
  if (!isLat(lat) || !isLng(lng)) return error(400, 'bad_point', 'lat/lng tidak valid.');
  try {
    const placeId = await lookup(name.trim(), lat, lng, typeof city === 'string' ? city : undefined);
    return json({ placeId });
  } catch (e) {
    return googleError(e);
  }
});
