# Yawala Browser

[![CI](https://github.com/yawala-siwala/yawala-browser/actions/workflows/build-test.yml/badge.svg)](https://github.com/yawala-siwala/yawala-browser/actions/workflows/build-test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Linux%20%7C%20macOS%20%7C%20Windows-blue)

> Cross-platform web browser, part of the Yawala-Siwala ecosystem. One Flutter code base targeting Android, iOS, Linux, macOS and Windows.

## Status

**Boilerplate / scaffolding** - the repository carries a complete single-code
base skeleton (state management, platform bindings, UI layer, CI matrix) with
sample data. Feature work starts on `main` via pull requests.

## Features

- Multi-tab state container with active-tab tracking and URL resolution
- Search-or-URL omnibox semantics built into `BrowserService.resolveInput`
- Native web-engine hooks isolated behind one method channel
  (`com.yawalasiwala/browser`) with per-platform renderers
- Shared design language with all Yawala-Siwala apps via `yawala-core`

## Architecture

```
lib/
  main.dart                     # entry point
  app.dart                      # MaterialApp + Material3 theming
  domain/
    model.dart                  # pure domain model (WebTab)
    service.dart                # data access / future platform wiring
  state/
    app_state.dart              # BrowserState (ChangeNotifier state management)
  native/
    platform_bindings.dart      # method-channel contracts per platform
  ui/
    screens/home_screen.dart    # main screen
    widgets/                    # toolbar + item cards
```

Platform configs are committed as consistent bundle-ID bootstrap files for
every target (`com.yawalasiwala.browser`):

| Platform | File |
| --- | --- |
| Android | `android/app/src/main/AndroidManifest.xml` (+ `app/build.gradle.kts` stub) |
| iOS | `ios/Runner/Info.plist` |
| Linux | `linux/yawala-browser.desktop` |
| macOS | `macos/Runner/Info.plist` |
| Windows | `windows/runner/main.cpp` (+ `Runner.rc`) |

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel) and a sibling checkout of the shared package:

```bash
git clone https://github.com/yawala-siwala/yawala-browser.git
cd yawala-browser
git clone https://github.com/yawala-siwala/yawala-core.git ../yawala-core
flutter pub get
flutter test
```

## Build instructions

Regenerate the native runner for a target once, then the configs above are
merged into generated sources:

```bash
flutter create . --platforms=android,ios,linux,macos,windows --org com.yawalasiwala --project-name yawala_browser
```

### Android
```bash
flutter build apk --release          # or: flutter build appbundle
flutter install                      # to a connected device/emulator
```

### iOS (requires macOS + Xcode)
```bash
flutter build ios --release          # or: flutter build ipa
```

### Linux (requires clang, cmake, ninja, libgtk-3-dev)
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
flutter build linux --release
flutter run -d linux
```

### Windows (requires Visual Studio 2022 with the C++ desktop workload)
```bash
flutter build windows --release
flutter run -d windows
```

### macOS (requires Xcode 14+)
```bash
flutter build macos --release
flutter run -d macos
```

## Continuous integration

`.github/workflows/build-test.yml` runs `flutter analyze` + `flutter test` on
Ubuntu, macOS and Windows, then builds debug artifacts (Android APK on Ubuntu,
`.app` on macOS, `.exe` on Windows) and uploads them per runner.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep one code base for all five
platforms and lift anything shared into
[yawala-core](https://github.com/yawala-siwala/yawala-core).

## License

MIT - see [LICENSE](LICENSE). Copyright (c) 2026 Yawala-Siwala Contributors.