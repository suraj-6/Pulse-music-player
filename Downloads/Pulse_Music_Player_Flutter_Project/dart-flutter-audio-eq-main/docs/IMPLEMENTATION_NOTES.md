# Implementation and submission notes

## Required scope implemented

- Bundled sample playback and native file picking.
- Play/pause, seek, previous/next.
- Track filename, elapsed time, total duration.
- Three live EQ bands and flat reset.
- Android and Windows target runners.

## Intentionally not added

No login, cloud sync, database, playlists saved to disk, equalizer presets, spectrum visualizer, lyrics, streaming catalog, background service, or unrelated DSP modes. The app remains focused on the assignment.

## Validation to run on the developer machine

This workspace did not have the Flutter SDK available to execute `flutter pub get`, `flutter analyze`, or native builds. Before submission, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Then test Android on a physical device or emulator:

```bash
flutter run -d <android-device-id>
```

The native plugin must be compiled by Flutter for the target host; a successful static source review is not a substitute for a Windows and Android runtime test. If the current installed Flutter version is older than Dart 3.11, upgrade Flutter before resolving dependencies.
