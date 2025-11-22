import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/score.dart';
import '../model/score_metadata.dart';

/// Gère la persistance locale des partitions en JSON.
///
/// Pour des besoins plus avancés, on pourra remplacer ce service par un
/// stockage SQLite, une API distante ou un format spécialisé (MusicXML, etc.).
class StorageService {
  static const String _metadataFileName = 'scores_metadata.json';
  static const String _scoresDirectoryName = 'scores';

  Future<Directory> _scoresDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final scoresDir = Directory('${directory.path}/$_scoresDirectoryName');
    if (!await scoresDir.exists()) {
      await scoresDir.create(recursive: true);
    }
    return scoresDir;
  }

  Future<File> _metadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_metadataFileName');
  }

  Future<File> _scoreFile(String scoreId) async {
    final scoresDir = await _scoresDirectory();
    return File('${scoresDir.path}/$scoreId.json');
  }

  /// Charge toutes les métadonnées des partitions.
  Future<List<ScoreMetadata>> loadScoresMetadata() async {
    final file = await _metadataFile();
    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    if (content.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(content) as List<dynamic>;
      return decoded
          .map((item) => ScoreMetadata.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde les métadonnées des partitions.
  Future<void> _saveScoresMetadata(List<ScoreMetadata> metadata) async {
    final file = await _metadataFile();
    final encoded = json.encode(metadata.map((m) => m.toJson()).toList());
    await file.writeAsString(encoded, flush: true);
  }

  /// Charge une partition spécifique par son ID.
  Future<Score?> loadScore(String scoreId) async {
    final file = await _scoreFile(scoreId);
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded = json.decode(content) as Map<String, dynamic>;
      return Score.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde une partition avec ses métadonnées.
  Future<void> saveScore(String scoreId, Score score, ScoreMetadata metadata) async {
    // Sauvegarder la partition
    final scoreFile = await _scoreFile(scoreId);
    final encoded = json.encode(score.toJson());
    await scoreFile.writeAsString(encoded, flush: true);

    // Mettre à jour les métadonnées
    final allMetadata = await loadScoresMetadata();
    final existingIndex = allMetadata.indexWhere((m) => m.id == scoreId);

    if (existingIndex >= 0) {
      allMetadata[existingIndex] = metadata;
    } else {
      allMetadata.add(metadata);
    }

    await _saveScoresMetadata(allMetadata);
  }

  /// Supprime une partition et ses métadonnées.
  Future<void> deleteScore(String scoreId) async {
    // Supprimer le fichier de partition
    final scoreFile = await _scoreFile(scoreId);
    if (await scoreFile.exists()) {
      await scoreFile.delete();
    }

    // Mettre à jour les métadonnées
    final allMetadata = await loadScoresMetadata();
    allMetadata.removeWhere((m) => m.id == scoreId);
    await _saveScoresMetadata(allMetadata);
  }

  /// Génère un nouvel ID unique pour une partition.
  String generateScoreId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

}
