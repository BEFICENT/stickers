import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final String title;

  const ErrorDialog({super.key, required this.message, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(
            primary: colorScheme.error,
            onPrimary: colorScheme.onError,
            primaryContainer: colorScheme.errorContainer,
            onPrimaryContainer: colorScheme.onErrorContainer,
          ),
        ),
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.ok))
          ],
        ));
  }
}
