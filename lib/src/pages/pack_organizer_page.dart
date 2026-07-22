import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/pages/default_page.dart';

enum PackSortOrder {
  nameAscending,
  nameDescending,
  author,
  staticFirst,
  animatedFirst,
}

class PackOrganizerPage extends StatefulWidget {
  final List<StickerPack> packs;

  const PackOrganizerPage({super.key, required this.packs});

  @override
  State<PackOrganizerPage> createState() => _PackOrganizerPageState();
}

class _PackOrganizerPageState extends State<PackOrganizerPage> {
  late final List<StickerPack> _originalOrder;
  late final List<StickerPack> _orderedPacks;

  @override
  void initState() {
    super.initState();
    _originalOrder = widget.packs.toList(growable: false);
    _orderedPacks = widget.packs.toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DefaultActivity(
      appBar: AppBar(
        title: Text(localizations.organizePacks),
        actions: [
          PopupMenuButton<PackSortOrder>(
            key: const Key('sort-packs'),
            tooltip: localizations.sortPacks,
            icon: const Icon(Icons.sort),
            onSelected: _sort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: PackSortOrder.nameAscending,
                child: Text(localizations.sortByNameAscending),
              ),
              PopupMenuItem(
                value: PackSortOrder.nameDescending,
                child: Text(localizations.sortByNameDescending),
              ),
              PopupMenuItem(
                value: PackSortOrder.author,
                child: Text(localizations.sortByAuthor),
              ),
              PopupMenuItem(
                value: PackSortOrder.staticFirst,
                child: Text(localizations.sortStaticFirst),
              ),
              PopupMenuItem(
                value: PackSortOrder.animatedFirst,
                child: Text(localizations.sortAnimatedFirst),
              ),
            ],
          ),
          IconButton(
            key: const Key('save-pack-order'),
            tooltip: localizations.saveOrder,
            onPressed: _hasChanges
                ? () => Navigator.of(context).pop(
                      List<StickerPack>.unmodifiable(_orderedPacks),
                    )
                : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        buildDefaultDragHandles: false,
        itemCount: _orderedPacks.length,
        onReorder: _reorder,
        itemBuilder: (context, index) {
          final pack = _orderedPacks[index];
          return Card(
            key: ValueKey(pack.id),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              leading: _PackThumbnail(pack: pack),
              title: Text(
                pack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${pack.author}\n'
                '${pack.animated ? localizations.animatedPack : localizations.staticPack}'
                ' - ${pack.stickers.length}/30',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: ReorderableDragStartListener(
                key: Key('drag-pack-${pack.id}'),
                index: index,
                child: Tooltip(
                  message: localizations.reorder,
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _hasChanges {
    for (var index = 0; index < _originalOrder.length; index++) {
      if (!identical(_originalOrder[index], _orderedPacks[index])) return true;
    }
    return false;
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final pack = _orderedPacks.removeAt(oldIndex);
      _orderedPacks.insert(newIndex, pack);
    });
  }

  void _sort(PackSortOrder order) {
    final indexedPacks = _orderedPacks.indexed.toList();
    indexedPacks.sort((left, right) {
      final result = _comparePacks(left.$2, right.$2, order);
      return result == 0 ? left.$1.compareTo(right.$1) : result;
    });
    setState(() {
      _orderedPacks
        ..clear()
        ..addAll(indexedPacks.map((entry) => entry.$2));
    });
  }

  int _comparePacks(
    StickerPack left,
    StickerPack right,
    PackSortOrder order,
  ) {
    final titleComparison = _compareText(left.title, right.title);
    final authorComparison = _compareText(left.author, right.author);
    switch (order) {
      case PackSortOrder.nameAscending:
        return titleComparison != 0 ? titleComparison : authorComparison;
      case PackSortOrder.nameDescending:
        return titleComparison != 0 ? -titleComparison : authorComparison;
      case PackSortOrder.author:
        return authorComparison != 0 ? authorComparison : titleComparison;
      case PackSortOrder.staticFirst:
        final typeComparison = _compareBool(left.animated, right.animated);
        return typeComparison != 0 ? typeComparison : titleComparison;
      case PackSortOrder.animatedFirst:
        final typeComparison = _compareBool(right.animated, left.animated);
        return typeComparison != 0 ? typeComparison : titleComparison;
    }
  }

  int _compareText(String left, String right) =>
      left.toLowerCase().compareTo(right.toLowerCase());

  int _compareBool(bool left, bool right) {
    if (left == right) return 0;
    return left ? 1 : -1;
  }
}

class _PackThumbnail extends StatelessWidget {
  final StickerPack pack;

  const _PackThumbnail({required this.pack});

  @override
  Widget build(BuildContext context) {
    final source = pack.trayIcon ??
        (pack.stickers.isEmpty ? null : pack.stickers.first.source);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: source == null
          ? const Icon(Icons.inventory_2_outlined)
          : Image.file(
              File(source),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
    );
  }
}
