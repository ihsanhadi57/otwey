// place-details: detail langsung satu tempat Google (rating, jam buka, status).
//
// Tidak disimpan ke database (ketentuan Google: hanya place_id yang boleh
// disimpan permanen). Ada cache singkat di memori instance dan header
// Cache-Control supaya tidak memanggil Google berulang dalam waktu dekat.
//
//   POST { "placeId": "ChIJ..." }
//   -> { id, displayName, rating, userRatingCount, businessStatus,
//        googleMapsUri, regularOpeningHours: { periods, weekdayDescriptions },
//        currentOpeningHours: { openNow } }

import { corsHeaders, error, googleError, googleFetch, json, readJson } from '../_shared/http.ts';

const FIELD_MASK = [
  'id',
  'displayName',
  'rating',
  'userRatingCount',
  'businessStatus',
  'googleMapsUri',
  'regularOpeningHours.periods',
  'regularOpeningHours.weekdayDescriptions',
  'currentOpeningHours.openNow',
].join(',');

const TTL_MS = 60 * 60 * 1000;
const memo = new Map<string, { at: number; body: Record<string, unknown> }>();

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return error(405, 'method', 'Pakai POST.');
  const body = await readJson(req);
  const placeId = body?.placeId;
  if (typeof placeId !== 'string' || !/^[A-Za-z0-9_-]{10,300}$/.test(placeId)) {
    return error(400, 'bad_place_id', 'placeId tidak valid.');
  }

  const hit = memo.get(placeId);
  if (hit && Date.now() - hit.at < TTL_MS) {
    return json(hit.body, 200, { 'Cache-Control': 'public, max-age=3600', 'X-Cache': 'hit' });
  }

  try {
    const res = await googleFetch(
      `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?languageCode=id&regionCode=ID`,
      { method: 'GET', fieldMask: FIELD_MASK },
    );
    if (memo.size > 500) memo.clear();
    memo.set(placeId, { at: Date.now(), body: res });
    return json(res, 200, { 'Cache-Control': 'public, max-age=3600', 'X-Cache': 'miss' });
  } catch (e) {
    return googleError(e);
  }
});
