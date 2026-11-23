/// Nilai dari `--dart-define-from-file=.env`.
///
/// Hanya nilai yang memang aman ada di aplikasi. API key Google tidak boleh di sini,
/// panggil lewat Supabase Edge Function (lihat docs/RULES.md).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
