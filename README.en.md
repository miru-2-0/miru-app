# miru

**English** | [中文](README.md)

A cross-platform media aggregation player built with Flutter. By loading JavaScript extension scripts, it parses lists, details and playback sources from third-party streaming sites, and provides local favorites, a built-in player and a themed UI.

## Features

- **Extension mechanism**: JavaScript scripts act as plugins, executed at runtime via QuickJS, covering list / search / detail / playback extraction
- **Favorites**: locally store your favorited titles (persisted via `shared_preferences`)
- **Built-in player**: powered by `media_kit` (libmpv/MSVPw backend), with progress memory and draggable progress bar
- **Search**: shows search results across installed extensions
- **Settings**: manage installed extensions, browse the extension repository, install local extensions

## Supported Platforms

| Platform | Support | Notes |
| --- | --- | --- |
| Windows | ✅ | Verified (QuickJS native bridge `quickjs_c_bridge.dll`) |
| macOS | ✅ | Supported |
| Linux | ✅ | Requires the QuickJS native library |
| Android | ✅ | Extension image hosts often use plain HTTP; enable `usesCleartextTraffic` in `AndroidManifest.xml` |
| iOS | ⚠️ | Can be built with `--no-codesign`; official distribution requires Apple signing |

> **No Web support**: the extension runtime depends on the QuickJS native FFI (`flutter_js`), which cannot run in a pure web environment, so the web platform has been removed.

## Quick Start

```bash
# 1. Install Flutter (>= 3.2, Dart SDK ^3.13)
# 2. Fetch dependencies
flutter pub get

# 3. Run (Windows as example)
flutter run -d windows

# 4. Build release artifacts
flutter build windows --release        # Windows
flutter build apk --release            # Android
flutter build macos --release          # macOS
flutter build linux --release          # Linux
flutter build ios --release --no-codesign  # iOS (unsigned)
```

## Publishing to GitHub

The repository comes with a GitHub Actions pipeline (`.github/workflows/release.yml`). Pushing a tag automatically builds every platform and uploads the artifacts to a GitHub Release:

```bash
git tag v0.0.5
git push main v0.0.5
```

Per-platform artifacts:

- Windows: `miru-windows-x64.zip`
- Android: `miru-android.apk`
- macOS: `miru-macos.zip`
- Linux: `miru-linux-x64.tar.gz`
- iOS: `miru-ios.zip` (unsigned)

Build logs can be viewed on the **Actions** tab; artifacts are downloadable from the **Releases** page.

## Running & Integration Tests

### Running the app

```bash
flutter run -d windows   # or any other enabled platform
```

### Generic extension-pipeline test tool

The tests auto-discover every `.js` script under `integration_test/fixtures/` and run the full chain for each: **latest → detail → watch → MediaDetailService contract conversion**. Cached extensions are deleted before the run and cleaned up afterwards, so every execution starts from a clean state.

```bash
# Test all fixtures in one go (Windows desktop device)
flutter test integration_test -d windows
```

#### How to use

1. **Add a script**: copy your extension into `integration_test/fixtures/` with any filename (e.g. `my_site.js`). The script must carry the `==MiruExtension==` metadata header (`@package`, `@name`, `@webSite`, etc.).
2. **Run**: execute the command above — all `.js` files are discovered and tested sequentially.
3. **Read results**: each extension prints `[PASS] package (name)` or detailed failure lines; any failing step (empty list, detail without episodes, empty playback URL, missing contract fields) is reported with specifics.
4. **Contract checks**: a sample (first 5 items by default) is converted and asserted — episodes non-empty, first episode has a playable URL, actor names non-empty; `director / area / writer / pubdate` pass if present in any sampled item (all missing only prints a note, since the contract allows null).

The underlying tooling lives in `integration_test/extension_test_tool.dart`:
- `runExtensionPipeline(...)`: single-extension pipeline entry (clear cache → direct runtime → manager contract conversion → cleanup);
- `discoverExtensionFixtures(...)`: scans the fixtures directory;
- `ExtensionTestReport`: results and failure details.

> Note: multiple QuickJS engines running concurrently in the same isolate trigger `JSValue released`, so all fixtures run **strictly sequentially** inside a single `test()`, each engine being disposed right after use with a settle delay — no test code changes are needed when adding a fixture.

> Note: the tests fetch live extension data and require network access; failures can be caused by a local proxy or the site being unreachable rather than by the script itself (image hosts not loading is usually a leftover proxy — see the FAQ below).

## Extension Contract

An extension is a JavaScript script executed inside QuickJS (see `assets/js/` or `integration_test/fixtures/360zy.com.js`). The script exposes standard list / search / detail / playback functions, with the following core contract:

- **List / Search**: returns an array of extractable entries (title, cover, link)
- **Detail**: parses `type`, `director`, `writer`, `area`, `lang`, `year`, `pubdate`, `remarks`, `total`, `score`, `actors`, description and episode list
- **Playback**: returns playback source links rendered by the built-in player

Scripts can be loaded through either:

- The extension repository (online install, see `extension_repo_service.dart`)
- Local install (`install_extension_screen.dart`)

> Field names and parsing details follow the contract defined in `template.js` and `extension_models.dart`.

## Project Structure

```
lib/
├── app/
│   ├── app.dart               # App entry & routing
│   └── theme/app_theme.dart   # Theme (deepPurple seed)
├── core/
│   └── constants/             # Global constants
└── features/
    ├── extension/             # Extensions: runtime, manager, repo, install & detail screens
    ├── home/                  # Home (recommendations + favorites)
    ├── search/                # Search
    ├── media_detail/          # Detail screen & detail parsing
    ├── player/                # Player
    ├── favorite/              # Favorites data service
    ├── settings/              # Settings
    └── main_navigation/       # Bottom main navigation
assets/
├── js/                        # Bundled extension scripts & crypto tools (md5 / CryptoJS / jsencrypt)
└── icon/                      # App icon
android/ ios/ linux/ macos/ windows/   # Platform projects
integration_test/              # End-to-end integration tests
```

## FAQ

- **Images not loading**: usually your local proxy is still on; also, extension image hosts are often plain HTTP with a custom port — Android 9+ blocks cleartext traffic by default, so set `android:usesCleartextTraffic="true"` on the `application` element in `AndroidManifest.xml`.
- **Android build fails with Kotlin target validation error**: keep `kotlin.jvm.target.validation.mode=warning` in `android/gradle.properties`.
- **iOS package cannot be installed directly**: the CI output is an unsigned source package; wire up signing certificates for official distribution.

## License

This project is a derivative work based on the upstream [miru-app](https://github.com/miru-project/miru-app) and is released under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for the full text.

Under the copyleft terms of GPL-3.0, any derivative work must also be released under GPL-3.0 with the original copyright notices preserved.

> Note: the companion extension repository [miru-2-0/repo](https://github.com/miru-2-0/repo) (extension scripts and `index.json`) is licensed under **MIT**, independent of the main app.