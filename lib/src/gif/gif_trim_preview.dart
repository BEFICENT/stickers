import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _gifPreviewViewType = 'de.loicezt.stickers/gif_preview';

class GifTrimPreviewController {
  MethodChannel? _channel;
  int? _viewId;

  Future<void> setRange(Duration start, Duration end) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<void>('setRange', {
        'startMs': start.inMilliseconds,
        'endMs': end.inMilliseconds,
      });
    } on PlatformException {
      // The platform view may be disposing while the route is closing.
    }
  }

  Future<Duration?> position() async {
    final channel = _channel;
    if (channel == null) return null;
    try {
      final milliseconds = await channel.invokeMethod<int>('getPosition');
      return milliseconds == null ? null : Duration(milliseconds: milliseconds);
    } on PlatformException {
      return null;
    }
  }

  void _attach(int viewId) {
    _viewId = viewId;
    _channel = MethodChannel('$_gifPreviewViewType/$viewId');
  }

  void _detach(int? viewId) {
    if (_viewId != viewId) return;
    _viewId = null;
    _channel = null;
  }
}

class GifTrimPreview extends StatefulWidget {
  final String gifPath;
  final Duration start;
  final Duration end;
  final GifTrimPreviewController controller;

  const GifTrimPreview({
    required this.gifPath,
    required this.start,
    required this.end,
    required this.controller,
    super.key,
  });

  @override
  State<GifTrimPreview> createState() => _GifTrimPreviewState();
}

class _GifTrimPreviewState extends State<GifTrimPreview> {
  int? _viewId;

  @override
  void didUpdateWidget(covariant GifTrimPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      unawaited(widget.controller.setRange(widget.start, widget.end));
    }
  }

  @override
  void dispose() {
    widget.controller._detach(_viewId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Image.file(
        File(widget.gifPath),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    return AndroidView(
      viewType: _gifPreviewViewType,
      creationParams: {
        'gifFile': widget.gifPath,
        'startMs': widget.start.inMilliseconds,
        'endMs': widget.end.inMilliseconds,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (viewId) {
        _viewId = viewId;
        widget.controller._attach(viewId);
      },
    );
  }
}
