import 'package:flutter/foundation.dart';

/// Métadonnées d'une partition pour l'affichage dans la liste.
@immutable
class ScoreMetadata {
  const ScoreMetadata({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    this.description,
  });

  /// Identifiant unique de la partition.
  final String id;

  /// Titre de la partition.
  final String title;

  /// Date de création.
  final DateTime createdAt;

  /// Date de dernière modification.
  final DateTime lastModified;

  /// Description optionnelle.
  final String? description;

  ScoreMetadata copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    String? description,
  }) {
    return ScoreMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScoreMetadata) return false;
    return id == other.id &&
           title == other.title &&
           createdAt == other.createdAt &&
           lastModified == other.lastModified &&
           description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, createdAt, lastModified, description);
  }

  @override
  String toString() {
    return 'ScoreMetadata(id: $id, title: $title, created: $createdAt)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'description': description,
      };

  factory ScoreMetadata.fromJson(Map<String, dynamic> json) {
    return ScoreMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      description: json['description'] as String?,
    );
  }
}
