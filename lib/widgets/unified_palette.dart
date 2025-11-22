import 'package:flutter/material.dart';

import '../model/accent.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../utils/music_symbols.dart';
import 'symbol_palette.dart';

enum ModificationSymbol { accent, flam, drag, roll }

/// Palette unifiée qui affiche tous les symboles (SelectedSymbol et ModificationSymbol) dans une même barre.
class UnifiedPalette extends StatelessWidget {
  const UnifiedPalette({
    super.key,
    required this.selectedSymbol,
    required this.availableSymbols,
    required this.modificationSymbols,
    this.selectedEvent,
    required this.onSelectedSymbolSelected,
    required this.onModificationSymbolSelected,
  });

  final SelectedSymbol selectedSymbol;
  final List<PaletteSymbol<SelectedSymbol>> availableSymbols;
  final List<PaletteSymbol<ModificationSymbol>> modificationSymbols;
  final NoteEvent? selectedEvent;
  final ValueChanged<SelectedSymbol> onSelectedSymbolSelected;
  final ValueChanged<String> onModificationSymbolSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Vérifier si une note est sélectionnée
    final bool hasNoteSelected = selectedEvent != null;

    // Déterminer l'état actif des ModificationSymbols si une note est sélectionnée
    final bool hasAccent = selectedEvent?.accent == Accent.accent;
    final bool hasFlam = selectedEvent?.ornament == Ornament.flam;
    final bool hasDrag = selectedEvent?.ornament == Ornament.drag;
    final bool hasRoll = selectedEvent?.ornament == Ornament.roll;

    return Material(
      elevation: 4,
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              // Afficher d'abord les SelectedSymbols
              if (index < availableSymbols.length) {
                final PaletteSymbol<SelectedSymbol> option =
                    availableSymbols[index];
                final bool isSelected = option.id == selectedSymbol;
                return UnifiedPaletteButton(
                  option: option,
                  isActive: isSelected,
                  showStaffLine: true,
                  onTap: () => onSelectedSymbolSelected(option.id),
                );
              }

              // Ensuite les ModificationSymbols
              final modificationIndex = index - availableSymbols.length;
              if (modificationIndex < modificationSymbols.length) {
                final PaletteSymbol<ModificationSymbol> option =
                    modificationSymbols[modificationIndex];
                final bool isActive;

                // Déterminer si cet attribut est actif
                if (option.symbol == MusicSymbols.accent) {
                  isActive = hasAccent;
                } else if (option.symbol == MusicSymbols.flam) {
                  isActive = hasFlam;
                } else if (option.symbol == MusicSymbols.drag) {
                  isActive = hasDrag;
                } else if (option.symbol == MusicSymbols.roll) {
                  isActive = hasRoll;
                } else {
                  isActive = false;
                }

                return UnifiedPaletteButton(
                  option: option,
                  isActive: isActive,
                  showStaffLine: false,
                  isDisabled: !hasNoteSelected,
                  onTap: () => onModificationSymbolSelected(option.symbol),
                );
              }

              return const SizedBox.shrink();
            },
            separatorBuilder: (context, index) {
              // Ajouter un séparateur plus large entre les deux groupes de symboles
              // Le separatorBuilder reçoit l'index du séparateur (entre index et index+1)
              // Donc après le dernier SelectedSymbol (index = availableSymbols.length - 1)
              if (index == availableSymbols.length - 1) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 2,
                      height: 60,
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                  ],
                );
              }
              return const SizedBox(width: 12);
            },
            itemCount: availableSymbols.length + modificationSymbols.length,
          ),
        ),
      ),
    );
  }
}

/// Bouton de palette unifié qui peut afficher une ligne de portée ou non.
class UnifiedPaletteButton extends StatelessWidget {
  const UnifiedPaletteButton({
    super.key,
    required this.option,
    required this.isActive,
    required this.showStaffLine,
    required this.onTap,
    this.isDisabled = false,
  });

  final PaletteSymbol option;
  final bool isActive;
  final bool showStaffLine;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color borderColor = isDisabled
        ? colorScheme.outline.withOpacity(0.3)
        : (isActive
            ? colorScheme.primary
            : colorScheme.outline);
    final Color backgroundColor = isDisabled
        ? colorScheme.surface.withOpacity(0.5)
        : (isActive
            ? colorScheme.primaryContainer
            : colorScheme.surface);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              option.iconBuilder?.call(context, isActive) ??
                  (showStaffLine
                      ? SizedBox(
                          width: 64,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ligne de portée complètement dépassant le symbole
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 24,
                                height: 2,
                                child: Container(color: Colors.black),
                              ),
                              // Symbole de la note
                              Center(
                                child: Text(
                                  option.symbol,
                                  style: const TextStyle(
                                    fontFamily: 'Bravura',
                                    fontSize: 32,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          option.symbol,
                          style: TextStyle(
                            fontFamily: 'Bravura',
                            fontSize: 32,
                            color: isDisabled
                                ? Colors.grey
                                : (isActive ? colorScheme.primary : Colors.black),
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        )),
              const SizedBox(height: 4),
              Text(
                option.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDisabled
                      ? Colors.grey
                      : (isActive ? colorScheme.primary : null),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SelectedSymbol { right, left, rest, triplet }
