// transit-route: rute transportasi umum (MRT, LRT, TransJakarta, KRL, bus)
// dari Google Routes API mode TRANSIT, dinormalisasi jadi langkah sederhana.
//
//   POST { "origin": { "lat": -6.2, "lng": 106.82 },
//          "destination": { "lat": -6.18, "lng": 106.83 },
//          "departureTime": "2026-11-25T08:00:00+07:00" }
//   -> { "minutes": 42, "distanceMeters": 9100, "steps": [
//          { "mode": "walk", "minutes": 6, "distanceMeters": 450 },
//          { "mode": "subway", "line": "MRT Jakarta", "lineShort": "M", "color": "#0057A8",
//            "headsign": "Bundaran HI", "from": "Blok M BCA", "to": "Bundaran HI",
//            "departAt": "2026-11-25T01:07:00Z", "arriveAt": "2026-11-25T01:25:00Z",
//            "minutes": 18, "stops": 9 } ] }
//   Tidak ada rute: { "minutes": null, "distanceMeters": null, "steps": [] }
//
// Hasil disimpan di cache_transit_route (kunci koordinat dibulatkan ~100 m,
// hari, dan slot 15 menit) supaya rute yang sama tidak memanggil Google lagi.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders, error, googleError, googleFetch, isLat, isLng, json, readJson, seconds } from '../_shared/http.ts';

const ROUTES_URL = 'https://routes.googleapis.com/directions/v2:computeRoutes';
const FIELD_MASK = [
  'routes.duration',
  'routes.distanceMeters',
  'routes.legs.steps.travelMode',
  'routes.legs.steps.staticDuration',
  'routes.legs.steps.distanceMeters',
  'routes.legs.steps.transitDetails',
].join(',');
const CACHE_DAYS = 3;
const WIB_OFFSET_MIN = 7 * 60;

type Mode = 'walk' | 'bus' | 'subway' | 'light_rail' | 'rail' | 'other';

interface Step {
  mode: Mode;
  minutes: number;
  distanceMeters?: number;
  line?: string;
  lineShort?: string;
  color?: string;
  headsign?: string;
  from?: string;
  to?: string;
  departAt?: string;
  arriveAt?: string;
  stops?: number;
}

function vehicleMode(type: unknown): Mode {
  switch (type) {
    case 'BUS':
    case 'INTERCITY_BUS':
    case 'TROLLEYBUS':
    case 'SHARE_TAXI':
      return 'bus';
    case 'SUBWAY':
    case 'METRO_RAIL':
      return 'subway';
    case 'LIGHT_RAIL':
    case 'TRAM':
    case 'MONORAIL':
      return 'light_rail';
    case 'RAIL':
    case 'HEAVY_RAIL':
    case 'COMMUTER_TRAIN':
    case 'HIGH_SPEED_TRAIN':
    case 'LONG_DISTANCE_TRAIN':
      return 'rail';
    default:
      return 'other';
  }
}

// deno-lint-ignore no-explicit-any
function normalize(res: any): { minutes: number | null; distanceMeters: number | null; steps: Step[] } {
  const route = res?.routes?.[0];
  if (!route) return { minutes: null, distanceMeters: null, steps: [] };
  const steps: Step[] = [];
  for (const leg of route.legs ?? []) {
    for (const s of leg.steps ?? []) {
      const minutes = Math.max(1, Math.round(seconds(s.staticDuration) / 60));
      if (s.travelMode === 'TRANSIT' && s.transitDetails) {
        const t = s.transitDetails;
        const line = t.transitLine ?? {};
        steps.push({
          mode: vehicleMode(line.vehicle?.type),
          minutes,
          distanceMeters: s.distanceMeters,
          line: line.name ?? line.vehicle?.name?.text,
          lineShort: line.nameShort,
          color: line.color,
          headsign: t.headsign,
          from: t.stopDetails?.departureStop?.name,
          to: t.stopDetails?.arrivalStop?.name,
          departAt: t.stopDetails?.departureTime,
          arriveAt: t.stopDetails?.arrivalTime,
          stops: t.stopCount,
        });
        continue;
      }
      // Langkah jalan kaki beruntun digabung jadi satu.
      const last = steps[steps.length - 1];
      if (last && last.mode === 'walk') {
        last.minutes += minutes;
        last.distanceMeters = (last.distanceMeters ?? 0) + (s.distanceMeters ?? 0);
      } else {
        steps.push({ mode: 'walk', minutes, distanceMeters: s.distanceMeters ?? 0 });
      }
    }
  }
  return {
    minutes: Math.round(seconds(route.duration) / 60),
    distanceMeters: route.distanceMeters ?? null,
    steps,
  };
}

function cacheKey(p: { lat: number; lng: number }): string {
  return `${p.lat.toFixed(3)},${p.lng.toFixed(3)}`;
}

/// Hari ISO dan slot 15 menit di WIB (Jakarta dan Bandung sama-sama WIB).
function slot(departure: Date): { day: number; slot: number } {
  const wib = new Date(departure.getTime() + WIB_OFFSET_MIN * 60_000);
  const day = wib.getUTCDay() === 0 ? 7 : wib.getUTCDay();
  const minutes = wib.getUTCHours() * 60 + wib.getUTCMinutes();
  return { day, slot: Math.floor(minutes / 15) * 15 };
}

function db(): SupabaseClient | null {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  return url && key ? createClient(url, key, { auth: { persistSession: false } }) : null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return error(405, 'method', 'Pakai POST.');
  const body = await readJson(req);
  // deno-lint-ignore no-explicit-any
  const o = body?.origin as any;
  // deno-lint-ignore no-explicit-any
  const d = body?.destination as any;
  if (!o || !d || !isLat(o.lat) || !isLng(o.lng) || !isLat(d.lat) || !isLng(d.lng)) {
    return error(400, 'bad_point', 'origin dan destination wajib {lat, lng}.');
  }
  let departure = typeof body?.departureTime === 'string' ? new Date(body.departureTime) : new Date();
  if (Number.isNaN(departure.getTime())) return error(400, 'bad_time', 'departureTime harus ISO 8601.');
  // Routes API menolak waktu lampau: pakai sekarang kalau sudah lewat.
  if (departure.getTime() < Date.now()) departure = new Date(Date.now() + 60_000);

  const origin = { lat: o.lat as number, lng: o.lng as number };
  const dest = { lat: d.lat as number, lng: d.lng as number };
  const { day, slot: departSlot } = slot(departure);
  const client = db();
  const key = { origin_key: cacheKey(origin), dest_key: cacheKey(dest), day_of_week: day, depart_slot: departSlot };

  if (client) {
    const { data } = await client
      .from('cache_transit_route')
      .select('payload')
      .match(key)
      .gt('expires_at', new Date().toISOString())
      .maybeSingle();
    if (data?.payload) return json(data.payload, 200, { 'X-Cache': 'hit' });
  }

  try {
    const res = await googleFetch(ROUTES_URL, {
      method: 'POST',
      fieldMask: FIELD_MASK,
      body: {
        origin: { location: { latLng: { latitude: origin.lat, longitude: origin.lng } } },
        destination: { location: { latLng: { latitude: dest.lat, longitude: dest.lng } } },
        travelMode: 'TRANSIT',
        departureTime: departure.toISOString(),
        computeAlternativeRoutes: false,
        languageCode: 'id',
        regionCode: 'ID',
        transitPreferences: { routingPreference: 'FEWER_TRANSFERS' },
      },
    });
    const payload = normalize(res);
    if (client) {
      const expires = new Date(Date.now() + CACHE_DAYS * 86_400_000).toISOString();
      await client
        .from('cache_transit_route')
        .upsert({ ...key, payload, expires_at: expires }, { onConflict: 'origin_key,dest_key,day_of_week,depart_slot' });
    }
    return json(payload, 200, { 'X-Cache': 'miss' });
  } catch (e) {
    return googleError(e);
  }
});
