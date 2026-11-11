# Unity migration: early prototype

This is a new Unity project, **not a finished or released game**. It is pinned to
Unity 2022.3.20f1 (built-in rendering pipeline). The Unity Editor and Android
build tools are not installed in the current workspace; the project has not
been opened in Unity, compiled, exported, or tested on any device.

`Assets/Scenes/Prototype.unity` is an initial scene registered in build settings.
The runtime bootstrap creates a small temporary block city, placeholder capsule,
camera and directional light. The prototype implements basic camera-relative
movement, jumping, multitouch joystick/look areas and an experimental hold-to-web
tether. Desktop controls are WASD, Space, right-mouse drag and E. The tether is
not yet a polished or physically validated swinging mechanic. The visual assets
are primitives, not the supplied character/city models; there is no Story,
combat, NPC, vehicle, graphics menu, save migration or final UI yet. The first
travel objective can advance to an unimplemented encounter; later Story rules
are present but are not connected to enemies, interactions or an escort.

## Next build and testing steps

1. Provision an appropriately licensed Unity 2022.3.20f1 Editor with Android
   Build Support and the correct SDK/NDK/JDK. A machine or hosted runner must be
   accessible to the agent; an Editor installed elsewhere is not automatically
   available. Unity's licensing and platform requirements must be checked for
   the environment in use; no paid purchase is assumed or required of the user.
2. Open the project and the prototype scene, resolve any import/build errors,
   then run Play Mode tests and actual Android builds. Implement real on-screen
   controls and a responsive layout after measuring on different devices.
3. Port assets and systems incrementally, including animations, collision,
   traversal, Story, interaction and saves; compare against the supplied visual
   references and profile on representative physical phones.
4. The existing APK uses package `com.comicspidey.nativegame`. Any compatible
   update must use that package, a higher version code and the original signing
   certificate described in `../../godot/RELEASE_SIGNING.md`. Do not commit keys
   or passwords, or publish a debug/temporary-key build as an update.

The old Godot and Unreal source trees are retained as references. A change of
engine does not by itself correct logic or guarantee smooth performance.

## Logic-only tests

`dotnet run --project unity/tests/StoryLogic/StoryLogic.csproj --configuration Release`
exercises the engine-independent Story progression rules without a Unity license.
These tests do not compile or run the Unity scene and cannot validate Android.
