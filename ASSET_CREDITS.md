# Model credits and usage status

The user confirmed permission to include and publicly redistribute the supplied Spider-Man, Doctor Octopus, and animation assets. The repository does not independently verify the ownership or chain of rights; this confirmation is not a claim of an official license or endorsement.

- **Spider-Man character and animations:** from the user's `Model/spiderman.zip`. The nested `source/spiderman.zip` contains `stand.fbx`, `run.fbx`, and `hanging.fbx`; their metadata identifies Mixamo. The stand file contains a skinned mesh and animation. Run and hanging clips were extracted to Three.js AnimationClip JSON for offline loading. The archive did not include a separate author/license statement; the user supplied permission as above.
- **Doctor Octopus:** from the user's `Model/doctor_octopus_spider-man_2_ps2.glb`. Its embedded metadata attributes the model to [LombaxLover2K](https://sketchfab.com/LombaxLover2K), identifies [the source](https://sketchfab.com/3d-models/doctor-octopus-spider-man-2-ps2-32b278b99a9c400d8f34a46f0e401859) and labels it [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The model is unchanged but rescaled and positioned for the prototype. The file is static: its limbs and tentacles are not independently animated.
- **Three.js and FBX/GLTF loaders:** three.js 0.160.1, MIT; see `app/src/main/assets/vendor/THREE-LICENSE.txt`. `model-loaders.js` bundles the official loaders and their support modules, using the existing global Three.js runtime.

If any supplied asset permission or attribution is incorrect, remove/replace it before distribution. Comic Spidey is not represented as an official or endorsed Marvel/Sony product.
