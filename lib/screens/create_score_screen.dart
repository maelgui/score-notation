import 'package:flutter/material.dart';

import '../model/score.dart';
import '../model/score_metadata.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'staff_screen.dart';

/// Page de création d'une nouvelle partition avec métadonnées.
class CreateScoreScreen extends StatefulWidget {
  const CreateScoreScreen({super.key});

  @override
  State<CreateScoreScreen> createState() => _CreateScoreScreenState();
}

class _CreateScoreScreenState extends State<CreateScoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final StorageService _storageService = StorageService();

  int _measureCount = 4;
  int _measuresPerLine = 4;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createScore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Générer un ID unique pour la nouvelle partition
      final scoreId = _storageService.generateScoreId();
      final now = DateTime.now();

      // Créer les métadonnées
      final metadata = ScoreMetadata(
        id: scoreId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: now,
        lastModified: now,
      );

      // Créer une partition vide avec le nombre de mesures spécifié
      final score = Score.defaultScore(
        measureCount: _measureCount,
        measuresPerLine: _measuresPerLine,
      );

      // Sauvegarder la partition et ses métadonnées
      await _storageService.saveScore(scoreId, score, metadata);

      if (mounted) {
        // Naviguer vers l'éditeur de partition avec l'ID de la partition
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => StaffScreen(scoreId: scoreId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Partition'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createScore,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la partition',
                hintText: 'Ex: Marche militaire, Rythme de base...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Le titre doit contenir au moins 2 caractères';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ajoutez une description de votre partition...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 24),

            // Configuration de la partition
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Nombre de mesures
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nombre de mesures: $_measureCount',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: _measureCount > AppConstants.minBarCount
                              ? () => setState(() => _measureCount--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          onPressed: _measureCount < AppConstants.maxBarCount
                              ? () => setState(() => _measureCount++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    Slider(
                      value: _measureCount.toDouble(),
                      min: AppConstants.minBarCount.toDouble(),
                      max: AppConstants.maxBarCount.toDouble(),
                      divisions:
                          AppConstants.maxBarCount - AppConstants.minBarCount,
                      onChanged: (value) {
                        setState(() {
                          _measureCount = value.round();
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mesures par ligne
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mesures par ligne: $_measuresPerLine',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: _measuresPerLine > 1
                              ? () => setState(() => _measuresPerLine--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          onPressed: _measuresPerLine < 8
                              ? () => setState(() => _measuresPerLine++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    Slider(
                      value: _measuresPerLine.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      onChanged: (value) {
                        setState(() {
                          _measuresPerLine = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations supplémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Information',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous pourrez modifier ces paramètres plus tard dans l\'éditeur de partition.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
