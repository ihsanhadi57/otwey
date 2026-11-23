import 'place.dart';

abstract interface class PlaceRepository {
  /// Tempat aktif di [city], lengkap dengan kategori, atribut, dan jam buka.
  Future<List<Place>> fetchByCity(String city);
}
