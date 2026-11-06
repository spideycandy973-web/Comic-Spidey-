# Comic Spidey — City Streets prototype

A **small, playable 3D Android prototype**, not the full game requested. It contains a custom spider-themed hero, two original boss encounters, a small city, walking civilians, and improved swinging. This is not an official Spider-Man game and does not claim to contain licensed characters, suits, artwork, or the PlayStation story. The custom art and characters are original prototype assets.

## Play

- Choose **Play Prototype** for two sequential villain encounters, or **Free Roam** to explore without a boss.
- **Move:** virtual joystick. **Look:** drag the scene. **Camera:** tap the camera button to switch third-/first-person.
- **Swing:** face a building and hold **SWING**. The line attaches to a real nearby rooftop. With swing assist on (default), a ground launch and gradual winch help you get airborne; release the button to keep your momentum. With assist off, jump first and move to build speed. No roof ahead/in range means no attachment; turn or get closer. The HUD displays web state and approximate altitude.
- **Combat:** approach a boss and tap **ATTACK**. The red ring telegraphs an attack; jump or move away. Bosses get faster in phase 2. Defeat both for victory.
- **Civilians:** walk up to a pedestrian and tap **TALK** for a short line. Pedestrians follow simple loops, not advanced AI. Traffic is decorative and has no collisions.
- Desktop: WASD/arrows to move; drag to look; Space to jump; hold Shift to swing; F to attack; E to talk; C to switch camera; Escape to pause.
- Manual day/sunset/night palettes and swing assist persist locally. The app pauses when backgrounded. Boss progress is **not saved**; a new run starts from the first villain.

The native Android activity uses package `com.comicspidey` and hosts offline WebGL/Three.js in a landscape WebView. Android 6.0+ (API 23+), subject to device WebGL support. **No physical device compatibility or performance claims are made.**

## Not yet implemented

The full open world, long campaign, licensed villains and suits, missions, dialogue system, audio, dynamic weather/time, top-down camera, controller support, customizable controls, world streaming, graphics presets, 4K/120 Hz, and production animation/graphics are not implemented. NPCs have limited scripted lines, vehicle collisions are absent, combat and enemy AI are rudimentary, and movement/camera collision is approximate. This is still a prototype, not the final app.

## Run in a browser

```sh
python3 -m http.server 8000 --directory app/src/main/assets
```

Visit `http://localhost:8000` in a WebGL-capable browser using a landscape viewport. The Android app uses the same local assets and requires no network permission.

## Build for Android

Install JDK 17, Android SDK Platform 35, and Gradle 8.9. Set `ANDROID_HOME` or set `sdk.dir` in an untracked `local.properties`:

```sh
gradle :app:assembleDebug
```

The APK is `app/build/outputs/apk/debug/app-debug.apk`. It is **debug-signed for testing only**, not a Play Store release. A production APK/AAB requires secure release signing, real-device validation, licensing review, and release configuration. Each CI run may use a different debug signing key; uninstall an older debug APK if Android refuses the update (this removes its app data). GitHub Actions runs simulation and browser tests, builds a debug APK, and publishes a one-time `v0.3.0-prototype` prerelease if absent.

## Test and architecture

```sh
node --test tests/*.test.js
```

`physics.js` owns 3D movement and data-driven boss rules; `city.js` owns basic pedestrian movement/dialogue; `game.js` handles Three.js presentation, cameras and input; `MainActivity.java` owns Android lifecycle. Browser smoke testing in CI additionally uses `playwright-core` and Chrome. Three.js 0.160.1 is vendored under its MIT license in `app/src/main/assets/vendor/`. This lightweight prototype is not the requested Unity/URP production architecture; the full game requires substantial further development.
