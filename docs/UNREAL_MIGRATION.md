# Unreal Engine Android migration — earlier assessment

The user has requested a move to Unreal Engine. An uncompiled starter scaffold is now in `unreal/ComicSpidey/`; the Godot project remains available as a reference and existing release, not as a completed Unreal migration.

The requested target is an Unreal Engine native Android game, not the Godot or
WebView builds in this repository. There is an initial Unreal source scaffold,
but no packaged Unreal app or validated Unreal gameplay exists yet. Keep the
older projects as references; do not release them as the requested Unreal game.

## Direction and scope

- Preserve Story and Free Roam, the original city, interactive citizens and
  villains, reliable combat, web swinging, touch controls and local saves.
- Aim for realistic character models, materials and lighting inspired by the
  visual fidelity of eFootball, while retaining a comic-book identity in the
  presentation. Do not copy eFootball assets or branding. Existing supplied
  models can help with development, but the static Doctor Octopus model,
  procedural city and current pedestrians are not equivalent to the requested
  realistic production assets. Secure suitable assets and rights before release.
- Provide graphics settings for resolution scaling/sharpness, texture quality,
  shadows, anti-aliasing and frame-rate targets, with device-appropriate defaults.
  Not every rendering feature or AA technique is available in every mobile
  renderer, on every GPU, or as a runtime toggle; do not promise otherwise.
- Target smooth play on supported devices, using measured frame times, thermal
  endurance and memory budgets. No engine can guarantee zero bugs, no lag or
  identical graphics on all phones. Establish a tested minimum specification and
  device matrix; gracefully reduce quality on less capable devices.

## Setup needed before implementation can be verified

1. Set up a suitable development machine with Unreal Engine 5.7 or newer and
   Android platform support. Choose and pin an exact engine version when the
   build environment is available. Epic recommends 32 GB RAM and a capable GPU
   for Linux development: [Linux requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/linux-development-requirements-for-unreal-engine).
2. For a Windows workstation, install Unreal Engine through Epic Games Launcher.
   For source access, link an Epic Games account to the GitHub account that will
   access Epic's Unreal repository and accept Epic's invitation; see [Epic's
   account and source guidance](https://dev.epicgames.com/documentation/en-us/unreal-engine/onboarding-licensees-in-unreal-engine).
   Do not put account credentials, signing keys or engine binaries in this repo.
3. In Unreal Editor use **Platforms > SDK Management > Android > Install SDK**
   and follow Turnkey; use the SDK/NDK/JDK versions for the exact engine version.
   Set Android packaging and test the installed SDK using Epic's
   [Android Quick Start](https://dev.epicgames.com/documentation/unreal-engine/android-quick-start?lang=en-US)
   and [Android requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/android-development-requirements-for-unreal-engine).
   Recheck store target-SDK rules at release time.
4. Provision a persistent build runner with the installed licensed engine,
   Android toolchain, adequate disk/RAM and access to representative physical
   Android devices. A machine merely installed elsewhere is not automatically
   accessible from this workspace. The current GitHub integration cannot list
   self-hosted runners, so their availability has not been verified. Standard
   hosted runners have limited storage; a suitable larger runner must be arranged
   and verified rather than assumed to be available.

## Migration and release gates

1. Create and build the actual Unreal project in the provisioned environment;
   confirm a native Android package installs and runs. Set up CI without
   redistributing engine files or checking generated build artifacts into Git.
2. Import/retarget the licensed models and animation sources; replace or upgrade
   them where necessary for the desired realism. Design and create the city,
   optimized mobile materials, LODs, lighting, streaming and collision.
3. Reimplement and test movement, swinging, combat, NPC behavior, all Story
   objectives, Free Roam events, UI, accessibility and saves. Godot scripts and
   save data are not directly portable. Decide and test any save migration rather
   than silently implying compatibility.
4. Implement quality settings and capability-based device profiles. Profile
   actual GPU/CPU frame times, shader compilation, loading, memory, battery and
   thermal throttling on low-, mid- and high-tier supported phones. Check touch,
   interruptions, orientation, long sessions and both game modes. Measure 30/60
   fps targets on the device tiers that can sustain them; record results instead
   of claiming universal smoothness.
5. Complete full human playthroughs, resolve release-blocking defects, verify
   asset and character rights, create secure signing and store assets, and only
   then produce and release a signed Android build.

Epic's [mobile anti-aliasing documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/anti-aliasing-and-upscaling-in-unreal-engine)
shows renderer-dependent method support. Epic describes [Lumen on mobile](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-lumen-global-illumination-on-mobile-in-unreal-engine)
as experimental and limited to certain high-end Android configurations; it is
not a universal baseline for this game.
