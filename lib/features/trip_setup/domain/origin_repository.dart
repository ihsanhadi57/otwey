import 'origin_point.dart';

abstract interface class OriginRepository {
  /// Titik berangkat yang tersedia di [city]: alamat tersimpan dan stasiun.
  Future<List<OriginPoint>> fetchByCity(String city);
}