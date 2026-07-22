import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/editor/crop_aspect_preset.dart';
import 'package:stickers/src/pages/crop_page.dart';

void main() {
  testWidgets('uses precise crop targets and exposes recovery controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final imageFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}crop_page_test.png',
    );
    await imageFile.writeAsBytes(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ));
    addTearDown(() async {
      if (await imageFile.exists()) await imageFile.delete();
    });

    final page = CropPage(
      pack: StickerPack('Test', 'Tester', 'test', [], '1', false),
      index: 0,
      imagePath: imageFile.path,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ExtendedImage), findsOneWidget);
    expect(find.byType(ExtendedImageEditor), findsOneWidget);
    final config = page.editorKey.currentState!.config;
    expect(config.hitTestSize, 28);
    expect(config.cropRectPadding, const EdgeInsets.all(24));
    expect(config.cornerSize, const Size(38, 6));
    expect(config.maxScale, 12);
    expect(config.autoCenterCropRect, isFalse);
    expect(config.clampCropRectToImage, isTrue);

    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.redo), findsOneWidget);
    expect(find.byIcon(Icons.flip), findsOneWidget);
    expect(find.byIcon(Icons.rotate_left), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    expect(find.byIcon(Icons.fit_screen), findsOneWidget);

    var selector = tester.widget<SegmentedButton<CropAspectPreset>>(
      find.byType(SegmentedButton<CropAspectPreset>),
    );
    expect(selector.selected, {CropAspectPreset.free});

    await tester.tap(find.text('1:1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    selector = tester.widget<SegmentedButton<CropAspectPreset>>(
      find.byType(SegmentedButton<CropAspectPreset>),
    );
    expect(selector.selected, {CropAspectPreset.square});

    final editorOrigin = tester.getTopLeft(find.byType(ExtendedImageEditor));
    final initialCrop = page.editorKey.currentState!.editAction!.cropRect!;
    await tester.dragFrom(
      editorOrigin + initialCrop.bottomCenter,
      const Offset(0, -50),
    );
    await tester.pump();
    final shrunkCrop = page.editorKey.currentState!.editAction!.cropRect!;
    expect(shrunkCrop.width, lessThan(initialCrop.width));

    final overdrag = await tester.startGesture(
      editorOrigin + shrunkCrop.bottomCenter,
    );
    await overdrag.moveBy(const Offset(0, 400));
    await tester.pump();
    final boundaryCrop = page.editorKey.currentState!.editAction!.cropRect!;
    await overdrag.moveBy(const Offset(0, 200));
    await tester.pump();
    final overdraggedCrop = page.editorKey.currentState!.editAction!.cropRect!;
    await overdrag.up();

    expect(overdraggedCrop.left, closeTo(boundaryCrop.left, 0.01));
    expect(overdraggedCrop.right, closeTo(boundaryCrop.right, 0.01));
    expect(overdraggedCrop.top, closeTo(boundaryCrop.top, 0.01));
    expect(overdraggedCrop.bottom, closeTo(boundaryCrop.bottom, 0.01));
    expect(tester.takeException(), isNull);
  });
}
