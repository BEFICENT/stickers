import 'package:flutter/material.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/media/media_probe.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/pages/crop_page.dart';
import 'package:stickers/src/pages/edit_page.dart';
import 'package:stickers/src/pages/fonts_manager_page.dart';
import 'package:stickers/src/pages/gif_crop_page.dart';
import 'package:stickers/src/pages/select_pack_page.dart';
import 'package:stickers/src/pages/sticker_pack_page.dart';
import 'package:stickers/src/pages/sticker_packs_page.dart';
import 'package:stickers/src/pages/video_crop_page.dart';
import 'package:stickers/src/settings/settings_controller.dart';
import 'package:stickers/src/settings/settings_page.dart';

class AppRouter {
  final SettingsController settingsController;
  final VoidCallback onPackChanged;

  const AppRouter({
    required this.settingsController,
    required this.onPackChanged,
  });

  Route<dynamic> generate(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _pageFor(settings),
    );
  }

  Widget _pageFor(RouteSettings settings) {
    switch (settings.name) {
      case SelectPackPage.routeName:
        return SelectPackPage(_arguments<MediaDescriptor>(settings));
      case FontsManagerPage.routeName:
        return FontsManagerPage();
      case SettingsPage.routeName:
        return SettingsPage(controller: settingsController);
      case VideoCropPage.routeName:
        final args = _arguments<EditArguments>(settings);
        return VideoCropPage(
          pack: args.pack,
          index: args.index,
          imagePath: args.mediaPath,
          batchQueue: args.batchQueue,
        );
      case GifCropPage.routeName:
        final args = _arguments<EditArguments>(settings);
        return GifCropPage(
          pack: args.pack,
          index: args.index,
          imagePath: args.mediaPath,
          batchQueue: args.batchQueue,
        );
      case CropPage.routeName:
        final args = _arguments<EditArguments>(settings);
        return CropPage(
          pack: args.pack,
          index: args.index,
          imagePath: args.mediaPath,
          batchQueue: args.batchQueue,
        );
      case EditPage.routeName:
        final args = _arguments<EditArguments>(settings);
        return EditPage(
          args.pack,
          args.index,
          args.mediaPath,
          args.type,
          trimStart: args.trimStart,
          trimEnd: args.trimEnd,
          batchQueue: args.batchQueue,
        );
      case StickerPackPage.routeName:
        return StickerPackPage(
          _arguments<StickerPack>(settings),
          onPackChanged,
        );
      case StickerPacksPage.routeName:
      default:
        return const StickerPacksPage();
    }
  }

  T _arguments<T>(RouteSettings settings) {
    final arguments = settings.arguments;
    if (arguments is T) return arguments;
    throw FlutterError(
      'Route ${settings.name} requires arguments of type $T, '
      'but received ${arguments.runtimeType}.',
    );
  }
}
