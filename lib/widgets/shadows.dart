import 'package:flutter/material.dart';
import '../theme.dart';

/// Erzeugt schmale, aber klare Schatten je nach Elevation.
///
/// Kleine Elemente erhalten einen feineren Schatten; größere Flächen
/// bekommen einen etwas tieferen, weicheren Look. Dadurch wirkt die UI
/// weniger flach, ohne dass sie zu schwer oder "materialistisch" wird.
List<BoxShadow> shadowForElevation(double elevation, {Color? accent}) {
  final color = accent ?? cOrange;

  if (elevation <= 0) return const [];
  if (elevation <= 2) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 10,
        spreadRadius: -3,
        offset: const Offset(0, 3),
      ),
    ];
  }
  if (elevation <= 4) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.10),
        blurRadius: 16,
        spreadRadius: -4,
        offset: const Offset(0, 6),
      ),
    ];
  }

  return [
    BoxShadow(
      color: color.withValues(alpha: 0.14),
      blurRadius: 24,
      spreadRadius: -5,
      offset: const Offset(0, 10),
    ),
  ];
}
