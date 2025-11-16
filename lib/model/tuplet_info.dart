import 'package:flutter/foundation.dart';

/// Information sur un tuplet (division irrégulière du temps).
///
/// Représente "N notes prenant la durée de M notes".
/// Exemple : TupletInfo(3, 2) signifie "3 notes prennent la durée de 2 notes"
/// (triplet).
@immutable
class TupletInfo {
  const TupletInfo(this.actualNotes, this.normalNotes)
      : assert(actualNotes > 0, 'actualNotes doit être positif'),
        assert(normalNotes > 0, 'normalNotes doit être positif'),
        assert(actualNotes != normalNotes,
            'actualNotes et normalNotes doivent être différents');

  /// Nombre de notes dans le tuplet.
  final int actualNotes;

  /// Nombre de notes équivalentes en notation normale.
  final int normalNotes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TupletInfo) return false;
    return actualNotes == other.actualNotes &&
        normalNotes == other.normalNotes;
  }

  @override
  int get hashCode => Object.hash(actualNotes, normalNotes);

  @override
  String toString() => '$actualNotes:$normalNotes';

  Map<String, dynamic> toJson() => {
        'actualNotes': actualNotes,
        'normalNotes': normalNotes,
      };

  factory TupletInfo.fromJson(Map<String, dynamic> json) {
    return TupletInfo(
      json['actualNotes'] as int,
      json['normalNotes'] as int,
    );
  }
}

