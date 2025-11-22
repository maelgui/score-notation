import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SnareNotationApp());
}

class SnareNotationApp extends StatelessWidget {
  const SnareNotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snare Notation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// FUTURE EXTENSIONS:
// - Ajouter des gestes avancés (glisser-déposer, sélection multiple, undo/redo).
// - Export PNG/PDF du canvas (voir CustomPainter.toImage et packages comme printing).
// - Playback MIDI ou synthèse audio pour pré-écouter la séquence.
// - Édition de la signature rythmique par barre.
