# Unity migration: early prototype

This is a new Unity project, **not a finished or released game**. It is pinned to
Unity 2022.3.20f1 (built-in rendering pipeline). The Unity Editor and Android
build tools are not installed in the current workspace. Unity Build Automation
build #3 successfully exported commit `cbaa058`, and the user installed it on a
Redmi Note 13 Pro+ 5G. The user reported that the city looked empty and the UI
was too small; the screenshot showed portrait orientation and placeholder blocks.
Changes after that build still need a new Unity build and device testing.

`Assets/Scenes/Prototype.unity` is an initial scene registered in build settings.
The source now presents **Story Test**, **Free Roam Test**, and **Boss Test**
choices; these are limited test scenarios, not the full campaign or open world.
Free Roam source now includes repeatable, timed crime alerts at a small set of
street sites. Reaching a marker starts an encounter with two placeholder attackers;
completion saves a separate local test-crime counter, and expiry or player
defeat cancels the current encounter. In-progress crimes are not restored after
restart. Settings offers a separately confirmed reset of that counter, without
resetting the story test or graphics preferences. An unrecognized/corrupted
counter is not overwritten automatically. This has not been built or
phone-tested and is not the final crime/progression, civilian-rescue or police
system. Eight floating placeholder test tokens can be picked up in Free Roam,
including on four roofs. The HUD reports the nearest token relative to the camera;
collection flags use a separate versioned local save and a separate confirmed
reset. They have no rewards and are not the final collectible art or progression.
Collection, placement, navigation, saves and resets remain untested in Unity
and on a phone. The prototype contains
no intentional online gameplay dependency, but airplane-mode operation and the
complete offline game still require device testing.
The runtime bootstrap creates a small temporary block city, placeholder capsule,
camera and directional light. It attempts to use the supplied rigged Spider-Man
FBX with its texture and stand, run, hanging, jump, fall and landing clips. These assets were supplied
by the user; redistribution permission was confirmed, but ownership and licensing
have not been independently verified. If the model or texture cannot be loaded,
the capsule remains visible. Build #3 showed the textured red-and-blue hero model on the user's phone, but animation and rig behaviour have not been fully verified. The
requested Peter-led campaign and Miles as a later character are not implemented. The prototype implements basic camera-relative
movement, jumping, multitouch joystick/look areas and an experimental hold-to-web
tether. Desktop controls are WASD, Space, right-mouse drag, E (web), F (attack) and
Left Shift (dodge); tap F for light attacks or hold and release for a heavy.
The prototype fight has light chains, a heavier stun attack and enemy hit stun;
placeholder enemies briefly flash orange before melee strikes and cannot attack
through obstacles. These attacks have no combat animation and are not
Unity/device-tested. A prototype
ground dodge has a cooldown and a short damage
protection window; it currently has no dodge animation and is not Unity-tested.
Source now includes experimental wall climbing and wall jumping, plus building
surface raycasts for web attachment. A collision-checked rooftop mantle has
been added for nearby ledges, and jumping while tethered releases with a limited
upward boost. A failed web attempt briefly shows a message. These are experimental
and untested in Unity or on a phone; the mantle has no dedicated animation.
The tether is not yet a polished or physically validated swinging mechanic. The city remains
primitive geometry; there is no complete Story, combat system, NPC population,
traffic or vehicle AI, final graphics menu, save migration or final UI yet. Source now creates
four experimental pedestrian patrols using converted Citizen Maker character
FBXs (with capsule fallback). Blender re-import verified rigs and animation in
the exports. Three.js FBXLoader 0.160.1 rejects an empty eye animation track;
Unity importing, appearance, animation and patrols remain unverified. A new **untested**
placeholder encounter spawns two capsule attackers after the first temporary
travel objective. A basic attack button, enemy pursuit, health and retry are
implemented in source only; they have not been built or played in Unity. The
prototype stops after this encounter; later legacy Story rules are not connected.
This test encounter is not the user's campaign mission 1. Source now stores a
versioned local checkpoint for the test encounter: reaching it and defeating
each attacker. On reload, surviving attackers return at full health and the
player resumes near the encounter with full health. Settings has a two-tap
reset for this test checkpoint only. This is not the future campaign save
system and has not been verified in Unity or on a device.

The next revision requests landscape orientation on mobile, enlarges text and
touch targets, and adds temporary road markings and window textures. A supplied
neighborhood street-light mesh and base-colour texture have been converted to
OBJ/PNG and placed in the test world. A straight road mesh and colour atlas
from the same pack are converted to OBJ/JPEG and batched into test streets.
Four test blocks now use an extracted neighborhood building's window and wall
meshes with shared textures and approximate box collision; the rest remain
placeholder cubes. Plants, AC units, other material maps and the original city
layout are omitted. Import, appearance, web attachment, collision and mobile
performance have not been verified in Unity. Run
`unity/tools/convert_neighborhood_building.py /path/to/Untitled.glb` to
reproduce the building conversion.
A basic, unsaved 12-minute day/night cycle changes the test sun, ambient
lighting and solid sky colour, pausing with the settings menu. There are no
clouds, stars, weather or final nighttime lighting; the appearance and mobile
cost are untested in Unity and on devices.
The prototype material now uses stepped
lighting and a subtle halftone pattern as a first comic-style experiment, not
the final requested visual style. This shader, the conversion, the approximate
pole collision and the other changes are unverified in Unity and on the phone. They
do not replace the requested full city or art direction. A new prototype
settings panel offers quality, frame-rate targets (30/60/120), shadow toggle and
render scale and stores the choices locally. Actual frame rate is device-limited;
render scaling may be unsupported by a device or rendering backend. None of
these settings have yet been verified in Unity or on the phone. The source GLB and
repeatable conversion tool are `godot/assets/city/street-light.glb` and
`unity/tools/convert_street_light.py` (paths relative to the repository root).
`unity/tools/convert_neighborhood_road.py` reproduces the road conversion from
`source/Untitled.glb` inside the user's neighborhood archive. Road appearance,
orientation, collision and performance still need Unity and phone tests.
The supplied civil-service FBX and base-colour/decal/optics maps are now used
as ten static parked-vehicle previews. They are not traffic or emergencies. The
Unity FBX import, texture slots, scale, alignment and collision are unverified;
the original pack's normal, metalness and opacity maps are not yet used.
The Doctor Octopus GLB was converted into three static OBJ parts and textures.
A separate experimental Boss Test uses a telegraphed area slam, dodge and
attack-in-recovery loop with four increasing-difficulty phases. The model has no
rig or animations. This is not the requested campaign boss battle, does not
implement story or final boss mechanics, and has not been built or phone-tested.
Conversion can be reproduced with `unity/tools/convert_doctor_octopus.py`.

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
option-selection, prototype checkpoint and dodge timing rules without a Unity license.
These tests do not compile or run the Unity scene and cannot validate Android.

Asset checks can also be run with `npm ci && npm test` in
`unity/tests/asset-check`. They inspect FBX skeletons, clips and PNG structure
using Three.js, not Unity; Unity-specific import, shader and animation behaviour
still requires editor and device testing. Unity will generate model and texture
import metadata on first opening this project.

## Campaign and phone test tracking

See [the campaign roadmap](../docs/STORY_AND_ROADMAP.md) and [phone test checklist](../docs/PHONE_TEST_CHECKLIST.md). The 25-mission campaign has not yet been implemented.
