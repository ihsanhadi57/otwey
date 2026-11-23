// Utilitas bersama Edge Function OTWEY: CORS, respon JSON, dan akses Google.
// API key Google hanya dibaca di sini dari secret Supabase, tidak pernah dikirim ke aplikasi.

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', ...extra },
  });
}

export function error(status: number, code: string, message: string): Response {
  return json({ error: { code, message } }, status);
}

export function googleKey(): string | null {
  const key = Deno.env.get('GOOGLE_MAPS_API_KEY');
  return key && key.length > 0 ? key : null;
}

export async function readJson(req: Request): Promise<Record<string, unknown> | null> {
  try {
    const body = await req.json();
    return body && typeof body === 'object' ? (body as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

export function isLat(v: unknown): v is number {
  return typeof v === 'number' && Number.isFinite(v) && v >= -90 && v <= 90;
}

export function isLng(v: unknown): v is number {
  return typeof v === 'number' && Number.isFinite(v) && v >= -180 && v <= 180;
}

/// Durasi Google ("123s") ke detik.
export function seconds(duration: unknown): number {
  if (typeof duration !== 'string') return 0;
  const n = Number.parseFloat(duration.replace('s', ''));
  return Number.isFinite(n) ? n : 0;
}

/// Panggil API Google dengan batas waktu. Melempar Error berisi status bila gagal.
export async function googleFetch(
  url: string,
  init: { method: 'GET' | 'POST'; fieldMask: string; body?: unknown },
): Promise<Record<string, unknown>> {
  const key = googleKey();
  if (!key) throw new Error('missing_key');
  const res = await fetch(url, {
    method: init.method,
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': key,
      'X-Goog-FieldMask': init.fieldMask,
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
    signal: AbortSignal.timeout(10_000),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`google_${res.status}: ${text.slice(0, 300)}`);
  return text.length === 0 ? {} : JSON.parse(text);
}

/// Ubah Error Google jadi respon JSON yang rapi.
export function googleError(e: unknown): Response {
  const msg = e instanceof Error ? e.message : String(e);
  if (msg === 'missing_key') {
    return error(500, 'missing_key', 'Secret GOOGLE_MAPS_API_KEY belum diset.');
  }
  if (msg.startsWith('google_429')) return error(429, 'quota', 'Kuota Google habis untuk hari ini.');
  if (msg.includes('TimeoutError') || msg.includes('timed out')) {
    return error(504, 'timeout', 'Google tidak menjawab tepat waktu.');
  }
  return error(502, 'google_failed', msg);
}
