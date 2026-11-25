# Pulse Music Player 🎵

A simple cross-platform music player built using **Flutter and Dart**, featuring audio playback, track navigation, seeking, and a real-time three-band equalizer.

**Target Platforms:** Android and Windows  
**Framework:** Flutter  
**Programming Language:** Dart

---

## 1. Project Overview

Pulse Music Player is a lightweight music player developed to demonstrate audio playback and real-time audio equalization using Flutter.

The application allows users to play bundled audio tracks or select audio files from their device. It provides standard playback controls along with three independent equalizer bands: Low, Mid, and High.

### Key Features

- Play bundled audio files.
- Import audio files from the device.
- Play and pause audio.
- Navigate to the next and previous tracks.
- Seek through the currently playing track.
- Display the current track name.
- Display elapsed time and total duration.
- Three-band equalizer with independent controls:
  - Low – 100 Hz
  - Mid – 1 kHz
  - High – 8 kHz
- Adjustable EQ range from -12 dB to +12 dB.
- Reset all equalizer bands to flat (0 dB).
- Real-time audio processing using SoLoud.

The application is designed to run on Android and Windows.

---

## 2. Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI development |
| Dart | Application programming language |
| flutter_soloud | Audio playback and real-time DSP processing |
| file_picker | Selecting audio files from the device |
| Material 3 | UI components and application theme |
| Android SDK | Android application development |
| Gradle | Android build automation |
| CMake | Windows desktop build configuration |

---

## 3. Project Architecture

The application follows a feature-based architecture that separates the user interface, playback functionality, and audio processing logic.

### Project Structure

```text
dart-flutter-audio-eq-main/
│
├── android/
│   └── Android platform configuration
│
├── windows/
│   └── Windows platform configuration
│
├── assets/
│   └── samples/
│       └── demo.wav
│
├── lib/
│   │
│   ├── main.dart
│   │
│   ├── app.dart
│   │
│   └── features/
│       │
│       ├── player/
│       │   └── player_page.dart
│       │
│       └── equalizer/
│           └── three_band_equalizer.dart
│
├── docs/
│   ├── ARCHITECTURE.md
│   └── IMPLEMENTATION_NOTES.md
│
├── pubspec.yaml
│
└── README.md
```

### Main Components

**1. main.dart – Application Entry Point**

- Initializes the Flutter application.
- Calls `runApp()` to start the application.
- Loads the main application widget.

**2. app.dart – Application Configuration**

- Configures the Material application.
- Defines the application theme.
- Sets the application title.
- Loads the PlayerPage as the home screen.

**3. player_page.dart – Music Player Interface**

This file handles the primary music player functionality.

Responsibilities include:

- Initializing the SoLoud audio engine.
- Loading bundled audio files.
- Importing audio files using the file picker.
- Managing the current track and track index.
- Implementing play and pause functionality.
- Implementing next and previous track navigation.
- Handling audio seeking.
- Displaying track information and playback duration.
- Updating the UI based on playback state.
- Connecting equalizer controls with the audio processing layer.

**4. three_band_equalizer.dart – Equalizer Processing**

This file handles the three-band equalizer implementation.

Responsibilities include:

- Initializing the parametric EQ filter.
- Configuring Low, Mid and High frequency bands.
- Updating individual band gains.
- Converting decibel values into linear gain.
- Applying EQ changes to the live audio mixer.
- Resetting all bands to their default values.
- Managing equalizer resources.

---

## 4. Packages Used

The following packages are used in the project.

| Package | Version | Purpose |
|---|---|---|
| flutter_soloud | ^5.3.2 | Audio playback and real-time equalizer processing |
| file_picker | ^13.4.1 | Importing audio files |
| cupertino_icons | ^1.0.8 | Cupertino icons |
| flutter_test | Flutter SDK | Testing support |
| flutter_lints | ^6.0.0 | Code quality and linting |

### flutter_soloud

The SoLoud audio engine is used for:

- Loading audio files.
- Playing and pausing tracks.
- Seeking through audio.
- Retrieving playback position.
- Obtaining audio duration.
- Applying real-time audio filters.

### file_picker

The file_picker package allows users to select audio files from their device.

The selected file is loaded into the audio engine for playback.

---

## 5. Equalizer Implementation

The most important functionality of this project is its three-band equalizer.

The application uses SoLoud's parametric EQ filter to modify the audio signal in real time.

Unlike a visual-only equalizer, the slider adjustments directly modify the audio processing parameters.

### 5.1 Three Equalizer Bands

The equalizer consists of three independent frequency bands.

| Band | Centre Frequency | Function |
|---|---:|---|
| Low | 100 Hz | Controls bass frequencies |
| Mid | 1,000 Hz | Controls middle frequencies and vocals |
| High | 8,000 Hz | Controls treble and higher frequencies |

Each band can be adjusted independently using a slider.

The adjustment range is:

**-12 dB to +12 dB**

### 5.2 Signal Processing Architecture

The audio processing pipeline works as follows:

```text
        Audio Input
             |
             v
    Audio File Loading
             |
             v
       SoLoud Engine
             |
             v
      Active Audio Voice
             |
             v
     Parametric EQ Filter
             |
       +-----+-----+
       |     |     |
       v     v     v
      LOW   MID   HIGH
     100Hz  1kHz  8kHz
       |     |     |
       +-----+-----+
             |
             v
       Audio Output
```

The equalizer is applied to the live audio mixer, allowing users to hear the changes while the track is playing.

### 5.3 Decibel to Linear Gain Conversion

The UI represents equalizer adjustments in decibels (dB).

However, the parametric EQ filter uses linear gain values.

Therefore, the application converts decibel values into linear gain.

The mathematical formula is:

G(linear) = 10^(G(dB)/20)

Where:

- G(linear) represents the linear gain.
- G(dB) represents the gain in decibels.

Examples:

| Decibel Value | Linear Gain |
|---|---:|
| -12 dB | 0.251 |
| -6 dB | 0.501 |
| 0 dB | 1.000 |
| +6 dB | 1.995 |
| +12 dB | 3.981 |

A gain of 0 dB represents the flat equalizer setting.

### 5.4 Parametric EQ Configuration

The equalizer uses three configured bands:

```dart
static const frequencies = [
  100.0,
  1000.0,
  8000.0
];

static const qValues = [
  0.8,
  1.0,
  0.8
];
```

The Q values control the bandwidth of each frequency band.

The initial linear gain of every band is set to 1.0.

### 5.5 Real-Time Equalizer Updates

When a user moves an equalizer slider:

1. The slider provides a new decibel value.
2. The value is clamped to the supported range.
3. The decibel value is converted into linear gain.
4. The corresponding EQ band is updated.
5. The SoLoud audio engine applies the updated filter parameters.
6. The user hears the change during playback.

The track does not need to be stopped or reloaded.

### 5.6 Reset Equalizer

The reset functionality sets all three bands to 0 dB.

```text
Low  = 0 dB
Mid  = 0 dB
High = 0 dB
```

This restores the equalizer to its flat response.

---

## 6. Audio Playback Implementation

The application supports both bundled audio and locally selected audio files.

### Bundled Audio

A demo WAV file is included in the project:

```text
assets/samples/demo.wav
```

The file is loaded using the SoLoud audio engine.

This allows users to test the player immediately without importing another file.

### Importing Audio Files

The file_picker package is used to select audio files from the device.

The general workflow is:

```text
User selects an audio file
          |
          v
      File Picker
          |
          v
   Retrieve file path
          |
          v
   Load using SoLoud
          |
          v
     Start Playback
```

### Playback Controls

The application implements:

**Play/Pause:** Starts or pauses the current audio track.

**Next:** Moves to the next available track.

**Previous:** Moves to the previous track.

**Seek:** Allows users to move to a particular position in the audio.

**Track Information:** Displays the current track name.

**Playback Duration:** Displays elapsed time and total track duration.

The track list is maintained in memory during the current application session.

---

## 7. Challenges Faced

During development and local Android setup, several challenges were encountered.

### 7.1 Gradle Distribution Download Failure

Initially, the Android build failed because Gradle could not download its required distribution.

Error:

```text
java.net.ConnectException: Connection timed out

Gradle threw an error while downloading artifacts
from the network.
```

**Solution:**

- Downloaded the Gradle 9.3.1 distribution ZIP manually.
- Temporarily configured the Gradle wrapper to use the local ZIP.
- Executed the Gradle wrapper command.
- Verified that Gradle 9.3.1 was successfully installed and extracted into the local Gradle cache.

### 7.2 Android NDK Installation

The next build attempt failed because the required Android NDK version was missing.

Error:

```text
Package ndk not found.

Package 28.2.13676358 not found.
```

**Solution:**

The required NDK version needs to be installed through:

Android Studio → Tools → SDK Manager → SDK Tools → Show Package Details → NDK (Side by side).

The exact required version is:

```text
28.2.13676358
```

### 7.3 Real-Time Equalizer Processing

One of the important implementation considerations was ensuring that the equalizer controls actually affect audio playback rather than only changing the displayed slider values.

**Solution:**

Used SoLoud's parametric EQ filter and updated the corresponding band gain whenever a slider value changes.

### 7.4 Cross-Platform Compatibility

The application targets both Android and Windows.

Platform-specific build tools and SDK configurations are required for each platform.

The Flutter application code is shared, while Android and Windows use their respective native runners.

**Note:** The Gradle and NDK issues are build-environment problems. A successful final Android and Windows build must be verified on the respective development environments.

---

## 8. UI Design

The application uses a custom colour palette to create a warm and minimal music player interface.

| Colour | Hex Code | Usage |
|---|---|---|
| Deep Plum | #4E2E54 | Primary text and dark surfaces |
| Dusty Rose | #954F75 | Secondary accents |
| Peach | #F8DAC3 | Highlights and artwork |
| Warm Cream | #F8F4E9 | Main background |
| Burgundy | #70263F | Primary playback controls and active states |

The design focuses on readability, simple controls and a consistent visual experience.

---

## 9. How to Run the Application

### Prerequisites

Install the following:

1. Flutter SDK.
2. Dart SDK.
3. Android Studio.
4. Android SDK.
5. Flutter and Dart plugins in Android Studio.
6. Visual Studio with Desktop development with C++ for Windows builds.

Check the Flutter installation:

```bash
flutter doctor -v
```

### Step 1: Clone the Repository

```bash
git clone https://github.com/<your-username>/<your-repository>.git
```

Navigate into the project:

```bash
cd dart-flutter-audio-eq-main
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Check Available Devices

```bash
flutter devices
```

### Step 4: Run on Android

Connect an Android phone with USB debugging enabled or start an emulator.

Execute:

```bash
flutter run
```

Alternatively:

```bash
flutter run -d <android-device-id>
```

### Step 5: Run on Windows

Make sure the Windows desktop development tools are installed.

Execute:

```bash
flutter run -d windows
```

### Useful Commands

Clean previous build files:

```bash
flutter clean
```

Install dependencies:

```bash
flutter pub get
```

Analyze the project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build Android APK:

```bash
flutter build apk --debug
```

Build Windows application:

```bash
flutter build windows --release
```

---

## 10. AI Tools Used

**ChatGPT (OpenAI)** was used as an AI development assistant throughout the project.

The tool assisted with development planning, code understanding, debugging, UI design decisions and technical documentation.

### How AI Was Used

**1. Project Planning**

ChatGPT helped break down the problem statement into individual requirements:

- Audio playback.
- Track navigation.
- Seeking.
- Playback duration display.
- Three-band equalizer.
- Reset functionality.
- Android and Windows support.

**2. Code Generation and Assistance**

ChatGPT was used to assist with:

- Flutter application structure.
- Dart code implementation.
- Audio playback logic.
- Equalizer implementation explanations.
- UI component suggestions.
- Code documentation.

Generated code was intended to be reviewed and integrated into the project rather than treated as automatically verified code.

**3. Debugging**

ChatGPT assisted in understanding build errors encountered during Android development.

Examples include:

- Gradle distribution download timeout.
- Local Gradle installation.
- Missing Android NDK version.
- Android build configuration issues.

It provided troubleshooting steps and commands to help resolve these problems.

**4. UI Design Decisions**

ChatGPT assisted in translating the supplied colour palette into a consistent application theme.

The selected colours were:

- Deep Plum: #4E2E54
- Dusty Rose: #954F75
- Peach: #F8DAC3
- Warm Cream: #F8F4E9
- Burgundy: #70263F

**5. Documentation**

ChatGPT assisted in preparing:

- Project architecture documentation.
- Package descriptions.
- Equalizer mathematical explanation.
- Setup instructions.
- Troubleshooting documentation.
- README content.

### AI Usage and Developer Responsibility

AI tools were used to accelerate development and assist with technical problem-solving.

The final implementation, integration, testing, and validation remain the developer's responsibility.

No AI tool is claimed to have independently verified the final Android or Windows builds or the audible EQ results.

---

## 11. Demo Video

A short demonstration video of maximum five minutes should cover:

1. Introduction to Pulse Music Player.
2. Launching the application.
3. Playing the bundled demo audio.
4. Demonstrating play/pause and track navigation.
5. Demonstrating seeking and playback duration.
6. Importing an audio file.
7. Adjusting Low, Mid and High equalizer sliders.
8. Demonstrating the reset-to-flat functionality.
9. Brief explanation of the application architecture.

The video should demonstrate actual application behavior on a tested platform.

**Demo Video Link:** Add your recorded video link here.

---

## 12. Future Improvements

The current implementation focuses only on the assignment requirements.

Possible future improvements include:

- Persistent music library.
- Playlist management.
- Album artwork support.
- Playback queue.
- Additional equalizer bands.
- Saving custom EQ presets.

These features are not part of the current assignment scope.

---

## 13. Conclusion

Pulse Music Player demonstrates how Flutter can be used to develop a cross-platform audio application with real-time audio processing.

The project combines Flutter UI development, SoLoud audio playback, parametric equalization and native platform integration.

The main objective is to provide a simple music player with functional playback controls and an audible three-band equalizer.

**Developed using Flutter and Dart.**

**Target Platforms: Android and Windows.**
