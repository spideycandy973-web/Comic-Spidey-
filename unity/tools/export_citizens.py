"""Convert the repository's generated, rigged citizen GLBs to Unity FBX.

Run with Blender's Python (bpy 4.2); the output is verified by re-importing it.
This retains skeletons and the active walk clip. The generated people and their
licenses are documented in ASSET_CREDITS.md. Unity import/device testing is still
required; this is not a gameplay or visual test.
"""
from pathlib import Path
import sys
import bpy

root = Path(__file__).resolve().parents[2]
out = root / 'unity/ComicSpidey/Assets/Resources/Citizens'
out.mkdir(parents=True, exist_ok=True)
for name in ('citizen', 'citizen2'):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source = root / 'godot/assets' / (name + '.glb')
    bpy.ops.import_scene.gltf(filepath=str(source))
    armatures = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE']
    meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
    if not armatures or not meshes or not bpy.data.actions:
        raise SystemExit(f'{name}: input does not contain expected mesh, rig, and walk action')
    print(f'{name} imported: {len(armatures)} armatures, {len(meshes)} meshes, '
          f'{len(bpy.data.actions)} actions', flush=True)
    target = out / (name + '.fbx')
    bpy.ops.export_scene.fbx(filepath=str(target), object_types={'ARMATURE', 'MESH'},
        axis_forward='-Z', axis_up='Y', add_leaf_bones=False,
        bake_anim=True, bake_anim_use_all_actions=False,
        bake_anim_use_nla_strips=False, bake_anim_force_startend_keying=True,
        path_mode='AUTO')
    # Re-import to catch empty or unrigged exports, without claiming Unity works.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(target), use_anim=True)
    rig_count = sum(obj.type == 'ARMATURE' for obj in bpy.data.objects)
    skinned = sum(obj.type == 'MESH' and any(mod.type == 'ARMATURE' for mod in obj.modifiers)
                  for obj in bpy.data.objects)
    animated = sum(len(action.fcurves) > 0 for action in bpy.data.actions)
    if not rig_count or not skinned or not animated:
        raise SystemExit(f'{name}: FBX verification failed: rigs={rig_count}, skinned={skinned}, actions={animated}')
    print(f'{name} verified FBX: {target.stat().st_size} bytes, '
          f'rigs={rig_count}, skinned meshes={skinned}, animated actions={animated}', flush=True)
