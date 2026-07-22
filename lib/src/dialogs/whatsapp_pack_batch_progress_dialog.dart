import 'package:flutter/material.dart';
import 'package:stickers/generated/intl/app_localizations.dart';
import 'package:stickers/src/data/sticker_pack.dart';
import 'package:stickers/src/integrations/whatsapp_pack_batch_service.dart';

class WhatsappPackBatchProgressDialog extends StatefulWidget {
  final List<StickerPack> packs;
  final WhatsappPackBatchService service;

  const WhatsappPackBatchProgressDialog({
    super.key,
    required this.packs,
    required this.service,
  });

  @override
  State<WhatsappPackBatchProgressDialog> createState() =>
      _WhatsappPackBatchProgressDialogState();
}

class _WhatsappPackBatchProgressDialogState
    extends State<WhatsappPackBatchProgressDialog> {
  int _current = 0;
  StickerPack? _currentPack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final result = await widget.service.sendAll(
      widget.packs,
      onProgress: (current, total, pack) {
        if (!mounted) return;
        setState(() {
          _current = current;
          _currentPack = pack;
        });
      },
    );
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.packs.length;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(AppLocalizations.of(context)!.addToWhatsapp),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: total == 0 ? null : _current / total,
              ),
              const SizedBox(height: 16),
              Text(
                _currentPack?.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$_current / $total',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
