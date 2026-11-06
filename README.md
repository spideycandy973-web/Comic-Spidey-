# Comic Spidey — City Showdown

An **early, playable 3D Android prototype**, not the finished open-world game. This replaces the old side-view slice with a small city, two camera perspectives and two original villain encounters. It uses original prototype art and characters, not licensed Spider-Man artwork, story, or other official assets; the project name does not imply a license or endorsement.

## What is playable

- A small 3D city with building and rooftop collision, a controllable original hero, basic jump, and 3D physics-based web tethering. Hold swing near a rooftop and release to launch; jump first for momentum. This is a simplified prototype, not production-quality traversal.
- **Third-person** follow camera and **first-person** camera. Switch with the on-screen camera button or C. Drag the scene to look around; movement is relative to the camera. The camera does not yet have building-occlusion avoidance.
- Two original sequential bosses: **Volt** and **Ironclad**. Each pursues the player, telegraphs attacks with a red ring, deals damage, and gets faster in phase 2. Get close and tap attack. You can jump or move away to avoid an attack. Defeat both to win; retry after defeat. They are original prototypes, not the requested licensed Spider-Man roster.
- Landscape touch controls (movement joystick, camera drag, jump, hold swing, attack, camera switch, pause). Desktop: WASD or arrows, drag to look, Space to jump, hold Shift to swing, F to attack, C to change camera, Escape to pause.
- Manual day/sunset/night palettes and swing assist setting, stored locally. Backgrounding the app pauses the game. Boss progress is **not saved**; a new run starts from the first villain.
- Native Android activity (`com.comicspidey`) with offline WebGL/Three.js rendering in a WebView; Android 6.0+ (API 23+), subject to device WebGL support.

## Not implemented

The long-form campaign, licensed villains and suits, missions, dialogue, audio, dynamic weather and time cycle, third camera mode, controller support, customizable touch layout, world streaming, graphics presets, 4K/120 Hz options, and production animation/graphics are **not implemented**. No physical device compatibility or performance claims are made. Camera clipping, rudimentary enemy AI, and simple collision and animation are known prototype limitations.

## Run in a browser

```sh
python3 -m http.server 8000 --directory app/src/main/assets
```

Visit `http://localhost:8000` on the same machine in a WebGL-capable browser and use a landscape viewport. The Android app uses the same local assets and requires no network permission.

## Build for Android

Install JDK 17, Android SDK Platform 35, and Gradle 8.9. Set `ANDROID_HOME` or set `sdk.dir` in an untracked `local.properties`:

```sh
gradle :app:assembleDebug
```

The APK is `app/build/outputs/apk/debug/app-debug.apk`. It is **debug-signed for testing only**, not a Play Store release. A production APK/AAB requires secure release signing, real-device validation, licensing review, and release configuration. GitHub Actions builds a debug APK, tests the movement/boss model and browser gameplay, and publishes a one-time `v0.2.0-prototype` prerelease if absent.

## Test and architecture

```sh
node --test tests/*.test.js
```

`physics.js` contains the 3D movement and data-driven boss rules independently of rendering; `game.js` handles Three.js presentation, cameras and inputs; `MainActivity.java` owns the Android lifecycle. Browser smoke testing in CI also requires `playwright-core` and Chrome. Three.js 0.160.1 is vendored under its MIT license in `app/src/main/assets/vendor/`. This is a lightweight prototype, not the requested Unity/URP production architecture; an expanded game would need substantial further engineering and content development.
