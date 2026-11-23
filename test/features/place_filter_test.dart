import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/features/places/domain/place.dart';
import 'package:otwey/features/places/domain/place_filter.dart';

Place _p(String id, String name, {List<String> cats = const ['makanan_berat'], List<String> attrs = const [], PriceRange? price}) =>
    Place(
      id: id,
      name: name,
      city: 'Bandung',
      lat: 0,
      lng: 0,
      visitMinutes: 60,
      categoryCodes: cats,
      attributeCodes: attrs,
      priceRange: price,
      openingHours: const [OpeningHour(dayOfWeek: 5, open: 600, close: 1200)],
    );

void main() {
  final places = [
    _p('imas', 'Warung Nasi Ibu Imas', attrs: ['halal'], price: PriceRange.murah),
    _p('braga', 'Jalan Braga', cats: ['sejarah_budaya'], price: PriceRange.murah),
    _p('steak', 'Waroeng Steak', price: PriceRange.sedang),
  ];
  final friday11 = DateTime(2026, 11, 20, 11);

  test('Pencarian cocok sebagian nama, abaikan kategori vibes', () {
    const f = PlaceFilter(query: 'bu imas');
    expect(f.apply(places, categories: {'sejarah_budaya'}, saved: {}, now: friday11).map((p) => p.id), ['imas']);
  });

  test('Tanpa pencarian pakai kategori vibes, budget, atribut', () {
    const f = PlaceFilter(maxBudget: 'murah', attributes: {'halal'});
    expect(f.apply(places, categories: {'makanan_berat'}, saved: {}, now: friday11).map((p) => p.id), ['imas']);
    expect(f.activeCount, 2);
  });

  test('Buka sekarang dan hanya wishlist', () {
    const f = PlaceFilter(openNow: true, onlySaved: true);
    expect(f.apply(places, categories: {'makanan_berat'}, saved: {'steak'}, now: friday11).map((p) => p.id), ['steak']);
    expect(f.apply(places, categories: {'makanan_berat'}, saved: {'steak'}, now: DateTime(2026, 11, 20, 22)), isEmpty);
  });
}
