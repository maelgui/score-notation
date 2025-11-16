import 'package:flutter/foundation.dart';

/// Représente une durée musicale comme une fraction rationnelle exacte.
///
/// Utilise uniquement des entiers pour éviter les erreurs de précision des floats.
/// Exemple : DurationFraction(1, 4) représente une noire (1/4 de ronde).
@immutable
class DurationFraction {
  const DurationFraction(this.numerator, this.denominator)
      : assert(denominator > 0, 'Le dénominateur doit être positif'),
        assert(numerator >= 0, 'Le numérateur doit être positif ou nul');

  final int numerator;
  final int denominator;

  /// Retourne une version normalisée de la fraction (dénominateur positif).
  DurationFraction normalized() {
    if (denominator < 0) {
      return DurationFraction(-numerator, -denominator);
    }
    return this;
  }

  /// Retourne une version réduite de la fraction (PGCD).
  DurationFraction reduce() {
    if (numerator == 0) {
      return const DurationFraction(0, 1);
    }
    final int gcd = _gcd(numerator.abs(), denominator.abs());
    return DurationFraction(numerator ~/ gcd, denominator ~/ gcd);
  }

  /// Normalise cette fraction en une fraction unitaire (1/n) si possible.
  /// 
  /// Pour les durées musicales standard, on veut toujours des fractions de la forme 1/n.
  /// Exemple : 2/4 devient 1/2, 3/8 reste 3/8 (ne peut pas être simplifié en 1/n).
  /// 
  /// Retourne null si la fraction ne peut pas être normalisée en 1/n.
  /// 
  /// Note: Cette méthode ne doit PAS être utilisée pour les tuplets ou les durées totales.
  DurationFraction? normalizeToUnitFraction() {
    if (numerator == 0) {
      return const DurationFraction(0, 1);
    }
    final reduced = reduce();
    // Si le numérateur est 1, c'est déjà une fraction unitaire
    if (reduced.numerator == 1) {
      return reduced;
    }
    // Si le numérateur divise le dénominateur, on peut normaliser
    if (denominator % numerator == 0) {
      return DurationFraction(1, denominator ~/ numerator);
    }
    // Sinon, on ne peut pas normaliser en 1/n
    return null;
  }

  /// Vérifie si cette fraction est une fraction unitaire (numérateur = 1).
  bool isUnitFraction() {
    final reduced = reduce();
    return reduced.numerator == 1;
  }

  /// Calcule le PGCD de deux entiers.
  int _gcd(int a, int b) {
    while (b != 0) {
      final int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// Multiplie cette fraction par une autre.
  DurationFraction multiply(DurationFraction other) {
    return DurationFraction(
      numerator * other.numerator,
      denominator * other.denominator,
    ).reduce();
  }

  /// Additionne cette fraction avec une autre.
  DurationFraction add(DurationFraction other) {
    final int commonDenominator = denominator * other.denominator;
    final int newNumerator =
        numerator * other.denominator + other.numerator * denominator;
    return DurationFraction(newNumerator, commonDenominator).reduce();
  }

  /// Soustrait une autre fraction de cette fraction.
  /// Retourne DurationFraction(0, 1) si le résultat serait négatif.
  DurationFraction subtract(DurationFraction other) {
    final int commonDenominator = denominator * other.denominator;
    final int newNumerator =
        numerator * other.denominator - other.numerator * denominator;
    // Si le résultat serait négatif, retourner zéro
    if (newNumerator < 0) {
      return const DurationFraction(0, 1);
    }
    return DurationFraction(newNumerator, commonDenominator).reduce();
  }

  /// Convertit la fraction en double (pour calculs optionnels).
  double toDouble() => numerator / denominator;

  /// Compare cette fraction avec une autre.
  /// Retourne un entier négatif si this < other, zéro si égales, positif si this > other.
  int compareTo(DurationFraction other) {
    // Comparer a/b et c/d en comparant a*d et c*b
    final thisValue = numerator * other.denominator;
    final otherValue = other.numerator * denominator;
    return thisValue.compareTo(otherValue);
  }

  /// Vérifie si cette fraction est strictement inférieure à une autre.
  bool operator <(DurationFraction other) => compareTo(other) < 0;

  /// Vérifie si cette fraction est strictement supérieure à une autre.
  bool operator >(DurationFraction other) => compareTo(other) > 0;

  /// Vérifie si cette fraction est inférieure ou égale à une autre.
  bool operator <=(DurationFraction other) => compareTo(other) <= 0;

  /// Vérifie si cette fraction est supérieure ou égale à une autre.
  bool operator >=(DurationFraction other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DurationFraction) return false;
    final DurationFraction reduced = reduce();
    final DurationFraction otherReduced = other.reduce();
    return reduced.numerator == otherReduced.numerator &&
        reduced.denominator == otherReduced.denominator;
  }

  @override
  int get hashCode {
    final DurationFraction reduced = reduce();
    return Object.hash(reduced.numerator, reduced.denominator);
  }

  @override
  String toString() => '$numerator/$denominator';

  Map<String, dynamic> toJson() => {
        'numerator': numerator,
        'denominator': denominator,
      };

  factory DurationFraction.fromJson(Map<String, dynamic> json) {
    return DurationFraction(
      json['numerator'] as int,
      json['denominator'] as int,
    );
  }

  // Constantes statiques pour les durées standard
  static const DurationFraction whole = DurationFraction(1, 1);
  static const DurationFraction half = DurationFraction(1, 2);
  static const DurationFraction quarter = DurationFraction(1, 4);
  static const DurationFraction eighth = DurationFraction(1, 8);
  static const DurationFraction sixteenth = DurationFraction(1, 16);
  static const DurationFraction thirtySecond = DurationFraction(1, 32);
}

