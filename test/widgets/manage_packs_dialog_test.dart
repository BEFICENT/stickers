import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/dialogs/manage_packs_dialog.dart';

void main() {
  testWidgets('exports every pack selected by default', (tester) async {
    PackManagementRequest? result;
    final first = _pack('first', 3);
    final second = _pack('second', 2);

    await tester.pumpWidget(_testApp(
      onResult: (value) => result = value,
      packs: [first, second],
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export-selected-packs')));
    await tester.pumpAndSettle();

    expect(result?.action, PackManagementAction.export);
    expect(result?.packs, [same(first), same(second)]);
  });

  testWidgets('requires incomplete packs to be deselected for WhatsApp',
      (tester) async {
    PackManagementRequest? result;
    final eligible = _pack('eligible', 3);
    final incomplete = _pack('incomplete', 2);

    await tester.pumpWidget(_testApp(
      onResult: (value) => result = value,
      packs: [eligible, incomplete],
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final whatsappButton = find.byKey(const Key('whatsapp-selected-packs'));
    expect(tester.widget<IconButton>(whatsappButton).onPressed, isNull);

    await tester.tap(find.byKey(const Key('manage-pack-incomplete')));
    await tester.pump();
    expect(tester.widget<IconButton>(whatsappButton).onPressed, isNotNull);
    await tester.tap(whatsappButton);
    await tester.pumpAndSettle();

    expect(result?.action, PackManagementAction.addToWhatsapp);
    expect(result?.packs, [same(eligible)]);
  });

  testWidgets('select all toggles the complete selection', (tester) async {
    final first = _pack('first', 3);
    final second = _pack('second', 3);

    await tester.pumpWidget(_testApp(
      onResult: (_) {},
      packs: [first, second],
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-all-packs')));
    await tester.pump();

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('export-selected-packs')),
          )
          .onPressed,
      isNull,
    );
  });
}

Widget _testApp({
  required ValueChanged<PackManagementRequest?> onResult,
  required List<StickerPack> packs,
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
            onResult(await showDialog<PackManagementRequest>(
              context: context,
              builder: (_) => ManagePacksDialog(packs: packs),
            ));
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

StickerPack _pack(String id, int stickerCount) => StickerPack(
      id,
      'author',
      id,
      List.generate(stickerCount, (index) => Sticker('$id-$index.webp', [])),
      '1',
      false,
    );
