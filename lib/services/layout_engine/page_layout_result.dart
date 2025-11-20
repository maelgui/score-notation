import 'package:flutter/material.dart';

import 'staff_layout_result.dart';

/// Résultat du layout d'une page.
/// 
/// Contient toutes les informations nécessaires pour dessiner la page,
/// avec positions absolues et structure hiérarchique.
class PageLayoutResult {
  const PageLayoutResult({
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.origin,
    required this.systems,
  });

  /// Index de la page (0-based, pour support multi-page).
  final int pageIndex;

  /// Largeur totale de la page.
  final double width;

  /// Hauteur totale de la page.
  final double height;

  /// Position absolue de la page dans le canvas global (pour multi-page).
  final Offset origin;

  /// Liste des systèmes (lignes de portée) de la page.
  final List<StaffLayoutResult> systems;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PageLayoutResult) return false;
    return pageIndex == other.pageIndex &&
        width == other.width &&
        height == other.height &&
        origin == other.origin &&
        _listEquals(systems, other.systems);
  }

  @override
  int get hashCode => Object.hash(
        pageIndex,
        width,
        height,
        origin,
        Object.hashAll(systems),
      );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}