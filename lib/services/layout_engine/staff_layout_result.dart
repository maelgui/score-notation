import 'package:flutter/material.dart';

import 'measure_layout_result.dart';

/// Résultat du layout d'un système (une ligne de portée).
/// 
/// Contient toutes les informations nécessaires pour dessiner un système,
/// avec positions absolues dans la page.
class StaffLayoutResult {
  const StaffLayoutResult({
    required this.systemIndex,
    required this.origin,
    required this.width,
    required this.height,
    required this.staffY,
    required this.measures,
  });

  /// Index du système (0-based).
  final int systemIndex;

  /// Position absolue du système dans la page.
  final Offset origin;

  /// Largeur totale du système.
  final double width;

  /// Hauteur totale du système.
  final double height;

  /// Position Y de la ligne de portée (absolue dans la page).
  final double staffY;

  /// Liste des mesures appartenant au système (avec positions absolues).
  final List<MeasureLayoutResult> measures;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffLayoutResult) return false;
    return systemIndex == other.systemIndex &&
        origin == other.origin &&
        width == other.width &&
        height == other.height &&
        staffY == other.staffY &&
        _listEquals(measures, other.measures);
  }

  @override
  int get hashCode => Object.hash(
        systemIndex,
        origin,
        width,
        height,
        staffY,
        Object.hashAll(measures),
      );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

