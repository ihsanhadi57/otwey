import 'access_route.dart';

abstract interface class AccessRouteRepository {
  /// Semua rute akses aktif, lengkap dengan langkah berurutan.
  Future<List<AccessRoute>> fetchAll();
}