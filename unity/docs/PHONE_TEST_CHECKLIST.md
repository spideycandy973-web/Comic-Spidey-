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
- [ ] Enable airplane mode before launch; start and play without internet.
- [ ] Reopens after closing, locking/unlocking and switching apps.
- [ ] Runs for 10 minutes without a crash, major heat or serious slowdown.

## Phone controls and traversal
- [ ] Correct landscape orientation; buttons/text are readable and don't overlap.
- [ ] Left drag moves; right drag turns the camera; both work at the same time.
- [ ] Run, stop, turn, jump and land without getting stuck or falling through.
- [ ] Web attaches to a visible building, swings with momentum and releases cleanly.
- [ ] Tap jump while tethered: the web releases, horizontal momentum continues,
      and there is an upward boost. Trying to web empty sky should show a notice.
- [ ] Swing continuously between buildings; no web through walls or ground.
- [ ] Climb a tagged wall while holding toward it; the experimental mantle should
      climb onto a nearby roof without clipping. Test wall-jump/cancel, a low
      ceiling and a blocked roof. Wall-running and dedicated mantle animation are
      not implemented; mantle clearance and controls are untested in Unity.
- [ ] Climb walls, wall-run and transition to rooftops.
- [ ] Air tricks and appropriate jumping, falling, landing and swinging animations.
      (Jump/fall/landing clips were added to source but have not been phone-tested.)

## Next test build: temporary modes and encounter only
- [ ] Select Boss Test; the supplied Doctor Octopus model and textures appear.
      Move near him, dodge the red slam warning, attack during recovery, defeat
      all four phases, then check retry after player defeat. He is not animated.
- [ ] Find the eight cyan test tokens on streets and rooftops. Check the nearest
      direction and distance, proximity pickup, no pickup through a wall, and
      that collected tokens stay gone after reopening Free Roam.
- [ ] In Settings, confirm Reset Test Tokens: tokens return; the crime count,
      story checkpoint and graphics options remain unchanged.
- [ ] Select Story Test; the test objective and encounter work.
- [ ] Relaunch and select Free Roam Test; after about 10 seconds, a crime alert
      appears. Check the relative direction and distance to the gold marker;
      reach it and defeat two attackers with tap/hold combat,
      and check the stopped count. Wait for another alert. Ignore an alert to
      check expiry; let attackers defeat the player to check cleanup/retry.
      Close/reopen and check that the stopped count persists; an unfinished crime
      restarts as a new alert rather than resuming. These are prototype crimes.
- [ ] Reset the crime count in Settings (two taps); confirm it becomes zero but
      the story checkpoint and graphics choices stay unchanged. Resetting the
      story checkpoint should likewise leave the crime count unchanged.
- [ ] Return to Story Test on next launch; its checkpoint is unchanged by Free Roam.
- [ ] Check the supplied road strips appear with correct texture and orientation;
      check streets, intersections and player contact for flicker or clipping.
- [ ] Check four supplied-building previews are visible with correctly aligned
      windows and walls; check their approximate collision, rooftop/web anchors,
      and performance. The other blocks remain placeholders.
- [ ] Follow the gold marker and two placeholder attackers appear.
- [ ] Tap ATTACK for light hits; chain three hits, or hold and release ATTACK
      for a heavy hit that briefly stuns an attacker. Release outside the button
      or lose focus to cancel. Try misses, cooldowns and multitouch with movement.
      No combat animations yet; all new input and hit/stun behavior is untested.
- [ ] In Story Test and an active crime, aim the camera toward an attacker and tap
      WEB SHOT. Check the cyan hit indication, interrupted wind-up, temporary
      stun and return to movement. Test obstacles, targets behind the camera,
      misses, the three-charge limit, recharge, pause and retry. The boss is not
      affected. This test effect is not a final projectile or animation.
- [ ] Check crime alert and active-encounter countdowns, and verify the Story Test
      waypoint direction and that its marker hides after arriving or restoring a
      later checkpoint, then reappears after resetting test progress.
- [ ] Attackers flash orange before striking; dodge during the warning and check
      they cannot hit the player through a wall. A hit should interrupt them.
- [ ] Attack button damages a nearby attacker; they pursue and damage the player.
- [ ] Dodge moves in the chosen direction on the ground, briefly avoids damage,
      cannot be spammed, and does not go through walls. No dodge animation yet.
- [ ] Defeat both attackers; the test-encounter completion message appears.
- [ ] Let the player be defeated and check that retry restores player health.
- [ ] Defeat one attacker, close and reopen the app: only the other attacker returns.
- [ ] Defeat both, close and reopen: the test encounter stays complete.
- [ ] In Settings, confirm Reset Test Progress: the test objective starts over;
      graphics settings should remain unchanged.
- [ ] Hold movement into a marked test building to climb; tap jump to wall-jump.
- [ ] Open Settings, change quality, FPS target, shadows and render scale; restart
      the app and check whether the chosen settings persist and take effect.
- [ ] Hold web near a building, check it visibly attaches to a surface and releases.
- [ ] Check four pedestrians appear, retain colours, walk without foot sliding,
      avoid walls and reverse if blocked. Their Unity import is unverified.
- [ ] Find the ten parked test vehicles (police, taxi, ambulance, fire truck,
      buses, garbage, service and tow trucks, post van); check size, colour,
      placement, collisions and phone performance. They do not drive yet.
- [ ] Check the hero and city textures remain visible with the new comic shader;
      check dots and lighting do not shimmer, obscure details or hurt performance.

These are source changes awaiting a Unity build; don't mark them as working
until actually tested on the phone. This is not the full robbery mission.

## World and comic presentation
- [ ] Peter's correct model and suit render and animate correctly.
- [ ] Supplied city, civilian, vehicle and villain models load with correct textures.
- [ ] Buildings, streets, lights and skyline resemble the supplied comic references.
- [ ] Comic outlines, colours and lighting look right without obscuring gameplay.
- [ ] Traffic and pedestrians move naturally; collisions prevent walking through objects.
- [ ] Watch the 12-minute experimental day/night lighting cycle; check readability,
      shadows, transitions and pause/resume. It is not a complete sky or weather.
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
  window textures, experimental swing momentum and a basic placeholder enemy
  encounter, converted supplied street lights, experimental climb/web changes
  graphics settings, test-encounter checkpoint, experimental comic shader and
  converted pedestrian patrols, supplied road batches, test mode selection and
  prototype dodge, static vehicle display, supplied building previews and
  separate Octopus test fight, experimental combat combos, free-roam crime
  encounters, saved test count, placeholder collectible tokens and prototype
  day/night lighting, rooftop mantle, web-jump and web-shot changes are
  **not yet Unity-built or phone-tested**. They are not the final
  city, combat or traversal system.
- The current first travel objective is a temporary test, not mission 1 of the
  requested campaign. Full combat, full Story and most checklist items are absent.
- 120 FPS is a desired option on capable devices, not a guaranteed result.
  High graphics and high frame rate compete for battery, heat and GPU capacity.
