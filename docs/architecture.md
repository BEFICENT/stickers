# Architecture

## Boundaries

- `data/pack_repository.dart` owns versioned, atomic metadata persistence.
- `data/pack_service.dart` is the command boundary for pack mutations. UI code
  must not mutate pack fields or sticker lists before persistence.
- `data/pack_validator.dart` enforces WhatsApp-compatible output constraints.
- `media/media_probe.dart` classifies picker, share, and batch input from file
  signatures with extension fallback.
- `editor/editor_export_service.dart` renders overlays and owns animated export
  retries, limits, and temporary-file cleanup.
- `navigation/` owns typed route arguments and media-to-route mappings.
- `integrations/whatsapp_pack_service.dart` is the WhatsApp adapter. Domain
  models do not import plugin APIs.
- `diagnostics/app_diagnostics.dart` records bounded local error logs.

## State And Persistence

`PackStore` remains the observable collection used by the current widgets.
All writes must go through `PackService`, which applies a mutation, writes one
repository snapshot, and restores memory and files if that write fails.

New features should receive services through constructors where practical.
Do not add new reads of the global `packs` collection outside existing legacy
screens. Migrating those screens to an application scope can be done
incrementally without changing the persistence contract.

## Media Workflow

Picker, Android share, and batch files are normalized to `MediaDescriptor`.
Static images route to crop, GIFs route to GIF trim, and videos route to video
trim. Every generated sticker is validated before it enters a pack.

## Native Boundary

Dart sends request IDs with every trim/encode call. Kotlin reports request IDs
on event channels so stale events cannot complete a newer request. Native jobs
are single-flight, cancellable, and released with the Android activity.
