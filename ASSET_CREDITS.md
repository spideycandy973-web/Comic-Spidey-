# Model credits and usage status

The user confirmed permission to include and publicly redistribute the supplied Spider-Man, Doctor Octopus, and animation assets. The repository does not independently verify the ownership or chain of rights; this confirmation is not a claim of an official license or endorsement.

- **Spider-Man character and animations:** from the user's `Model/spiderman.zip`. The nested `source/spiderman.zip` contains `stand.fbx`, `run.fbx`, `hanging.fbx`, `jumpUp.fbx`, `jumpDown.fbx` and `braceDrop.fbx`; their metadata identifies Mixamo. The stand file contains a skinned mesh and animation. Run, hanging, jump, fall and landing clips were extracted to Three.js AnimationClip JSON for offline loading. The archive did not include a separate author/license statement; the user supplied permission as above.
- **Doctor Octopus:** from the user's `Model/doctor_octopus_spider-man_2_ps2.glb`. Its embedded metadata attributes the model to [LombaxLover2K](https://sketchfab.com/LombaxLover2K), identifies [the source](https://sketchfab.com/3d-models/doctor-octopus-spider-man-2-ps2-32b278b99a9c400d8f34a46f0e401859) and labels it [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The model is rescaled and positioned for the prototype. The supplied file has no rig; two tentacle meshes receive a gentle procedural vertex deformation at runtime. The body and individual tentacles are not skeletally animated.
- **Three.js and FBX/GLTF loaders:** three.js 0.160.1, MIT; see `app/src/main/assets/vendor/THREE-LICENSE.txt`. `model-loaders.js` bundles the official loaders and their support modules, using the existing global Three.js runtime.

If any supplied asset permission or attribution is incorrect, remove/replace it before distribution. Comic Spidey is not represented as an official or endorsed Marvel/Sony product.
- **Rigged pedestrians:** generated with [Citizen Maker](https://github.com/ghanemja/citizen-maker) by Janelle Ghanem (MIT; license reproduced in `app/src/main/assets/vendor/CITIZEN-MAKER-LICENSE.txt`), using MakeHuman's CC0 base geometry. Two generated dressed human models and their procedural walk clips are cloned across eight pedestrians; their meshes were simplified with glTF Transform and meshoptimizer for reduced rendering cost; simple fallback geometry is used if loading fails.

## Native Godot development project

`godot/assets/hero.glb` is a conversion of the supplied skinned Spider-Man FBX and six supplied Mixamo clips to glTF; the hero texture comes from the same user-supplied archive. `godot/assets/doctor_octopus.glb` is the supplied static Doctor Octopus model, and `godot/assets/citizen*.glb` include the two generated and optimized Citizen Maker characters described above plus two additional generated, rigged variants with walk and run clips. The additional variants were also simplified with glTF Transform and meshoptimizer. Godot Engine is distributed separately under the MIT license: https://godotengine.org/license/. The city remains predominantly procedural. `godot/assets/city/street-light.glb` is an extracted, resized-texture street light from the supplied neighborhood model; the full neighborhood is not used. The user confirmed permission to include and publicly redistribute the neighborhood and civil-service vehicle pack; ownership and license provenance have not been independently verified. The vehicle pack is not currently included.

- **Bangers display font:** The Bangers Project Authors, SIL Open Font License 1.1. Source: https://github.com/google/fonts/tree/main/ofl/bangers. The license is included at `godot/fonts/BANGERS-OFL.txt` and in the native in-game credits.

## Unity prototype

`unity/ComicSpidey/Assets/Resources/Hero/` contains `stand.fbx`, `run.fbx`,
`hanging.fbx` and the suit texture from the user's `spiderman.zip`. The FBX
files contain the supplied rigged model and Mixamo clips. The user confirmed
permission to include and publicly redistribute these character and animation
assets; ownership and the chain of rights have not been independently verified.
The Unity integration is untested and the supplied suit is not a Miles-style
black-and-red model.

- **Unity pedestrian prototype:** `unity/ComicSpidey/Assets/Resources/Citizens/`
  contains FBX conversions of the repository's two generated Citizen Maker/
  MakeHuman GLBs described above. `unity/tools/export_citizens.py` retains rigs
  and animation during Blender conversion. Blender re-import found rigged meshes
  and animation actions in both exports. Three.js 0.160.1's FBXLoader rejects
  an empty eye animation track in the exports; Unity import and actual visual/
  animation behaviour are not yet verified and may also require corrections.
