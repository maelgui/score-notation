/// Accents et articulations pour les notes de caisse claire.
enum Accent {
  accent,
  staccato,
  marcato,
  tenuto;

  /// Convertit l'accent en JSON.
  String toJson() => name;

  /// Crée un accent depuis JSON.
  static Accent? fromJson(String? json) {
    if (json == null) return null;
    try {
      return Accent.values.firstWhere((a) => a.name == json);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case Accent.accent:
        return 'Accent';
      case Accent.staccato:
        return 'Staccato';
      case Accent.marcato:
        return 'Marcato';
      case Accent.tenuto:
        return 'Tenuto';
    }
  }
}

