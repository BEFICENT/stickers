# Third-Party Code

## Flutter Git Dependencies

The following modified dependencies are pinned to immutable commits:

| Dependency | Repository | Revision |
| --- | --- | --- |
| `matrix_gesture_detector` | `lolocomotive/matrix_gesture_detector` | `62749b7e18f6a61834ca7f5bb45f9c7ace12bdd2` |
| `image_editor` | `lolocomotive/flutter_image_editor` | `e848b10f7be0e78dc89b0907b92859b66a12144e` |
| `whatsapp_stickers_plus` | `lolocomotive/whatsapp_stickers_plus` | `c435f986166c5734b1d64561307cad619814f531` |
| `flutter_archive` | `lolocomotive/flutter_archive` | `555a589a0b4def2641f02e5352f4b842ccf9164d` |

The lockfile records the same resolved revisions. These repositories are not
currently mirrored under this project's GitHub owner. Before changing a pinned
dependency, create an owner-controlled mirror, preserve its license and history,
verify the commit hash, then update the URL without changing behavior.

## Vendored Flutter Dependencies

- `extended_image` is stored under `third_party/extended_image` from
  `lolocomotive/extended_image` revision
  `9a0a7a577c29519d3535b14db95922bb0d53b78c`. Its MIT license is preserved in
  that directory. The local editor adds optional anchored crop-boundary
  clamping and an option to disable automatic crop recentering.

## Native Dependencies

- `android-gif-drawable` 1.2.31 is resolved from Maven Central.
- libwebp source is vendored under `android/app/src/main/cpp/libwebp` and was
  introduced by repository commit `0afc5c28f20d141ff10179ec2242f7976cadb9bd`.
  The stripped source snapshot does not contain reliable release metadata; its
  encoder and decoder ABI are `0x0210`.
- The local libwebp animation finalization/blending changes are part of this
  repository and must remain covered by Android build and animated-output smoke
  tests.

Do not replace the vendored source opportunistically. A future update must note
the exact upstream tag and archive checksum, preserve the upstream license,
reapply documented local changes, and run GIF/video device fixtures.
