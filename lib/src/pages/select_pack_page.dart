import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/dialogs/create_pack_dialog.dart';
import 'package:stickers/src/dialogs/error_dialog.dart';
import 'package:stickers/src/globals.dart';
import 'package:stickers/src/media/media_probe.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/pages/crop_page.dart';
import 'package:stickers/src/pages/default_page.dart';
import 'package:stickers/src/pages/gif_crop_page.dart';
import 'package:stickers/src/pages/video_crop_page.dart';
import 'package:stickers/src/widgets/sticker_pack_preview_card.dart';

class SelectPackPage extends StatefulWidget {
  final MediaDescriptor media;

  const SelectPackPage(this.media, {super.key});

  static const routeName = "/selectPack";

  @override
  State<SelectPackPage> createState() => _SelectPackPageState();
}

class _SelectPackPageState extends State<SelectPackPage> {
  @override
  Widget build(BuildContext context) {
    final descriptor = widget.media;
    final isAnimated = descriptor.kind.isAnimated;
    return DefaultSliverActivity(
      fab: FloatingActionButton(
        heroTag: "select_pack_add_fab",
        onPressed: () async {
          final pack = await showDialog<StickerPack>(
            context: context,
            builder: (_) => CreatePackDialog(initialAnimated: isAnimated),
          );
          if (pack == null) return;
          try {
            await createPack(pack);
            if (mounted) setState(() {});
          } on Exception catch (error) {
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (_) => ErrorDialog(
                title: AppLocalizations.of(context)!.importError,
                message: error.toString(),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      title: AppLocalizations.of(context)!.selectStickerPack,
      child: ListView.separated(
        separatorBuilder: (context, index) => Container(),
        itemBuilder: (context, index) {
          bool disabled = packs[index].animated != isAnimated ||
              packs[index].stickers.length >= 30;
          debugPrint("disabled: $disabled");
          return Stack(
            children: [
// dart format off
              ColorFiltered(
                colorFilter: disabled
                    ? ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0
                      ])
                    : ColorFilter.matrix(<double>[
                        1,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0
                      ]),
                child: IgnorePointer(
                  child: StickerPackPreviewCard(packs[index], () {
                    setState(() {});
                  }),
                ),
              ),
// dart format on
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          final routeName = switch (descriptor.kind) {
                            SourceMediaKind.gif => GifCropPage.routeName,
                            SourceMediaKind.video => VideoCropPage.routeName,
                            _ => CropPage.routeName,
                          };
                          final mediaType = switch (descriptor.kind) {
                            SourceMediaKind.gif => MediaType.gif,
                            SourceMediaKind.video => MediaType.video,
                            _ => MediaType.picture,
                          };
                          Navigator.pushNamed(
                            context,
                            routeName,
                            arguments: EditArguments(
                              pack: packs[index],
                              index: packs[index].stickers.length,
                              mediaPath: descriptor.path,
                              type: mediaType,
                            ),
                          ).then(
                            (value) => setState(
                              () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushNamed("/");
                                Navigator.of(context).pushNamed("/pack",
                                    arguments: packs[index]);
                              },
                            ),
                          );
                        },
                ),
              ),
            ],
          );
        },
        itemCount: packs.length,
      ),
    );
  }
}
