import 'package:flutter/material.dart';

import '../utils/music_symbols.dart';

/// Small visual representation of rudiments using ghost notes
/// (e.g., flam: single grace note, drag: double grace note).
class RudimentIcon extends StatelessWidget {
  const RudimentIcon({
    super.key,
    required this.graceNoteCount,
    required this.isActive,
  }) : assert(graceNoteCount >= 1 && graceNoteCount <= 2);

  final int graceNoteCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color graceColor = (isActive ? colorScheme.primary : Colors.black87)
        .withOpacity(isActive ? 1.0 : 0.85);

    final double baseFontSize = graceNoteCount == 1 ? 28 : 24;
    final String graceSymbol = graceNoteCount == 1
        ? MusicSymbols.eighthNoteUp
        : MusicSymbols.sixteenthNoteUp;

    return SizedBox(
      width: graceNoteCount == 1 ? 56 : 72,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(graceNoteCount, (index) {
          final double horizontalShift = 4 + index * 16;
          final double verticalShift =
              6 + (graceNoteCount - index - 1) * 6.0; // léger escalier
          final double scale =
              graceNoteCount == 1 ? 0.9 : (0.85 - index * 0.08);

          return Positioned(
            left: horizontalShift,
            bottom: verticalShift,
            child: Transform.scale(
              scale: scale.clamp(0.65, 1.0),
              alignment: Alignment.bottomLeft,
              child: Text(
                graceSymbol,
                style: TextStyle(
                  fontFamily: 'Bravura',
                  fontSize: baseFontSize,
                  color: graceColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

