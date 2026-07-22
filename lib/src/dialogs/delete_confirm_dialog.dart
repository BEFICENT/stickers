import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';

class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog(this.target, {super.key}) : multiple = false;

  const DeleteConfirmDialog.multiple({super.key})
      : target = '',
        multiple = true;

  final String target;
  final bool multiple;

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.multiple
          ? localizations.deleteSelectedPacks
          : localizations.deletePack(widget.target)),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(localizations.cancel)),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.error,
                  onPrimary: Theme.of(context).colorScheme.onError,
                  primaryContainer:
                      Theme.of(context).colorScheme.errorContainer,
                  onPrimaryContainer:
                      Theme.of(context).colorScheme.onErrorContainer,
                ),
          ),
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(localizations.delete),
          ),
        )
      ],
    );
  }
}
