# Comic Spidey — development build

This repository contains a **small playable 3D prototype**, not the complete game. It has an original procedurally generated city (roughly 1.62 km across), streamed building chunks, an original story with travel, interactions, an escort, a group fight and boss encounters, free roam with repeatable street crimes, two boss encounters, simple walking civilians and swinging. It uses a user-supplied rigged Spider-Man model and a static user-supplied Doctor Octopus model; the first boss and some civilians are low-poly placeholders. Four pedestrians use an animated human model derived from CC0 MakeHuman geometry. The requested production game and realistic animated models are not yet implemented.

## Play

- **New Story** starts an original mission: investigate the plaza, stop Volt and Doctor Octopus, disable a relay, escort a civilian, stop a crew and confront Octopus again. Use TALK/USE at the relay and generator; the civilian follows only while nearby and on the ground. Follow the yellow beacon. **Continue** resumes at the last objective checkpoint; a boss fight restarts at full health after resuming. It is not the PlayStation storyline.
- **Free Roam** starts a new exploration session without a boss; **Continue Free Roam** restores the last saved position, health, web energy and camera. It autosaves every five seconds of gameplay and when paused. Ropes, momentum and active encounters are not restored; a save inside a building is moved to its roof. Story and Free Roam saves are separate. Repeatable street events appear at red beacons and on the minimap. Stop an assault, defeat a crew and help a civilian, or stop attackers and disarm a device before its timer expires. Completed events restore health and add to a locally saved crime count. The attackers are simple low-poly models with basic pursuit; leaving does not save the current encounter. A north-up minimap shows nearby streets, parks, buildings, the player and the current objective. The city has downtown, midtown, industrial and residential districts plus four green parks. Buildings have collision and valid web anchors; trees, streetlights and benches are decorative. A small reusable crowd walks around the central plaza or a nearby road junction as you explore and can be spoken to; four use the generated rigged human model, while four use simple placeholders. Their AI is limited. A small recycled traffic pool follows exploration and stops for nearby people, but has no vehicle collisions or damage.
- Move with the virtual joystick and drag the scene to look. Use the camera button to cycle third-person, first-person and overhead views.
- Face a building and hold **SWING** to attach to a rooftop. The visible line starts at the hero's hand; release to keep momentum. Swing assist (on by default) provides a takeoff boost and slow reel-in. With assist off, jump first and move to build speed. If there is no roof in range/ahead, turn or get closer. The supplied Spider-Man rig uses idle, run, hanging, jump, fall and landing animation clips, and the third-person web begins at its animated hand.
- Hold **JUMP** while moving into a wall in the air to run upward briefly; the limit resets after landing. This is a basic traversal mechanic rather than full wall-crawling animation.
- Attacks and web shots are blocked by building walls. Approach an enemy and tap **ATTACK** for a three-hit damage combo. **WEB SHOT** automatically targets the nearest enemy within range, briefly stuns them and consumes rechargeable web energy. **DODGE** bursts in the movement direction (or sideways at rest) and briefly avoids incoming hits. Warning rings telegraph attacks; bosses become faster in phase 2.
- Desktop: WASD/arrows to move; drag to look; Space to jump (hold into a wall to run up); hold Shift to swing; F to attack; G to shoot a web; Q to dodge; E to talk; C to switch camera; Escape to pause.
- Standard-mapped controllers: left stick moves, right stick looks, A jumps/holds wall run, B dodges, X attacks, Y shoots a web, right trigger swings, left bumper talks/uses, right bumper changes camera, Start pauses/resumes. Support depends on the Android WebView/controller exposing the standard Gamepad API; nonstandard controllers are not mapped.
- Completing story objectives for the first time and stopping street crimes earns locally saved XP and rank. XP unlocks two optional color tints of the same Spider-Man model; these are cosmetic filters, not separate suit models.
- Manual day/sunset/night palettes, an optional gradual day/night cycle and swing assist persist locally. The cycle advances during gameplay only. Cosmetic rain (fixed or changing), render-resolution presets, control size and side swapping, draggable positions for the joystick and five action buttons, and synthesized sound effects can be adjusted and persist locally. Weather advances only during gameplay; it does not affect physics. The app pauses when backgrounded.

## Asset and scope status

The user confirmed permission to distribute the supplied character and animation assets. The Spider-Man FBX archive includes a rigged mesh and compatible idle, run and hanging clips; the Doctor Octopus GLB is static, with no independently animated limbs or tentacles. See `ASSET_CREDITS.md` for provenance and attribution. This project is not represented as official or endorsed. The oversized city GLB in Drive is not needed for this original procedural city and has not been imported. No suitable civilian character models were identified in the folder; four generated MakeHuman-derived humans are used instead.

A long, production-quality campaign, additional characters and distinct suit models, photorealistic citizen models, production-quality animations, full-scale living city, full weather effects, broader controller compatibility, fully adjustable HUD controls, music and production audio, advanced graphics options, 4K/120 Hz, and production performance/device validation remain unimplemented. Camera and collision are approximate; NPCs and traffic are limited. No claims are made of a finished game or device compatibility.

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

`physics.js` owns movement and enemy rules; `combat.js` owns combat; `crime.js` owns free-roam encounters; `savegame.js` validates and restores Free Roam saves; `progress.js` owns cosmetic XP progress; `layout.js` validates normalized touch positions; `weather.js` and `audio.js` own environmental state and synthesized effects; `gamepad.js` maps standard gamepads; `city.js` owns pedestrian simulation; `traffic.js` owns the lightweight traffic pool; `story.js` owns story progression; `game.js` handles Three.js rendering, streaming and input; `MainActivity.java` owns Android lifecycle. Three.js 0.160.1 is vendored under MIT in `app/src/main/assets/vendor/`. This lightweight WebView prototype is not the requested Unity/URP production architecture.
