import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otwey/core/assets/app_assets.dart';

void main() {
  test('semua file aset brand ada', () {
    final paths = [
      AppAssets.logo,
      AppAssets.logoOnDark,
      AppAssets.logoMark,
      for (final m in OtiMood.values) AppAssets.oti(m),
    ];
    for (final p in paths) {
      expect(File(p).existsSync(), isTrue, reason: p);
    }
  });
}
