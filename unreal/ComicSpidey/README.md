# Unreal migration scaffold

This is an **untested, incomplete starting point**, not a playable or releasable
replacement for the native Godot game. The Unreal Editor and Android toolchain
are not available in this workspace. Nothing here has been compiled, packaged,
or tested on a phone. The existing Godot project and released APK are retained.

The project targets Unreal Engine 5.7 as an initial development choice; verify the
installed engine version and Android SDK/NDK/JDK requirements before building.
It contains a C++ game module, a default game mode, and a placeholder character
with a third-person camera, keyboard movement and jump. It has no character mesh
or game map; create a test level with ground, lighting and a Player Start in the
editor, save it, and set it as the default map before testing. No Android touch
controls, assets, story, web swinging, combat, AI, save migration, or mobile
performance work has been implemented yet. Input bindings are for a desktop
prototype only.

On a machine with Unreal Engine 5.7, platform support and a C++ toolchain:

1. Generate project files from `ComicSpidey.uproject`, then build the editor target
   using that engine's standard project workflow. Open the project in the editor.
2. Create and save a test level, configure it as the game default map, and verify
   keyboard movement, camera and jumping in Play In Editor.
3. Configure Android using the requirements for the installed engine and build a
   test APK. Profile and validate on real devices before considering any release.

Do not commit Unreal Engine binaries, generated files, signing keys, or Android
SDKs. See `../../docs/UNREAL_MIGRATION.md` for the broader migration and gates.
MCP is optional editor automation: it requires a running compatible editor and
an agent environment explicitly connected to that server. Merely adding an MCP
config file here does not give this session access to an editor elsewhere.
