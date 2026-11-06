# Comic Spidey — development build

This repository contains a **small playable 3D prototype**, not the complete game. It has a larger procedurally generated city (roughly 420 m across), streamed building chunks, a four-objective original story, free roam, two original boss encounters, simple walking civilians and swinging. The existing hero and bosses are original, low-poly placeholders—not official Spider-Man or licensed villain models. The requested production game and realistic animated models are not yet implemented.

## Play

- **New Story** starts a short original mission: investigate the plaza, defeat Volt, travel north, then defeat Ironclad. Follow the yellow beacon. **Continue** resumes at the last objective checkpoint; a boss fight restarts at full health after resuming. It is not the PlayStation storyline.
- **Free Roam** lets you explore the map without a boss. Civilians walk around the original central plaza and can be spoken to; their AI is limited. Traffic is decorative and has no collisions.
- Move with the virtual joystick and drag the scene to look. Use the camera button for third-/first-person view.
- Face a building and hold **SWING** to attach to a rooftop. The visible line starts at the hero's hand; release to keep momentum. Swing assist (on by default) provides a takeoff boost and slow reel-in. With assist off, jump first and move to build speed. If there is no roof in range/ahead, turn or get closer. The stylized placeholder body leans and moves while swinging; this is not skeletal character animation.
- Approach a boss and tap **ATTACK**. A red ring telegraphs an attack; jump or move away. Bosses become faster in phase 2.
- Desktop: WASD/arrows to move; drag to look; Space to jump; hold Shift to swing; F to attack; E to talk; C to switch camera; Escape to pause.
- Manual day/sunset/night palettes and swing assist persist locally. The app pauses when backgrounded.

## Asset and scope status

The supplied Drive folder contains a Spider-Man GLB and Doctor Octopus GLB with embedded CC-BY labels, but those labels do not establish underlying Spider-Man/game-character rights. They are not bundled or published pending confirmation of redistribution rights. The inspected GLBs are static, with no rig or animation. A separate Spider-Man archive contains FBX animation files, whose compatibility and rights still need checking. The 350 MB city GLB exceeds this environment's 100 MiB Drive file transfer limit; it needs to be split or optimized before import. No suitable civilian character models have yet been identified in the folder.

The long campaign, licensed characters and suits, realistic rigged human models, production-quality animations, full-scale living city, dynamic weather/time, top-down camera, controller support, configurable touch controls, audio, graphics presets, 4K/120 Hz, and production performance/device validation remain unimplemented. Camera and collision are approximate; NPCs and traffic are limited. No claims are made of a finished game or device compatibility.

## Run locally

```sh
python3 -m http.server 8000 --directory app/src/main/assets
```

Open `http://localhost:8000` in a WebGL-capable browser, using a landscape viewport. The native Android activity uses package `com.comicspidey` and hosts these offline assets in a WebView, Android 6.0+ (API 23+) subject to WebGL support.

## Build and test

Install JDK 17, Android SDK Platform 35, and Gradle 8.9; set `ANDROID_HOME` or `sdk.dir` in an untracked `local.properties`:

```sh
node --test tests/*.test.js
gradle :app:assembleDebug
```

The APK is `app/build/outputs/apk/debug/app-debug.apk`, signed with a debug key **for testing only**, not a production release. A Play Store release requires secure release signing, rights clearance, real-device testing and substantial further development. CI runs simulation and browser checks and uploads a debug APK artifact; it does not automatically publish releases. Different debug keys may require uninstalling an older test APK first, which deletes its app data.

`physics.js` owns movement and boss rules; `city.js` owns pedestrian simulation; `story.js` owns story progression; `game.js` handles Three.js rendering, streaming and input; `MainActivity.java` owns Android lifecycle. Three.js 0.160.1 is vendored under MIT in `app/src/main/assets/vendor/`. This lightweight WebView prototype is not the requested Unity/URP production architecture.
