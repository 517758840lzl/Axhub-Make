import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS uses the system UI face. Android uses the platform sans face.
String? get _systemFaceFamily => switch (defaultTargetPlatform) {
      TargetPlatform.iOS => '.AppleSystemUIFont',
      TargetPlatform.android => 'sans-serif',
      _ => null,
    };

/// Status and navigation bars match the canvas: light background, dark icons.
const revolutSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Matches the `--rev-*` tokens in the prototype `style.css`.
abstract final class RevolutColors {
  static const canvas = Color(0xFFF4F4F8);
  static const surface1 = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF0F6);
  static const surface3 = Color(0xFFE4E7F0);
  static const divider = Color(0xFFDFE3EE);
  static const text = Color(0xFF0A0A0F);
  static const textSecondary = Color(0xFF5C5C6F);
  static const textMuted = Color(0xFF8B8B9E);
  static const brandStart = Color(0xFF5B6BFF);
  static const brandEnd = Color(0xFF9C6BFF);
  static const brandSolid = Color(0xFF6B5BFF);
  static const income = Color(0xFF0D9F5F);
  static const spend = Color(0xFFE5484D);
  static const donutTrack = Color(0xFFE2E5F0);

  static const gradient = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4),
    colors: [brandStart, brandEnd],
  );

  static BoxShadow softShadow = BoxShadow(
    color: const Color(0x0F0F172A),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static BoxShadow ctaShadow = BoxShadow(
    color: const Color(0x475B6BFF),
    blurRadius: 24,
    offset: const Offset(0, 8),
    blurStyle: BlurStyle.outer,
  );
}

ThemeData buildRevolutTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: RevolutColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RevolutColors.brandSolid,
      surface: RevolutColors.surface1,
    ),
  );
  final textTheme = base.textTheme.apply(
    fontFamily: _systemFaceFamily,
    bodyColor: RevolutColors.text,
    displayColor: RevolutColors.text,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: revolutSystemUi,
      backgroundColor: RevolutColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
  );
}

TextStyle monoStyle(BuildContext context, {double size = 14, FontWeight w = FontWeight.w600}) {
  return TextStyle(
    fontFamily: _systemFaceFamily,
    fontSize: size,
    fontWeight: w,
    color: RevolutColors.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
