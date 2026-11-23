/// Cara menempuh satu perpindahan di itinerary.
enum LegMode { ojol, transum }

/// Kunci stabil satu perpindahan dari koordinat ujungnya (id leg berubah
/// setiap planner jalan ulang, koordinat tidak).
String legKey(double fromLat, double fromLng, double toLat, double toLng) =>
    '${fromLat.toStringAsFixed(4)},${fromLng.toStringAsFixed(4)}>'
    '${toLat.toStringAsFixed(4)},${toLng.toStringAsFixed(4)}';
