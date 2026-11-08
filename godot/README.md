# Native Godot Android game — work in progress

This Godot 4.3 project is a native Android game, separate from the legacy WebView in `../app`. It is **not yet a finished release**. It contains a 13-objective Story sequence, repeatable Free Roam emergencies, checkpoint retry and separate local saves, touch controls, an original procedurally generated city with parks and simple road traffic, and the supplied Spider-Man and Doctor Octopus models. Citizens use four generated rigged variants. Combat has melee, web shots, enemy AI and health; swinging uses a physics rope attached to rooftops. The game works offline and uses original synthesized sound effects.

Important limitations: the city and vehicles use original procedural geometry, not the detailed finished artwork requested. The Doctor Octopus model is not rigged and uses procedural tentacle deformation and a body lunge rather than a skeletal rig; Spider-Man's punch uses a procedural arm pose rather than a supplied combat animation. Pedestrian dialogue and behavior are basic, and only four citizen models are used. Swinging, combat feel, performance and screen layouts have not been validated on physical Android devices. This must not be described or distributed as the finished game.

## Controls

On touchscreens use the left stick, drag empty space to look, hold WEB and release to let go, or press JUMP while swinging for a boosted release; HIT for melee, SHOT for web shots, JUMP and TALK. Use the pause button for resume, restarting modes, sound and mirrored touch layout. Keyboard: WASD, Space jump, Shift hold web, F attack, Q web shot, E talk, Escape pause.

Progress is autosaved locally per mode, at Story checkpoints, periodically during play, and on pause. Starting a new mode replaces that mode's save. No account or internet connection is required. This build's separate package ID means it does not import saves from the older WebView app.

## Development verification

Open `project.godot` in Godot 4.3 and run `main.tscn`. The native workflow imports models, tests objective transitions, combat, multitouch and saves, exports a debug APK and attempts Android emulator installation, launch and touch input. An emulator and automated checks do not replace hands-on testing on real devices. No signed final release is produced by this workflow.

## Additional citizen generation

The two additional citizens were generated from Citizen Maker using `tools/make-extra-citizens.mjs`, then simplified with glTF Transform 4.2.1 (`simplify --ratio 0.5 --error 0.001`). To regenerate them, copy the script into a Citizen Maker checkout with its models, install Three.js 0.160.1 in that checkout or a parent directory, and run `OUTPUT_DIR=/path/to/output node make-extra-citizens.mjs`. Simplify the two resulting GLBs before placing them in `assets/`. Citizen Maker and MakeHuman attribution is in `../ASSET_CREDITS.md`.

The native game's current comic-art pass uses cel lighting and ink outlines on characters, graphic window framing and a saturated palette for the procedural city, and comic-inspired interface panels using the OFL-licensed Bangers font. This is an ongoing visual treatment, not a claim of finished comic artwork or device-validated performance.
