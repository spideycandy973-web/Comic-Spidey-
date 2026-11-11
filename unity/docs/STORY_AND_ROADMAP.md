# Comic Spidey: The City That Never Breaks — campaign and roadmap

This is a planning index of the user's story, not a claim of implementation.
The detailed story and dialogue supplied in the conversation remain authoritative.
The main playable hero is **Peter Parker**; Miles is a story character introduced
later. Comic presentation, supplied reference images and compatible supplied
models guide the art. Keep Free Roam and post-story exploration.

## Campaign tracker

No mission below is implemented or tested as the requested full mission. The
existing prototype's unrelated first travel marker is not campaign mission 1.
Each mission needs playable objectives, interactions, dialogue/cinematics,
checkpoints, save/load, failure/retry handling and phone testing.

| # | Act | Mission | Gameplay/story target | Status |
|---|---|---|---|---|
| 1 | I | Another Day in New York | Apartment opening; traversal/combat tutorial, robbery rescue and car pursuit | Not started |
| 2 | I | The Man Behind the Money | Kane's warehouse, weapons fight, encrypted Eclipse data for MJ | Not started |
| 3 | I | Science and Responsibility | Octavius lab, mechanical-arm demonstration and science puzzles | Not started |
| 4 | I | The Blackout | Investigate theft, Electro encounter and civilian rescue | Not started |
| 5 | I | A Dangerous Discovery | MJ decrypts records; investigate Apex Industries | Not started |
| 6 | II | The Underground | Convoy pursuit, underground facility, Rhino escape | Not started |
| 7 | II | The Man in the Mask | Visit Li's community center; meet Miles | Not started |
| 8 | II | Broken Trust | Rescue MJ from Apex warehouse; disagreement about secrecy | Not started |
| 9 | II | The Devil's Project | Infiltrate lab, discover Devil's Core and Li's theft | Not started |
| 10 | II | The Truth About Martin Li | Discover the Shadows, Li's backstory and boss fight | Not started |
| 11 | III | New York Under Attack | Explosions, rescues, emergency response; Miles and his father | Not started |
| 12 | III | The Missing Scientist | Investigate Octavius's disappearance and altered arms | Not started |
| 13 | III | The Six | Prison transport attack; Octavius assembles the Six | Not started |
| 14 | III | The First Hunt | Shocker's vibration fight through city and station | Not started |
| 15 | III | Wings of Destruction | Vulture aerial chase and rooftop fight | Not started |
| 16 | III | The Beast | Rhino industrial fight with civilians and environmental traps | Not started |
| 17 | III | The Scorpion's Poison | Chemical contamination, hallucinations, antidote and Scorpion | Not started |
| 18 | III | Electricity and Fear | Electro at power station; electrical grid crisis | Not started |
| 19 | IV | The Mentor | Octavius confrontation and lab battle | Not started |
| 20 | IV | The Last Hope | Three facilities: stealth, combat, puzzles, rescue and hacking | Not started |
| 21 | IV | The City Remembers | Aunt May conversation; Miles reveals emerging powers | Not started |
| 22 | IV | The Final Six | Infiltrate facility, remaining villains, machine activated | Not started |
| 23 | V | New York's Last Night | Citywide emergency, rescue workers, MJ's discovery | Not started |
| 24 | V | The Final Battle | Four-phase Octavius fight, dialogue and arrest | Not started |
| 25 | V | The Choice | Antidote decision, May's sacrifice and city saved | Not started |

Epilogue: rebuild, May's grave, Miles's invisibility/electricity and spare mask.
Post-credits: Eclipse phase two and an unidentified experimental organism.
Preserve the story's consequences rather than silently changing the ending.

## Development sequence and gates

1. **Playable foundation:** responsive touch and camera, collision, jump, wall
   traversal, momentum swing and a short playable city slice. Profile and test
   each on Android; fix issues before expanding.
2. **Art and world:** audit supplied models, formats and usage rights; import,
   rig, texture and optimize suitable city, hero, civilian and vehicle assets.
   Add comic lighting/ink, districts, traffic, pedestrians, sound and weather.
   Do not treat the current colored boxes as the final city.
3. **Combat and interaction:** health, enemy AI, web attacks, dodge, civilian
   rescue, pursuit and distinct bosses; validate mechanics on devices.
4. **Story systems:** real mission scripting, cutscenes, checkpoints, durable
   saves, replay, Free Roam and the 25 missions above. Build and test in order.
5. **Options and release:** adjustable resolution, textures, shadows, quality
   and target 30/60/120 FPS, with sensible low-end defaults and real device
   measurements. Sign a release correctly, test install/update/relaunch and only
   then publish. 120 FPS, maximum visuals and crash-free operation cannot be
   guaranteed across devices.

The user has approved redistributing the previously identified Spider-Man,
Doctor Octopus and animation assets, neighborhood city model, and civil-service
vehicle pack; ownership and license chains were not independently verified.
Other items in the supplied folder need an asset-by-asset suitability and rights
review before public distribution. Some are unrelated to New York and some are
very large or in formats not directly supported by the current Unity project;
adding everything blindly could harm download size and performance.

Story continuity to resolve during scripting: mission 13 identifies Octavius
as Doctor Octopus, whereas mission 19 describes Peter's later shock at this
revelation and says Octavius helped Doctor Octopus's organization. Preserve
both scenes as planned and confirm the intended reveal before final dialogue.
