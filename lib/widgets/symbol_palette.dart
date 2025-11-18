import 'package:flutter/material.dart';

typedef PaletteIconBuilder = Widget Function(
  BuildContext context,
  bool isActive,
);

/// Représente un symbole affiché dans la palette.
class PaletteSymbol<T extends Enum> {
  const PaletteSymbol({
    required this.label,
    required this.symbol,
    required this.id,
    this.iconBuilder,
  });

  final String label;
  final String symbol;
  final T id;
  final PaletteIconBuilder? iconBuilder;
}

/// Palette horizontale affichant la liste des symboles musicaux disponibles.
class SymbolPalette<T extends Enum> extends StatelessWidget {
  const SymbolPalette({
    super.key,
    required this.symbols,
    required this.selectedSymbol,
    required this.onSymbolSelected,
  });

  final List<PaletteSymbol<T>> symbols;
  final T selectedSymbol;
  final ValueChanged<T> onSymbolSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
              final PaletteSymbol<T> option = symbols[index];
              final bool isSelected = option.id == selectedSymbol;
              return _PaletteButton(
                option: option,
                isSelected: isSelected,
                onTap: () => onSymbolSelected(option.id),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: symbols.length,
          ),
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final PaletteSymbol option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color borderColor =
        isSelected ? colorScheme.primary : colorScheme.outline;
    final Color backgroundColor =
        isSelected ? colorScheme.primaryContainer : colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            option.iconBuilder?.call(context, isSelected) ??
                SizedBox(
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
                        child: Container(
                          color: Colors.black,
                        ),
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
                ),
            const SizedBox(height: 4),
            Text(
              option.label,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

