import 'package:flutter/foundation.dart';

/// Signature rythmique d'une mesure.
///
/// Exemple : TimeSignature(4, 4) représente une mesure à 4/4.
@immutable
class TimeSignature {
  const TimeSignature(this.numerator, this.denominator)
      : assert(numerator > 0, 'Le numérateur doit être positif'),
        assert(denominator > 0, 'Le dénominateur doit être positif');

  final int numerator;
  final int denominator;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeSignature) return false;
    return numerator == other.numerator && denominator == other.denominator;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';

  Map<String, dynamic> toJson() => {
        'numerator': numerator,
        'denominator': denominator,
      };

  factory TimeSignature.fromJson(Map<String, dynamic> json) {
    return TimeSignature(
      json['numerator'] as int,
      json['denominator'] as int,
    );
  }
}

