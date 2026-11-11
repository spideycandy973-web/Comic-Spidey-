# Comic Spidey

**Current game: native Android, built with Godot 4.5.2.** The active game project is in [`godot/`](godot/README.md). The older Three.js Android WebView prototype in [`app/`](app/) is retained only as a legacy reference and is not the active game.

## Current native game

- Third-person 3D city exploration with streamed procedural districts, streets, buildings, rooftops and parks.
- Story mode with 13 objectives, dialogue, boss encounters, an escort, checkpoints and local saves.
- Free Roam with repeatable street emergencies, enemy encounters, traffic and pedestrian NPCs.
- Touch joystick, look gestures, action buttons, minimap, camera controls and adjustable graphics settings.
- Character movement, jumping, wall traversal/mantling, rooftop web attachment, swinging and momentum-preserving release.
- Melee combat, web shots, enemy pursuit, health and dodge/impact responses.

## Status and limitations

This is an evolving playable prototype, **not a finished production game**. The city is procedural, character animation and enemy AI are limited, and movement/combat still need extensive feel tuning. Automated Godot tests and Android-emulator checks do not prove real-phone compatibility. Test on physical Android devices before treating any build as stable. See the [native project documentation](godot/README.md) for exact features, controls, tests and known limitations.

Unreal Engine migration was evaluated but no Unreal project or Unreal Android build exists in this repository. The current supported development path is Godot because it can be built and tested with the existing phone-accessible GitHub Actions pipeline.

## Build verification

The native Android workflow runs Godot import, gameplay and rendering tests, Android APK export, emulator install/launch checks and repeated lifecycle checks. CI's temporary-key release-template APK is for verification only and must never be distributed. A public release must use the persistent release signing key described in [`godot/RELEASE_SIGNING.md`](godot/RELEASE_SIGNING.md), and must be independently checked for its actual downloadable APK asset.

## Repository map

- `godot/` — active native Godot Android game.
- `app/` — legacy Android WebView/Three.js prototype; see [legacy documentation](docs/LEGACY_WEBVIEW.md).
- `engine-check/` — earlier engine investigation utilities.
- `docs/UNREAL_MIGRATION.md` — Unreal migration requirements and release gates.
- `.github/workflows/native-android.yml` — native import, gameplay, Android export and emulator verification.
- `ASSET_CREDITS.md` — asset provenance and attribution.

