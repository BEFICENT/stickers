import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/dialogs/create_pack_dialog.dart';

void main() {
  testWidgets('returns a validated pack draft without mutating external state',
      (tester) async {
    StickerPack? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(
          body: FilledButton(
            onPressed: () async {
              result = await showDialog<StickerPack>(
                context: context,
                builder: (_) => const CreatePackDialog(),
              );
            },
            child: const Text('Open'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pack-title-field')),
      'Favorites',
    );
    await tester.enterText(
      find.byKey(const Key('pack-author-field')),
      'Tester',
    );
    await tester.tap(find.byKey(const Key('create-pack-confirm')));
    await tester.pumpAndSettle();

    expect(result?.title, 'Favorites');
    expect(result?.author, 'Tester');
    expect(result?.animated, isFalse);
    expect(result?.stickers, isEmpty);
  });

  testWidgets('does not close when required fields are empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: CreatePackDialog(),
    ));

    await tester.tap(find.byKey(const Key('create-pack-confirm')));
    await tester.pump();

    expect(find.byType(CreatePackDialog), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
