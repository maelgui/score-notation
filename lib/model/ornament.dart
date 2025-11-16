/// Ornements de caisse claire écossaise.
enum Ornament {
  flam,
  drag,
  roll;

  /// Convertit l'ornement en JSON.
  String toJson() => name;

  /// Crée un ornement depuis JSON.
  static Ornament? fromJson(String? json) {
    if (json == null) return null;
    try {
      return Ornament.values.firstWhere((o) => o.name == json);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case Ornament.flam:
        return 'Flam';
      case Ornament.drag:
        return 'Drag';
      case Ornament.roll:
        return 'Roll';
    }
  }
}

