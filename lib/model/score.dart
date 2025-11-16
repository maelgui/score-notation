import 'package:flutter/foundation.dart';

import 'measure.dart';

/// Partition complète de caisse claire écossaise.
///
/// Contient une liste de mesures, chacune avec sa propre signature rythmique.
@immutable
class Score {
  const Score({required this.measures});

  /// Liste des mesures de la partition.
  final List<Measure> measures;

  Score copyWith({List<Measure>? measures}) {
    return Score(measures: measures ?? this.measures);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Score) return false;
    return _listEquals(measures, other.measures);
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
    return measures.length.hashCode;
  }

  @override
  String toString() {
    return 'Score(${measures.length} measures)';
  }

  Map<String, dynamic> toJson() => {
        'measures': measures.map((m) => m.toJson()).toList(),
      };

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      measures: (json['measures'] as List<dynamic>)
          .map((m) => Measure.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

