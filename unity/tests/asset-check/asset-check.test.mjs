import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import * as THREE from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

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
  for (const name of ['stand', 'run', 'hanging']) {
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
