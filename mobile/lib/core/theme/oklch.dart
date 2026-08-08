import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Converts a CSS `oklch(L C H)` color to a Flutter [Color].
///
/// Uses Björn Ottosson's OKLab matrices (the same ones browsers use for CSS
/// `oklch()`), converting OKLab -> linear sRGB -> gamma-corrected sRGB.
Color oklchToColor(double l, double c, double h) {
  final hueRad = h * math.pi / 180;
  final a = c * math.cos(hueRad);
  final b = c * math.sin(hueRad);

  final lPrime = l + 0.3963377774 * a + 0.2158037573 * b;
  final mPrime = l - 0.1055613458 * a - 0.0638541728 * b;
  final sPrime = l - 0.0894841775 * a - 1.2914855480 * b;

  final lCubed = lPrime * lPrime * lPrime;
  final mCubed = mPrime * mPrime * mPrime;
  final sCubed = sPrime * sPrime * sPrime;

  final rLinear =
      4.0767416621 * lCubed - 3.3077115913 * mCubed + 0.2309699292 * sCubed;
  final gLinear =
      -1.2684380046 * lCubed + 2.6097574011 * mCubed - 0.3413193965 * sCubed;
  final bLinear =
      -0.0041960863 * lCubed - 0.7034186147 * mCubed + 1.7076147010 * sCubed;

  return Color.fromARGB(
    255,
    _linearToSrgbByte(rLinear),
    _linearToSrgbByte(gLinear),
    _linearToSrgbByte(bLinear),
  );
}

int _linearToSrgbByte(double value) {
  final clampedLinear = value.clamp(0.0, 1.0);
  final srgb = clampedLinear <= 0.0031308
      ? clampedLinear * 12.92
      : 1.055 * math.pow(clampedLinear, 1 / 2.4) - 0.055;
  return (srgb.clamp(0.0, 1.0) * 255).round();
}
