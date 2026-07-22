import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/batch/batch_import_queue.dart';
import 'package:stickers/src/checker_painter.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/editor/crop_aspect_preset.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/pages/default_page.dart';

class CropPage extends StatefulWidget {
  final StickerPack pack;
  final int index;
  final String imagePath;
  final BatchImportQueue? batchQueue;
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  CropPage({
    required this.pack,
    required this.index,
    required this.imagePath,
    this.batchQueue,
    super.key,
  });

  static const routeName = "/crop";

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> with TickerProviderStateMixin {
  late final AnimationController _maskColorController;
  final ImageEditorController _editorController = ImageEditorController();

  bool _previousPtrVal = false;

  @override
  void initState() {
    super.initState();
    _maskColorController = AnimationController(vsync: this);
    Tween<double> tween = Tween(begin: 0.0, end: 1.0);
    Animation anim = CurvedAnimation(
        parent: _maskColorController,
        curve: Curves.ease,
        reverseCurve: Curves.ease);
    anim.drive(tween);
    _maskColorController.addListener(_animationListener);
    _editorController.addListener(_editorChanged);
  }

  void _animationListener() {
    if (mounted) setState(() {});
  }

  void _editorChanged() {
    if (mounted) setState(() {});
  }

  void _syncAspectPreset() {
    if (!mounted) return;
    setState(() {
      _aspectPreset = CropAspectPreset.fromRatio(
        _editorController.cropAspectRatio,
      );
    });
  }

  void _undo() {
    _editorController.undo();
    _syncAspectPreset();
  }

  void _redo() {
    _editorController.redo();
    _syncAspectPreset();
  }

  void _rotate(double degree) {
    _editorController.rotate(degree: degree, animation: true);
    _syncAspectPreset();
  }

  @override
  void dispose() {
    _maskColorController.removeListener(_animationListener);
    _maskColorController.dispose();
    _editorController.removeListener(_editorChanged);
    _editorController.dispose();
    super.dispose();
  }

  CropAspectPreset _aspectPreset = CropAspectPreset.free;

  @override
  Widget build(BuildContext context) {
    return DefaultActivity(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cropYourSticker),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          //TODO make loading less abrupt
          children: [
            Expanded(
              child: Container(
                // The clip and empty BoxDecoration is intentional, sometimes the done button doesn't appear otherwise
                // See: https://github.com/lolocomotive/stickers/issues/1
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: ExtendedImage.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  beforePaintImage: (canvas, rect, image, paint) {
                    CheckerPainter.checkerPainter(canvas, rect, context);
                    return false;
                  },
                  mode: ExtendedImageMode.editor,
                  extendedImageEditorKey: widget.editorKey,
                  cacheRawData: true,
                  initEditorConfigHandler: (state) {
                    return EditorConfig(
                      editorMaskColorHandler: (ctx, pointerDown) {
                        if (_previousPtrVal && !pointerDown) {
                          _maskColorController.animateTo(1,
                              duration: const Duration(milliseconds: 150));
                        }
                        if (!_previousPtrVal && pointerDown) {
                          _maskColorController.animateTo(0,
                              duration: const Duration(milliseconds: 150));
                        }
                        _previousPtrVal = pointerDown;
                        return Color.lerp(
                          Theme.of(context).colorScheme.surface.withAlpha(50),
                          Theme.of(context).colorScheme.surface.withAlpha(200),
                          _maskColorController.value,
                        )!;
                      },
                      animationCurve: Curves.ease,
                      tickerDuration: const Duration(milliseconds: 250),
                      autoCenterCropRect: false,
                      clampCropRectToImage: true,
                      lineHeight: 2,
                      lineColor:
                          Theme.of(context).colorScheme.primary.withAlpha(190),
                      animationDuration: const Duration(milliseconds: 250),
                      maxScale: 12,
                      cropRectPadding: const EdgeInsets.all(24),
                      hitTestSize: 28,
                      cropAspectRatio: _aspectPreset.ratio,
                      cornerColor: Theme.of(context).colorScheme.primary,
                      cornerSize: const Size(38, 6),
                      controller: _editorController,
                    );
                  },
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.undo,
                      onPressed: _editorController.canUndo ? _undo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.redo,
                      onPressed: _editorController.canRedo ? _redo : null,
                      icon: const Icon(Icons.redo),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.flipHorizontal,
                      onPressed: () => _editorController.flip(animation: true),
                      icon: const Icon(Icons.flip),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.rotateLeft,
                      onPressed: () => _rotate(-90),
                      icon: const Icon(Icons.rotate_left),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.rotateRight,
                      onPressed: () => _rotate(90),
                      icon: const Icon(Icons.rotate_right),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.resetCrop,
                      onPressed: () {
                        setState(() => _aspectPreset = CropAspectPreset.free);
                        _editorController.reset();
                      },
                      icon: const Icon(Icons.fit_screen),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<CropAspectPreset>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: CropAspectPreset.free,
                          icon: const Icon(Icons.crop_free),
                          label: Text(AppLocalizations.of(context)!.freeCrop),
                        ),
                        const ButtonSegment(
                          value: CropAspectPreset.landscapeWide,
                          icon: Icon(Icons.crop_16_9),
                          label: Text("16:9"),
                        ),
                        const ButtonSegment(
                          value: CropAspectPreset.landscape,
                          icon: Icon(Icons.crop_3_2),
                          label: Text("3:2"),
                        ),
                        const ButtonSegment(
                          value: CropAspectPreset.square,
                          icon: Icon(Icons.crop_din),
                          label: Text("1:1"),
                        ),
                        ButtonSegment(
                          value: CropAspectPreset.portrait,
                          icon: Transform.rotate(
                            angle: pi / 2,
                            child: const Icon(Icons.crop_3_2),
                          ),
                          label: const Text("2:3"),
                        ),
                        ButtonSegment(
                          value: CropAspectPreset.portraitTall,
                          icon: Transform.rotate(
                            angle: pi / 2,
                            child: const Icon(Icons.crop_16_9),
                          ),
                          label: const Text("9:16"),
                        ),
                      ],
                      selected: {_aspectPreset},
                      onSelectionChanged: (selection) {
                        final preset = selection.first;
                        _editorController.updateCropAspectRatio(preset.ratio);
                        setState(() => _aspectPreset = preset);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: FilledButton(
                        onPressed: () async {
                          final state = widget.editorKey.currentState!;
                          if (state.getCropRect()!.height < .5 ||
                              state.getCropRect()!.width < .5) {
                            showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                      title: Text(AppLocalizations.of(context)!
                                          .cropTooSmall),
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .cropTooSmallDetails),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text("Okay 💗")),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text("Yay 💗")),
                                      ],
                                    ));
                            return;
                          }
                          final cropped = await cropSticker(
                              state.getCropRect()!,
                              state.rawImageData,
                              widget.pack,
                              widget.index,
                              _editorController.rotateDegrees);
                          final output = await saveTemp(cropped);
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamed(
                            "/edit",
                            arguments: EditArguments(
                              pack: widget.pack,
                              index: widget.index,
                              mediaPath: output.path,
                              batchQueue: widget.batchQueue,
                            ),
                          );
                        },
                        child: Text(AppLocalizations.of(context)!.done),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
