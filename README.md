# Stickers

An independent, ad-free Android sticker pack editor for WhatsApp.

## Features

- Static and animated sticker packs
- Image, GIF, and video import
- Trimming for GIF and video stickers with WhatsApp duration enforcement
- Text, drawing, color, crop, and transform editing
- Guided batch import that preserves editing and trimming for every item
- Safe pack import/export with rollback and archive validation
- WhatsApp pack validation before sending
- Local-only diagnostics; the app does not upload crash logs

## Development

Prerequisites are Flutter stable, Android SDK 35 or newer, JDK 17, CMake 3.22.1,
and NDK 29.0.14206865.

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

The development build uses `de.loicezt.stickers.dev`, so it can be installed
alongside the production application. The configured local emulator is
`Stickers_API_35`.

See [Testing](docs/testing.md), [Architecture](docs/architecture.md), and
[Releasing](docs/releasing.md) before making cross-cutting changes.

## Releases

Signed Android releases are produced by the tag-driven GitHub Actions workflow.
The workflow requires repository signing secrets and publishes APK, AAB, and
SHA-256 checksum artifacts. Debug signing must not be used for public releases.

## Licensing And Origin

This project is licensed under GPL-3.0. It is derived from
[`lolocomotive/stickers`](https://github.com/lolocomotive/stickers). See
[NOTICE](NOTICE) and [Third-party code](docs/third_party.md) for provenance and
dependency details.
