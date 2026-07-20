import 'package:stickers/src/batch/batch_import_queue.dart';
import 'package:stickers/src/media/media_probe.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/pages/crop_page.dart';
import 'package:stickers/src/pages/gif_crop_page.dart';
import 'package:stickers/src/pages/video_crop_page.dart';

abstract final class BatchImportNavigation {
  static String routeFor(BatchImportItem item) => switch (item.kind) {
        SourceMediaKind.image => CropPage.routeName,
        SourceMediaKind.video => VideoCropPage.routeName,
        SourceMediaKind.gif => GifCropPage.routeName,
        _ => throw StateError('Unsupported batch media kind: ${item.kind}'),
      };

  static MediaType mediaTypeFor(BatchImportItem item) => switch (item.kind) {
        SourceMediaKind.image => MediaType.picture,
        SourceMediaKind.video => MediaType.video,
        SourceMediaKind.gif => MediaType.gif,
        _ => throw StateError('Unsupported batch media kind: ${item.kind}'),
      };
}
