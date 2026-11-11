# Unity migration: early prototype

This is a new Unity project, **not a finished or released game**. It is pinned to
Unity 2022.3.20f1 (built-in rendering pipeline). The Unity Editor and Android
build tools are not installed in the current workspace. Unity Build Automation
build #3 successfully exported commit `cbaa058`, and the user installed it on a
Redmi Note 13 Pro+ 5G. The user reported that the city looked empty and the UI
was too small; the screenshot showed portrait orientation and placeholder blocks.
Changes after that build still need a new Unity build and device testing.

`Assets/Scenes/Prototype.unity` is an initial scene registered in build settings.
The runtime bootstrap creates a small temporary block city, placeholder capsule,
camera and directional light. It attempts to use the supplied rigged Spider-Man
FBX with its texture and stand, run and hanging clips. These assets were supplied
by the user; redistribution permission was confirmed, but ownership and licensing
have not been independently verified. If the model or texture cannot be loaded,
the capsule remains visible. Build #3 showed the textured red-and-blue hero model on the user's phone, but animation and rig behaviour have not been fully verified. The
requested Peter-led campaign and Miles as a later character are not implemented. The prototype implements basic camera-relative
movement, jumping, multitouch joystick/look areas and an experimental hold-to-web
tether. Desktop controls are WASD, Space, right-mouse drag, E (web) and F (attack).
Source now includes experimental wall climbing and wall jumping, plus building
surface raycasts for web attachment. These traversal changes are not yet built
or physically tested, and climbing does not yet have a rooftop mantle or its
own animation. The tether is not yet a polished or physically validated
swinging mechanic. The city remains
primitive geometry; there is no complete Story, combat system, NPC population,
vehicle, final graphics menu, save migration or final UI yet. A new **untested**
placeholder encounter spawns two capsule attackers after the first temporary
travel objective. A basic attack button, enemy pursuit, health and retry are
implemented in source only; they have not been built or played in Unity. The
prototype stops after this encounter; later legacy Story rules are not connected.
This test encounter is not the user's campaign mission 1.

The next revision requests landscape orientation on mobile, enlarges text and
touch targets, and adds temporary road markings and window textures. A supplied
neighborhood street-light mesh and base-colour texture have been converted to
OBJ/PNG and placed in the test world. This conversion, the approximate pole
collision and the other changes are unverified in Unity and on the phone. They
do not replace the requested full city or art direction. A new prototype
settings panel offers quality, frame-rate targets (30/60/120), shadow toggle and
render scale and stores the choices locally. Actual frame rate is device-limited;
render scaling may be unsupported by a device or rendering backend. None of
these settings have yet been verified in Unity or on the phone. The source GLB and
repeatable conversion tool are `godot/assets/city/street-light.glb` and
`unity/tools/convert_street_light.py` (paths relative to the repository root).

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
exercises engine-independent Story progression, tether projection, health and
option-selection rules without a Unity license.
These tests do not compile or run the Unity scene and cannot validate Android.

Asset checks can also be run with `npm ci && npm test` in
`unity/tests/asset-check`. They inspect FBX skeletons, clips and PNG structure
using Three.js, not Unity; Unity-specific import, shader and animation behaviour
still requires editor and device testing. Unity will generate model and texture
import metadata on first opening this project.

## Campaign and phone test tracking

See [the campaign roadmap](../docs/STORY_AND_ROADMAP.md) and [phone test checklist](../docs/PHONE_TEST_CHECKLIST.md). The 25-mission campaign has not yet been implemented.
