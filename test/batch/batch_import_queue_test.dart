import 'package:flutter_test/flutter_test.dart';
import 'package:stickers/src/batch/batch_import_queue.dart';
import 'package:stickers/src/media/media_probe.dart';
import 'package:stickers/src/navigation/batch_import_navigation.dart';
import 'package:stickers/src/navigation/edit_arguments.dart';
import 'package:stickers/src/pages/crop_page.dart';
import 'package:stickers/src/pages/gif_crop_page.dart';
import 'package:stickers/src/pages/video_crop_page.dart';

void main() {
  test('advances through each item exactly once', () {
    final queue = BatchImportQueue([
      const BatchImportItem(path: 'one.png', kind: SourceMediaKind.image),
      const BatchImportItem(path: 'two.gif', kind: SourceMediaKind.gif),
    ]);

    expect(queue.activeNumber, 0);
    expect(queue.next()?.path, 'one.png');
    expect(queue.activeNumber, 1);
    expect(queue.next()?.path, 'two.gif');
    expect(queue.activeNumber, 2);
    expect(queue.next(), isNull);
  });

  test('maps every supported media kind to one route and editor type', () {
    const image = BatchImportItem(
      path: 'image.png',
      kind: SourceMediaKind.image,
    );
    const gif = BatchImportItem(path: 'image.gif', kind: SourceMediaKind.gif);
    const video = BatchImportItem(
      path: 'video.mp4',
      kind: SourceMediaKind.video,
    );

    expect(BatchImportNavigation.routeFor(image), CropPage.routeName);
    expect(BatchImportNavigation.routeFor(gif), GifCropPage.routeName);
    expect(BatchImportNavigation.routeFor(video), VideoCropPage.routeName);
    expect(BatchImportNavigation.mediaTypeFor(image), MediaType.picture);
    expect(BatchImportNavigation.mediaTypeFor(gif), MediaType.gif);
    expect(BatchImportNavigation.mediaTypeFor(video), MediaType.video);
  });
}
