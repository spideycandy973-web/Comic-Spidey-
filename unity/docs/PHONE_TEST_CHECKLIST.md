# Comic Spidey — Android test checklist

Use this for each **test build**. The current Unity app is an early prototype,
not the requested full game. A check means the person testing actually tried the
item on the listed build/device; it does not mean the feature is finished.
Record failures as “Not working” rather than ticking them.

**Build / commit:** __________  **Phone / Android version:** __________
**Date:** __________  **Graphics / FPS setting:** __________

For each line mark ✅ working, ❌ not working, or ➖ unavailable/not tested.
Add what happened and a screenshot or screen recording if possible.

## Install and stability
- [ ] Installs and opens without a crash.
- [ ] Reopens after closing, locking/unlocking and switching apps.
- [ ] Runs for 10 minutes without a crash, major heat or serious slowdown.

## Phone controls and traversal
- [ ] Correct landscape orientation; buttons/text are readable and don't overlap.
- [ ] Left drag moves; right drag turns the camera; both work at the same time.
- [ ] Run, stop, turn, jump and land without getting stuck or falling through.
- [ ] Web attaches to a visible building, swings with momentum and releases cleanly.
- [ ] Swing continuously between buildings; no web through walls or ground.
- [ ] Climb walls, wall-run and transition to rooftops.
- [ ] Air tricks and appropriate jumping, falling, landing and swinging animations.

## World and comic presentation
- [ ] Peter's correct model and suit render and animate correctly.
- [ ] Supplied city, civilian, vehicle and villain models load with correct textures.
- [ ] Buildings, streets, lights and skyline resemble the supplied comic references.
- [ ] Comic outlines, colours and lighting look right without obscuring gameplay.
- [ ] Traffic and pedestrians move naturally; collisions prevent walking through objects.
- [ ] Explore districts, rooftops and interiors; day/night and weather work.
- [ ] Crime, emergency services, ambient city sounds and random activities work.

## Gameplay, story and saves
- [ ] Light/heavy attacks, combos, dodges and web attacks work.
- [ ] Enemies patrol, pursue, take damage, recover and can be defeated.
- [ ] Each boss has distinct working attacks; civilians react; escort AI follows.
- [ ] Story Mode mission objectives, dialogue and cutscenes work in order.
- [ ] Complete each mission through gameplay, including all 25 main missions.
- [ ] Checkpoints, save/load, mission replay and Free Roam after the ending work.
- [ ] Side missions, collectibles, upgrades and unlockable suits work.

## Graphics and performance
- [ ] Settings save after restarting the app.
- [ ] Graphics quality, textures, shadows, resolution and frame-rate options work.
- [ ] Measure 30/60/120 FPS modes on supported devices; note actual FPS, heat and battery.
- [ ] Check low-end settings on a representative lower-end phone.

**Issues and steps to reproduce:** ______________________________________

## Known results and limitations

- Unity cloud build #3 (`cbaa058`, Unity 2022.3.62f3) built and the user installed
  it on a Redmi Note 13 Pro+ 5G. Screenshots showed the supplied red/blue model,
  plain block buildings, small portrait controls, and an empty-looking view while
  using the web. The user reported that nothing appeared. This does **not** prove
  movement, physics, animations, performance or other features work correctly.
- Later changes to landscape orientation, control sizing, street markings,
  window textures and experimental swing momentum are **not yet Unity-built or
  phone-tested**. They are not the final city or the full traversal system.
- The current first travel objective is a temporary test, not mission 1 of the
  requested campaign. Combat, full Story and most checklist items are absent.
- 120 FPS is a desired option on capable devices, not a guaranteed result.
  High graphics and high frame rate compete for battery, heat and GPU capacity.
