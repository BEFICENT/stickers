import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/theme/app_themes.dart';

String themePresetLabel(
  AppLocalizations localizations,
  AppThemePreset preset,
) =>
    switch (preset) {
      AppThemePreset.system => localizations.system,
      AppThemePreset.canvas => localizations.themeCanvas,
      AppThemePreset.carbon => localizations.themeCarbon,
      AppThemePreset.oledMint => localizations.themeOledMint,
      AppThemePreset.oledEmber => localizations.themeOledEmber,
    };

class ThemePickerDialog extends StatelessWidget {
  final AppThemePreset selected;

  const ThemePickerDialog({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.theme),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      content: SizedBox(
        width: 420,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppThemePreset.values.length,
          itemBuilder: (context, index) {
            final preset = AppThemePreset.values[index];
            final isSelected = preset == selected;
            return ListTile(
              key: Key('theme-${preset.name}'),
              selected: isSelected,
              onTap: () => Navigator.of(context).pop(preset),
              leading: _ThemeSwatches(colors: AppThemes.swatches(preset)),
              title: Text(themePresetLabel(localizations, preset)),
              trailing: SizedBox.square(
                dimension: 32,
                child: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
      ],
    );
  }
}

class _ThemeSwatches extends StatelessWidget {
  final List<Color> colors;

  const _ThemeSwatches({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: colors
            .map((color) => Expanded(child: ColoredBox(color: color)))
            .toList(growable: false),
      ),
    );
  }
}
