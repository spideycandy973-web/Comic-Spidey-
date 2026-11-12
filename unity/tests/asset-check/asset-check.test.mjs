import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import * as THREE from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

// These checks inspect the supplied FBXs without a Unity editor. They do not
// validate Unity's FBX importer, rig rendering, animation or Android builds.
globalThis.window = { URL: { createObjectURL: () => '' } };
THREE.TextureLoader.prototype.load = () => new THREE.Texture();
const asset = path => new URL(`../../ComicSpidey/Assets/Resources/Hero/${path}`, import.meta.url);
function loadFbx(name) {
  const bytes = readFileSync(asset(`${name}.fbx`));
  return new FBXLoader().parse(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), '');
}
test('hero FBX files contain compatible skeletons, skinned mesh and clips', () => {
  let original;
  for (const name of ['stand', 'run', 'hanging', 'jumpUp', 'jumpDown', 'braceDrop']) {
    const scene = loadFbx(name);
    let mesh;
    scene.traverse(node => { if (node.isSkinnedMesh) mesh = node; });
    assert.ok(mesh, `${name} has a skinned mesh`);
    assert.ok(mesh.geometry.attributes.position.count > 1000, `${name} has geometry`);
    assert.ok(mesh.geometry.attributes.skinIndex && mesh.geometry.attributes.skinWeight, `${name} has skin weights`);
    assert.ok(scene.animations.length && scene.animations[0].tracks.length > 10, `${name} has animation`);
    const bones = mesh.skeleton.bones.map(bone => bone.name).sort();
    if (original) assert.deepEqual(bones, original, `${name} bone names match stand`);
    else original = bones;
  }
});
test('suit texture is a PNG and the Unity resource shader exists', () => {
  const png = readFileSync(asset('hero_diffuse.png'));
  assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  assert.ok(png.readUInt32BE(16) > 0 && png.readUInt32BE(20) > 0);
  assert.match(readFileSync(asset('HeroLit.shader'), 'utf8'), /ComicSpidey\/HeroLit/);
});

test('Unity manifest does not request a nonexistent legacy-input package', () => {
  const manifest = JSON.parse(readFileSync(new URL('../../ComicSpidey/Packages/manifest.json', import.meta.url), 'utf8'));
  assert.equal(Object.hasOwn(manifest.dependencies, 'com.unity.modules.inputlegacy'), false);
});

// Conversion is checked structurally here; Unity import, UV orientation,
// appearance, scale and collision still need editor/device verification.
test('supplied street light OBJ and base-colour PNG are structurally present', () => {
  const city = path => new URL(`../../ComicSpidey/Assets/Resources/City/${path}`, import.meta.url);
  const obj = readFileSync(city('street-light.obj'), 'utf8');
  assert.equal((obj.match(/^v /gm) || []).length, 1110);
  assert.equal((obj.match(/^vt /gm) || []).length, 1110);
  assert.equal((obj.match(/^vn /gm) || []).length, 1110);
  assert.equal((obj.match(/^f /gm) || []).length, 1082);
  assert.equal(readFileSync(city('street-light.png')).subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
});

test('prototype comic shader keeps the textured material and quantized lighting', () => {
  const shader = readFileSync(asset('HeroLit.shader'), 'utf8');
  assert.match(shader, /#pragma surface surf Comic/);
  assert.match(shader, /LightingComic/);
  assert.match(shader, /tex2D\(_MainTex/);
  assert.match(shader, /dotPattern/);
});

// The source GLBs have rigged meshes and walk animation. Blender re-import
// separately verified their generated FBX files; Unity import and playback are
// not verified here. Three.js FBXLoader 0.160.1 rejects an empty eye track in
// these Blender exports, so binary/header checks cannot replace a Unity test.
test('citizen sources contain rigs and walk clips; converted FBX files exist', async () => {
  for (const name of ['citizen', 'citizen2']) {
    const glb = readFileSync(new URL(`../../../godot/assets/${name}.glb`, import.meta.url));
    const source = await new Promise((resolve, reject) => new GLTFLoader().parse(
      glb.buffer.slice(glb.byteOffset, glb.byteOffset + glb.byteLength), '', resolve, reject));
    let skinCount = 0;
    source.scene.traverse(node => { if (node.isSkinnedMesh) skinCount++; });
    assert.ok(skinCount > 0, `${name} has skinned meshes`);
    assert.ok(source.animations.some(clip => clip.tracks.length > 0 && clip.duration > 0), `${name} has animation`);
    const fbx = readFileSync(new URL(`../../ComicSpidey/Assets/Resources/Citizens/${name}.fbx`, import.meta.url));
    assert.equal(fbx.subarray(0, 20).toString('ascii'), 'Kaydara FBX Binary  ');
    assert.ok(fbx.length > 100000, `${name} converted FBX is nonempty`);
  }
});

test('neighborhood road conversion contains expected mesh and JPEG', () => {
  const road = path => new URL(`../../ComicSpidey/Assets/Resources/City/${path}`, import.meta.url);
  const obj = readFileSync(road('road_strip.obj'), 'utf8');
  assert.equal((obj.match(/^v /gm) || []).length, 138);
  assert.equal((obj.match(/^vt /gm) || []).length, 138);
  assert.equal((obj.match(/^vn /gm) || []).length, 138);
  assert.equal((obj.match(/^f /gm) || []).length, 72);
  assert.equal(readFileSync(road('road_strip.jpg')).subarray(0, 3).toString('hex'), 'ffd8ff');
});
