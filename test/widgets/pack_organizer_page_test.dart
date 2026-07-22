import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/pages/pack_organizer_page.dart';

void main() {
  testWidgets('sorts packs by name and returns the order on save',
      (tester) async {
    List<StickerPack>? result;
    final bravo = _pack('bravo', title: 'Bravo');
    final alpha = _pack('alpha', title: 'alpha');

    await tester.pumpWidget(_testApp(
      packs: [bravo, alpha],
      onResult: (value) => result = value,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-packs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (A-Z)'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('alpha')).dy,
      lessThan(tester.getTopLeft(find.text('Bravo')).dy),
    );

    await tester.tap(find.byKey(const Key('save-pack-order')));
    await tester.pumpAndSettle();
    expect(result, [same(alpha), same(bravo)]);
  });

  testWidgets('allows packs to be reordered with the drag handle',
      (tester) async {
    List<StickerPack>? result;
    final first = _pack('first', title: 'First');
    final second = _pack('second', title: 'Second');
    final third = _pack('third', title: 'Third');

    await tester.pumpWidget(_testApp(
      packs: [first, second, third],
      onResult: (value) => result = value,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('drag-pack-first')),
      const Offset(0, 220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-pack-order')));
    await tester.pumpAndSettle();

    expect(result, [same(second), same(first), same(third)]);
  });

  testWidgets('does not enable save before the order changes', (tester) async {
    await tester.pumpWidget(_testApp(
      packs: [_pack('first', title: 'First')],
      onResult: (_) {},
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<IconButton>(
      find.byKey(const Key('save-pack-order')),
    );
    expect(saveButton.onPressed, isNull);
  });
}

Widget _testApp({
  required List<StickerPack> packs,
  required ValueChanged<List<StickerPack>?> onResult,
}) {
  return MaterialApp(
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
            onResult(
              await Navigator.of(context).push<List<StickerPack>>(
                MaterialPageRoute(
                  builder: (_) => PackOrganizerPage(packs: packs),
                ),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

StickerPack _pack(String id, {required String title}) => StickerPack(
      title,
      'Author',
      id,
      const [],
      '1',
      false,
    );
