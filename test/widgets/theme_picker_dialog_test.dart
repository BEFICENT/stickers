import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/dialogs/theme_picker_dialog.dart';
import 'package:stickers/src/theme/app_themes.dart';

void main() {
  testWidgets('shows every preset and returns the selected theme',
      (tester) async {
    AppThemePreset? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppThemes.canvas,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              result = await showDialog<AppThemePreset>(
                context: context,
                builder: (_) => const ThemePickerDialog(
                  selected: AppThemePreset.canvas,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    for (final preset in AppThemePreset.values) {
      expect(find.byKey(Key('theme-${preset.name}')), findsOneWidget);
    }
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final mintSwatch = find.descendant(
      of: find.byKey(const Key('theme-oledMint')),
      matching: find.byType(ColoredBox),
    ).first;
    expect(tester.getSize(mintSwatch).height, greaterThan(20));

    await tester.tap(find.byKey(const Key('theme-oledMint')));
    await tester.pumpAndSettle();
    expect(result, AppThemePreset.oledMint);
  });
}
