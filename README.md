# Comic Spidey — Rooftop Run

An **early, playable Android traversal prototype**, not the finished open-world game. This repository starts with a small, original side-view comic world so the core movement can be tested and extended. It does not contain licensed Spider-Man artwork, characters, story, music, or other official assets; the project name does not imply a license or endorsement.

## What works

- Landscape Android app (`com.comicspidey`) hosting an offline Canvas game in a native WebView, Android 6.0+ (API 23+).
- Original procedurally drawn city, side-view player, parallax skyline, rooftops and 12 collectible pages.
- Physics-based gravity, jump, horizontal air control, nearby rooftop web anchors, rope constraint, and release momentum. The model is 2D, not 3D; there are no building side collisions or wall running yet.
- Touch controls: hold left/right to move, tap jump, and **hold swing** near a higher rooftop; release to launch. On desktop use A/D or arrow keys, Space, and hold Shift to swing. Escape pauses.
- Local progress (position and collected pages) and settings; play resumes the saved run. Pausing, backgrounding and returning to the menu save progress. Clearing app storage resets it.
- Day, sunset and night palettes and a swing-assist range option. These are manual visual choices, not a time cycle.
- Automatic pause on Android background/back and browser backgrounding.

## Not implemented

The campaign, chapters, enemies, bosses, combat, suits, dialogue, sound, dynamic weather and day/night cycle, 3D physics, wall traversal, camera modes, controller support, customizable touch layout, streaming, graphics presets, adaptive resolution, and 4K/120 Hz options are **not implemented**. Artwork is simple original vector-style prototype art, not a claim of production-quality assets. No APK/AAB production release or device performance target is implied by this prototype.

## Run in a browser

From the repository root:

```sh
python3 -m http.server 8000 --directory app/src/main/assets
```

Visit `http://localhost:8000` on the same machine. Use a landscape viewport. The Android app uses the same local assets and requires no network permission.

## Build for Android

Install JDK 17, Android SDK Platform 35, and Gradle 8.9; ensure `ANDROID_HOME` points at the SDK (or set `sdk.dir` in an untracked `local.properties`). Then run:

```sh
gradle :app:assembleDebug
```

The debug APK will be at `app/build/outputs/apk/debug/app-debug.apk`. It is signed with the standard debug key and is **for testing only**, not a production/Play Store release. A production AAB/APK requires an appropriately secured release signing key, real-device validation, licensing review and release configuration. Android API choices here are prototype defaults, not a claim of device compatibility testing.

The GitHub Actions workflow runs movement tests and builds a debug APK as a downloadable workflow artifact. It does not publish a production release.

## Test

```sh
node --test tests/*.test.js
```

The movement model is separate from rendering (`app/src/main/assets/physics.js`) and can be tested without Android. `game.js` owns UI, rendering and save orchestration; `MainActivity.java` owns the native lifecycle. This is a pragmatic prototype architecture rather than the requested Unity/URP production architecture. A larger 3D project would need an engine migration and independently developed systems.

## Roadmap / scope

1. Validate movement and touch controls on real Android devices; add proper collision and accessibility.
2. Build a modular world/streaming layer and improved original animated assets.
3. Design and test combat, AI, missions, save versioning, audio and accessibility.
4. Evaluate a 3D-capable engine for additional camera modes and 3D swinging; profile quality and refresh-rate options on supported hardware.
5. Add content only with the necessary rights, then run device testing and create a properly signed release.
