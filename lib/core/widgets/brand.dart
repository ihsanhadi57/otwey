import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../assets/app_assets.dart';
import '../config/app_config.dart';

/// Logo OTWEY. Pakai [onDark] di atas latar gelap.
class OtweyLogo extends StatelessWidget {
  const OtweyLogo({this.height = 32, this.onDark = false, super.key});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        onDark ? AppAssets.logoOnDark : AppAssets.logo,
        height: height,
        semanticsLabel: AppConfig.appName,
      );
}

/// Maskot Oti. Rasio gambar 200 x 220.
class Oti extends StatelessWidget {
  const Oti({this.mood = OtiMood.happy, this.size = 160, super.key});

  final OtiMood mood;

  /// Lebar dalam logical pixel. Tinggi otomatis 1,1 kali lebar.
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        AppAssets.oti(mood),
        width: size,
        height: size * 1.1,
        semanticsLabel: 'Oti',
      );
}
