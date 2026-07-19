import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_handler/share_handler.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/dialogs/error_dialog.dart';
import 'package:stickers/src/globals.dart';
import 'package:stickers/src/pages/crop_page.dart';
import 'package:stickers/src/pages/edit_page.dart';
import 'package:stickers/src/pages/fonts_manager_page.dart';
import 'package:stickers/src/pages/gif_crop_page.dart';
import 'package:stickers/src/pages/select_pack_page.dart';
import 'package:stickers/src/pages/sticker_pack_page.dart';
import 'package:stickers/src/pages/sticker_packs_page.dart';
import 'package:stickers/src/pages/video_crop_page.dart';
import 'package:stickers/src/util.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_page.dart';

/// The Widget that configures your application.
class StickersApp extends StatefulWidget {
  static StickersAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<StickersAppState>();

  const StickersApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<StickersApp> createState() => StickersAppState();
}

class StickersAppState extends State<StickersApp> {
  late Locale _locale;
  StreamSubscription<SharedMedia>? _sharedMediaSubscription;

  @override
  void initState() {
    super.initState();
    _locale =
        Locale.fromSubtags(languageCode: widget.settingsController.locale);
    initPlatformState();
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  SharedMedia? media;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    final initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null) {
      debugPrint("Initial Media received");
      await _processMedia(initialMedia);
      if (mounted) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _openPendingMedia());
      }
    }
    _sharedMediaSubscription =
        handler.sharedMediaStream.listen((SharedMedia sharedMedia) async {
      if (!mounted) return;
      debugPrint("Media Stream received");
      await _processMedia(sharedMedia);
      if (mounted) _openPendingMedia();
    });
  }

  void _openPendingMedia() {
    final pendingMedia = media;
    final navigator = navigatorKey.currentState;
    if (!mounted || pendingMedia == null || navigator == null) return;
    media = null;
    navigator.pushNamedAndRemoveUntil(
      SelectPackPage.routeName,
      (route) => false,
      arguments: pendingMedia,
    );
  }

  @override
  void dispose() {
    _sharedMediaSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
            Locale('de', ''),
            Locale('fr', ''),
            Locale('ru', ''),
          ],
          locale: _locale,

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: widget.settingsController.themeMode,
          navigatorKey: navigatorKey,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SelectPackPage.routeName:
                    return SelectPackPage(
                      routeSettings.arguments as SharedMedia,
                    );
                  case FontsManagerPage.routeName:
                    return FontsManagerPage();
                  case SettingsPage.routeName:
                    return SettingsPage(controller: widget.settingsController);
                  case VideoCropPage.routeName:
                    final args = routeSettings.arguments as EditArguments;
                    return VideoCropPage(
                      pack: args.pack,
                      index: args.index,
                      imagePath: args.mediaPath,
                      batchQueue: args.batchQueue,
                    );
                  case GifCropPage.routeName:
                    final args = routeSettings.arguments as EditArguments;
                    return GifCropPage(
                      pack: args.pack,
                      index: args.index,
                      imagePath: args.mediaPath,
                      batchQueue: args.batchQueue,
                    );
                  case CropPage.routeName:
                    final args = routeSettings.arguments as EditArguments;
                    return CropPage(
                      pack: args.pack,
                      index: args.index,
                      imagePath: args.mediaPath,
                      batchQueue: args.batchQueue,
                    );
                  case EditPage.routeName:
                    final args = routeSettings.arguments as EditArguments;
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
                        routeSettings.arguments as StickerPack, () {
                      setState(() {});
                    });
                  case StickerPacksPage.routeName:
                  default:
                    return const StickerPacksPage();
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _processMedia(SharedMedia media) async {
    final attachments = media.attachments;
    final attachment = attachments?.whereType<SharedAttachment>().firstOrNull;
    if (attachment == null || attachment.path.isEmpty) {
      _showShareError(
        (context) => AppLocalizations.of(context)!.unrecognizedFormat,
      );
      return;
    }
    final lowerPath = attachment.path.toLowerCase();
    if (!await File(attachment.path).exists()) {
      _showShareError(
        (context) => AppLocalizations.of(context)!.couldntLoadMedia,
      );
      return;
    }
    if (lowerPath.endsWith(".stickify") ||
        lowerPath.endsWith(".zip") ||
        lowerPath.endsWith(".wastickers")) {
      try {
        await importPack(File(attachment.path));
        if (mounted) setState(() {});
      } on Exception catch (_) {
        if (mounted) {
          showDialog(
              context: navigatorKey.currentState!.context,
              builder: (context) => ErrorDialog(
                    message: AppLocalizations.of(context)!.checkIfFileValid,
                    title: AppLocalizations.of(context)!.importError,
                  ));
        }
      }
      return;
    }
    final isGif = attachment.path.toLowerCase().endsWith(".gif");
    if (attachment.type != SharedAttachmentType.image && !isGif) {
      if (mounted) {
        showDialog(
            context: navigatorKey.currentState!.context,
            builder: (context) => ErrorDialog(
                  message: AppLocalizations.of(context)!.unrecognizedFormat,
                  title: AppLocalizations.of(context)!.unrecognizedFormat,
                ));
      }
      return;
    }
    this.media = media;
    if (widget.settingsController.quickMode && !isGif) {
      await _quickAdd(media, widget.settingsController.defaultTitle,
          widget.settingsController.defaultAuthor);
      this.media = null;
    }
  }

  void _showShareError(String Function(BuildContext context) message) {
    final currentContext = navigatorKey.currentContext;
    if (!mounted || currentContext == null) return;
    showDialog(
      context: currentContext,
      builder: (context) => ErrorDialog(
        message: message(context),
        title: message(context),
      ),
    );
  }

  Future<void> _quickAdd(
      SharedMedia media, String defaultTitle, String defaultAuthor) async {
    final rawImageData = File(media.attachments!.first!.path).readAsBytesSync();
    final pack = packs.firstWhere(
        (pack) => pack.stickers.length < 30 && !pack.animated, orElse: () {
      final pack = StickerPack(
        defaultTitle,
        defaultAuthor,
        "pack_${DateTime.now().millisecondsSinceEpoch}",
        [],
        "0",
        false, // TODO add support for animated stickers in auto-generated
      );
      packs.add(pack);
      savePacks(packs);
      return pack;
    });
    final index = pack.stickers.length;
    final img = await decodeImageFromList(rawImageData);
    final cropRect =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final cropped = await cropSticker(cropRect, rawImageData, pack, index, 0);
    await addToPack(pack, index, cropped);

    navigatorKey.currentState?.pushNamed("/pack", arguments: pack);
    if (!mounted) return;
    await sendToWhatsappWithErrorHandling(pack, context);
  }
}
