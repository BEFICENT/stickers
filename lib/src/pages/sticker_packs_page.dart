import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/constants.dart';
import 'package:stickers/src/data/load_store.dart';
import 'package:stickers/src/data/pack_batch_import.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/dialogs/create_pack_dialog.dart';
import 'package:stickers/src/dialogs/delete_confirm_dialog.dart';
import 'package:stickers/src/dialogs/edit_pack_dialog.dart';
import 'package:stickers/src/dialogs/error_dialog.dart';
import 'package:stickers/src/dialogs/manage_packs_dialog.dart';
import 'package:stickers/src/dialogs/whatsapp_pack_batch_progress_dialog.dart';
import 'package:stickers/src/globals.dart';
import 'package:stickers/src/integrations/whatsapp_pack_batch_service.dart';
import 'package:stickers/src/pages/default_page.dart';
import 'package:stickers/src/pages/pack_organizer_page.dart';
import 'package:stickers/src/util.dart';
import 'package:stickers/src/widgets/sticker_pack_preview_card.dart';

class StickerPacksPage extends StatefulWidget {
  const StickerPacksPage({super.key});

  static const routeName = "/";

  @override
  State<StickerPacksPage> createState() => StickerPacksPageState();
}

class StickerPacksPageState extends State<StickerPacksPage> {
  @override
  initState() {
    super.initState();
    packs.addListener(update);
  }

  void update() {
    if (!mounted) return;
    // We don't necessarily need to await savePacks here if it was already called elsewhere,
    // but we should ensure the UI reflects the current state of 'packs'.
    setState(() {});
  }

  @override
  void dispose() {
    packs.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      actions: [
        IconButton(
          key: const Key('organize-packs'),
          tooltip: AppLocalizations.of(context)!.organizePacks,
          onPressed: packs.isEmpty
              ? null
              : () => _organizePacks(packs.toList(growable: false)),
          icon: const Icon(Icons.reorder),
        ),
        IconButton(
          key: const Key('manage-packs'),
          tooltip: AppLocalizations.of(context)!.managePacks,
          onPressed: packs.isEmpty ? null : _managePacks,
          icon: const Icon(Icons.checklist),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.settings,
          onPressed: () {
            Navigator.of(context).pushNamed("/settings");
          },
          icon: const Icon(Icons.settings),
        )
      ],
      fab: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "import_fab",
            tooltip: AppLocalizations.of(context)!.import,
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: true,
                  dialogTitle: AppLocalizations.of(context)!.selectPack);
              if (result == null) return;
              final files = result.files
                  .where((file) => file.path != null)
                  .map((file) => File(file.path!));
              final importResult = await importPackBatch(files);
              if (mounted) setState(() {});
              for (final pack in importResult.packsMissingMetadata) {
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (_) => EditPackDialog(pack),
                );
              }
              for (final failure in importResult.failures) {
                debugPrint(failure.error.toString());
                debugPrintStack(stackTrace: failure.stackTrace);
              }
              if (importResult.failures.isNotEmpty && context.mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => ErrorDialog(
                    title: AppLocalizations.of(context)!.couldntImportPack,
                    message: AppLocalizations.of(context)!.checkPack,
                  ),
                );
              }
            },
            mini: true,
            child: const Icon(Icons.upload_file),
          ),
          SizedBox(
            width: 8,
          ),
          FloatingActionButton.extended(
            key: const Key('create-pack-button'),
            heroTag: "create_fab",
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              final pack = await showDialog<StickerPack>(
                context: context,
                builder: (_) => const CreatePackDialog(),
              );
              if (pack == null) return;
              try {
                await createPack(pack);
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
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(
              AppLocalizations.of(context)!.createPack,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      title: AppLocalizations.of(context)?.pTitle ?? localizationUnavailable,
      child: packs.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(8, 36, 8, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noPacks,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Opacity(
                    opacity: .8,
                    child: Text(
                      AppLocalizations.of(context)!
                          .clickOnTheBottomRightToAddAStickerPack,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox.shrink(),
                itemBuilder: (context, index) =>
                    StickerPackPreviewCard(packs[index], () {
                  setState(() {});
                }),
                itemCount: packs.length,
              ),
            ),
    );
  }

  Future<void> _managePacks() async {
    final request = await showDialog<PackManagementRequest>(
      context: context,
      builder: (_) => ManagePacksDialog(
        packs: packs.toList(growable: false),
      ),
    );
    if (!mounted || request == null || request.packs.isEmpty) return;

    switch (request.action) {
      case PackManagementAction.export:
        await _exportPacks(request.packs);
        return;
      case PackManagementAction.addToWhatsapp:
        await _addPacksToWhatsapp(request.packs);
        return;
      case PackManagementAction.delete:
        await _deletePacks(request.packs);
        return;
    }
  }

  Future<void> _organizePacks(List<StickerPack> currentOrder) async {
    final orderedPacks = await Navigator.of(context).push<List<StickerPack>>(
      MaterialPageRoute(
        builder: (_) => PackOrganizerPage(packs: currentOrder),
      ),
    );
    if (!mounted || orderedPacks == null) return;
    try {
      await reorderPacks(orderedPacks);
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not save pack order: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorDialog(
          title: AppLocalizations.of(context)!.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _exportPacks(List<StickerPack> selected) async {
    try {
      await exportPacks(selected);
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not export packs: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorDialog(
          title: AppLocalizations.of(context)!.couldntExportPacks,
          message: AppLocalizations.of(context)!.checkPacksForExport,
        ),
      );
    }
  }

  Future<void> _deletePacks(List<StickerPack> selected) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteConfirmDialog.multiple(),
    );
    if (confirmed != true) return;
    try {
      await deletePacks(selected);
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not delete packs: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorDialog(
          title: AppLocalizations.of(context)!.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _addPacksToWhatsapp(List<StickerPack> selected) async {
    final result = await showDialog<WhatsappPackBatchResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhatsappPackBatchProgressDialog(
        packs: selected,
        service: WhatsappPackBatchService(
          sender: createWhatsappPackService().send,
        ),
      ),
    );
    if (!mounted || result == null) return;

    for (final failure in result.failures) {
      debugPrint('Could not add ${failure.pack.title}: ${failure.error}');
      debugPrintStack(stackTrace: failure.stackTrace);
    }
    if (result.failures.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorDialog(
          title: AppLocalizations.of(context)!.couldnTAddStickerPack,
          message: result.failures
              .map((failure) => '${failure.pack.title}: ${failure.error}')
              .join('\n'),
        ),
      );
    }
  }
}
