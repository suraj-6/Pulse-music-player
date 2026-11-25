# Project contents and feature checklist

This file is a quick map of the submitted project. Start with `README.md` for the full architecture and setup instructions.

## Files to know

| File / folder | Purpose |
|---|---|
| `lib/main.dart` | Flutter entry point |
| `lib/app.dart` | App theme and root screen |
| `lib/features/player/player_page.dart` | Player screen, bundled/imported tracks, transport controls, seek/time display |
| `lib/features/equalizer/three_band_equalizer.dart` | Three-band DSP setup, dB conversion, live updates and flat reset |
| `assets/samples/demo.wav` | Included sample audio for first launch |
| `android/` | Android application runner and Gradle configuration |
| `windows/` | Windows desktop runner and CMake configuration |
| `docs/ARCHITECTURE.md` | Playback lifecycle and EQ signal path |
| `docs/IMPLEMENTATION_NOTES.md` | Implemented scope and local validation checklist |

## Included assignment features

- [x] Bundled audio sample
- [x] Pick audio files from device
- [x] Play / pause
- [x] Seek
- [x] Next / previous
- [x] Current track name
- [x] Elapsed and total duration
- [x] Low / Mid / High sliders
- [x] Live EQ parameter changes
- [x] Reset to flat (0 dB on all bands)
- [x] Android target
- [x] Windows target

## Deliberately omitted

No additional product features beyond the requested player and EQ are included. The only UX detail added beyond the literal checklist is a compact track count label and loading/error feedback to make file loading understandable.
