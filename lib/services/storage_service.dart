import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/score.dart';

/// Gère la persistance locale de la partition en JSON.
///
/// Pour des besoins plus avancés, on pourra remplacer ce service par un
/// stockage SQLite, une API distante ou un format spécialisé (MusicXML, etc.).
class StorageService {
  static const String _fileName = 'snare_notation_score.json';

  Future<File> _scoreFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Charge la partition depuis le fichier JSON.
  /// Retourne une partition vide si le fichier n'existe pas ou est invalide.
  Future<Score> loadScore() async {
    final file = await _scoreFile();
    if (!await file.exists()) {
      return const Score(measures: []);
    }

    final content = await file.readAsString();
    if (content.isEmpty) {
      return const Score(measures: []);
    }

    try {
      final Map<String, dynamic> decoded = json.decode(content) as Map<String, dynamic>;
      return Score.fromJson(decoded);
    } catch (e) {
      // Si le format est invalide, retourner une partition vide
      return const Score(measures: []);
    }
  }

  /// Sauvegarde la partition dans le fichier JSON.
  Future<void> saveScore(Score score) async {
    final file = await _scoreFile();
    final encoded = json.encode(score.toJson());
    await file.writeAsString(encoded, flush: true);
  }

  /// Efface la partition sauvegardée.
  Future<void> clearScore() async {
    final file = await _scoreFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
