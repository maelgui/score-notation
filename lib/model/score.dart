import 'package:flutter/foundation.dart';

import 'measure.dart';

/// Partition complète de caisse claire écossaise.
///
/// Contient une liste de mesures, chacune avec sa propre signature rythmique.
@immutable
class Score {
  const Score({
    required this.measures,
    this.measuresPerLine = 4,
  });

  /// Liste des mesures de la partition.
  final List<Measure> measures;

  /// Nombre de mesures par ligne pour l'affichage.
  final int measuresPerLine;

  Score copyWith({
    List<Measure>? measures,
    int? measuresPerLine,
  }) {
    return Score(
      measures: measures ?? this.measures,
      measuresPerLine: measuresPerLine ?? this.measuresPerLine,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Score) return false;
    return _listEquals(measures, other.measures) &&
           measuresPerLine == other.measuresPerLine;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(measures.length, measuresPerLine);
  }

  @override
  String toString() {
    return 'Score(${measures.length} measures, $measuresPerLine per line)';
  }

  Map<String, dynamic> toJson() => {
        'measures': measures.map((m) => m.toJson()).toList(),
        'measuresPerLine': measuresPerLine,
      };

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      measures: (json['measures'] as List<dynamic>)
          .map((m) => Measure.fromJson(m as Map<String, dynamic>))
          .toList(),
      measuresPerLine: json['measuresPerLine'] as int? ?? 4,
    );
  }
}
