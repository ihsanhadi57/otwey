import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/edge_function.dart';
import '../domain/transit_route.dart';

/// Permintaan rute transum satu perpindahan. Dipakai sebagai kunci provider.
class TransitQuery {
  const TransitQuery({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.date,
    required this.departMinutes,
  });

  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime date;

  /// Jam berangkat, menit sejak tengah malam WIB.
  final int departMinutes;

  Map<String, dynamic> toJson() => {
        'origin': {'lat': fromLat, 'lng': fromLng},
        'destination': {'lat': toLat, 'lng': toLng},
        'departureTime': wibIso(date, departMinutes),
      };

  // Koordinat dibulatkan ~100 m dan jam ke 15 menit, sama dengan kunci cache
  // server, supaya perubahan kecil tidak memicu panggilan baru.
  String get _key => '${fromLat.toStringAsFixed(3)},${fromLng.toStringAsFixed(3)}>'
      '${toLat.toStringAsFixed(3)},${toLng.toStringAsFixed(3)}@'
      '${date.year}-${date.month}-${date.day}/${departMinutes ~/ 15}';

  @override
  bool operator ==(Object other) => other is TransitQuery && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

/// Rute transum langsung lewat Edge Function `transit-route`.
class TransitRouteRepository {
  const TransitRouteRepository(this._fn);

  final EdgeFunctions _fn;

  Future<TransitRoute?> fetch(TransitQuery q) async => TransitRoute.fromJson(await _fn.call('transit-route', q.toJson()));
}

/// Null kalau Supabase belum dikonfigurasi: kartu perpindahan tetap tampil
/// seperti biasa (ojol / data transum seed).
final transitRouteRepositoryProvider = Provider<TransitRouteRepository?>((ref) {
  final fn = ref.watch(edgeFunctionsProvider);
  return fn == null ? null : TransitRouteRepository(fn);
});

/// Rute transum per perpindahan. Disimpan selama aplikasi hidup supaya tidak
/// dipanggil ulang setiap kali timeline dibangun ulang.
final liveTransitProvider = FutureProvider.family<TransitRoute?, TransitQuery>((ref, q) async {
  final repo = ref.watch(transitRouteRepositoryProvider);
  if (repo == null) return null;
  return repo.fetch(q);
});
