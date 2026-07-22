import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';

enum PackManagementAction { export, addToWhatsapp, delete }

class PackManagementRequest {
  final PackManagementAction action;
  final List<StickerPack> packs;

  const PackManagementRequest({required this.action, required this.packs});
}

class ManagePacksDialog extends StatefulWidget {
  final List<StickerPack> packs;

  const ManagePacksDialog({super.key, required this.packs});

  @override
  State<ManagePacksDialog> createState() => _ManagePacksDialogState();
}

class _ManagePacksDialogState extends State<ManagePacksDialog> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.packs.map((pack) => pack.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final allSelected = _selectedIds.length == widget.packs.length;
    final noneSelected = _selectedIds.isEmpty;
    final whatsappEligible = !noneSelected &&
        _selectedPacks.every((pack) => pack.stickers.length >= 3);

    return AlertDialog(
      title: Text(localizations.managePacks),
      content: SizedBox(
        width: 460,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                key: const Key('select-all-packs'),
                value: allSelected
                    ? true
                    : noneSelected
                        ? false
                        : null,
                tristate: true,
                onChanged: (_) {
                  setState(() {
                    if (allSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(widget.packs.map((pack) => pack.id));
                    }
                  });
                },
                title: Text(localizations.selectAll),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.packs.length,
                  itemBuilder: (context, index) {
                    final pack = widget.packs[index];
                    final packType = pack.animated
                        ? localizations.animatedPack
                        : localizations.staticPack;
                    final needsMoreStickers = pack.stickers.length < 3;
                    return CheckboxListTile(
                      key: Key('manage-pack-${pack.id}'),
                      value: _selectedIds.contains(pack.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIds.add(pack.id);
                          } else {
                            _selectedIds.remove(pack.id);
                          }
                        });
                      },
                      title: Text(pack.title),
                      subtitle: Text(
                        '${pack.author}\n$packType - ${pack.stickers.length}/30'
                        '${needsMoreStickers ? '\n${localizations.youNeedAtLeast3Stickers}' : ''}',
                      ),
                      isThreeLine: needsMoreStickers,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        Tooltip(
          message: localizations.delete,
          child: IconButton(
            key: const Key('delete-selected-packs'),
            onPressed: noneSelected
                ? null
                : () => _complete(PackManagementAction.delete),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        Tooltip(
          message: localizations.export,
          child: IconButton.filledTonal(
            key: const Key('export-selected-packs'),
            onPressed: noneSelected
                ? null
                : () => _complete(PackManagementAction.export),
            icon: const Icon(Icons.ios_share),
          ),
        ),
        Tooltip(
          message: localizations.addToWhatsapp,
          child: IconButton.filled(
            key: const Key('whatsapp-selected-packs'),
            onPressed: whatsappEligible
                ? () => _complete(PackManagementAction.addToWhatsapp)
                : null,
            icon: const Icon(Icons.playlist_add),
          ),
        ),
      ],
    );
  }

  List<StickerPack> get _selectedPacks => widget.packs
      .where((pack) => _selectedIds.contains(pack.id))
      .toList(growable: false);

  void _complete(PackManagementAction action) {
    Navigator.of(context).pop(
      PackManagementRequest(action: action, packs: _selectedPacks),
    );
  }
}
