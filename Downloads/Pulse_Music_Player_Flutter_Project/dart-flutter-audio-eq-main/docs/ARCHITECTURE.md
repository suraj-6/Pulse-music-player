# Architecture notes

## Layers

- **App shell (`app.dart`)**: global Material theme and route root.
- **Player feature (`player_page.dart`)**: owns the selected track list, SoLoud source/voice handle, transport state, import action, and presentation. It coordinates playback operations.
- **EQ feature (`three_band_equalizer.dart`)**: isolates DSP setup and gain conversion from widgets. It exposes three gain values, `setGain`, `reset`, and `dispose`.
- **Native audio runtime (`flutter_soloud`)**: decodes assets/files, outputs audio, tracks the playhead, and applies the parametric EQ in the live mixer.

## Runtime sequence

```text
main()
  └─ AudioEqApp
      └─ PlayerPage.initState
          ├─ SoLoud.init()
          ├─ ThreeBandEqualizer.initialize()
          │   └─ activate parametricEqFilter; configure 3 bands
          └─ load bundled WAV
              └─ SoLoud.loadAsset() -> AudioSource -> play() -> SoundHandle
```

## EQ signal path

```text
Selected audio source
       |
       v
SoLoud decoder / voice
       |
       v
Live mixer parametric EQ
  ├─ Band 1: 100 Hz / Low
  ├─ Band 2: 1 kHz / Mid
  └─ Band 3: 8 kHz / High
       |
       v
Audio output device
```

The equalizer filter is global to this app's SoLoud mixer. Changing a band updates its gain parameter without stopping or replacing the active voice.
