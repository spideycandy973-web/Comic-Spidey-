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

// Validates that the supplied fleet has the meshes and colour maps we select.
// It does not test Unity's importer, appearance, collisions, or performance.
test('supplied vehicle FBX contains all ten test fleet meshes and colour textures', () => {
  const vehicle = name => new URL(`../../ComicSpidey/Assets/Resources/Vehicles/${name}`, import.meta.url);
  const bytes = readFileSync(vehicle('fleet.fbx'));
  const scene = new FBXLoader().parse(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), '');
  const expected = ['ambulance', 'citybus', 'fire_truck', 'garbage_truck', 'police_sedan', 'rdservtruck', 'school_bus', 'taxi', 'towtruck', 'postvan'];
  const meshes = new Map();
  scene.traverse(node => { if (node.isMesh) meshes.set(node.name, node); });
  for (const name of expected) {
    assert.ok(meshes.has(name), `${name} is in the FBX`);
    assert.ok(meshes.get(name).geometry.attributes.position.count > 1000, `${name} has geometry`);
  }
  for (const name of ['ambulance', 'citybus', 'firetruck', 'garbagetruck', 'police', 'servicetruck', 'schoolbus', 'taxi', 'towtruck', 'postvan']) {
    assert.equal(readFileSync(vehicle(`${name}_albedo.png`)).subarray(0, 8).toString('hex'), '89504e470d0a1a0a', `${name} texture`);
  }
});

test('converted static Doctor Octopus parts preserve source geometry and textures', () => {
  const source = readFileSync(new URL('../../../godot/assets/doctor_octopus.glb', import.meta.url));
  const doc = JSON.parse(source.subarray(20, 20 + source.readUInt32LE(12)).toString());
  assert.equal(doc.meshes.length, 3);
  assert.equal((doc.skins || []).length, 0, 'source has no rig');
  for (let i = 0; i < 3; i++) {
    const file = name => new URL(`../../ComicSpidey/Assets/Resources/DoctorOctopus/part_${i}.${name}`, import.meta.url);
    const obj = readFileSync(file('obj'), 'utf8');
    const primitive = doc.meshes[i].primitives[0];
    const count = doc.accessors[primitive.attributes.POSITION].count;
    assert.equal((obj.match(/^v /gm) || []).length, count);
    assert.equal((obj.match(/^vn /gm) || []).length, count);
    assert.equal((obj.match(/^vt /gm) || []).length, count);
    assert.equal((obj.match(/^f /gm) || []).length, doc.accessors[primitive.indices].count / 3);
    assert.equal(readFileSync(file('png')).subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  }
});

test('neighborhood building parts contain valid indexed geometry and colour textures', () => {
  const building = name => new URL(`../../ComicSpidey/Assets/Resources/City/Building/${name}`, import.meta.url);
  const expected = [ ['windows_a', 24047, 13096], ['windows_b', 16895, 10120],
    ['wall_lower', 240, 120], ['wall_upper', 1296, 648] ];
  for (const [name, vertexCount, faceCount] of expected) {
    const lines = readFileSync(building(`${name}.obj`), 'utf8').split('\n');
    let positions = 0, normals = 0, uvs = 0, faces = 0;
    for (const line of lines) {
      const values = line.trim().split(/\s+/);
      if (['v', 'vn', 'vt'].includes(values[0])) {
        const expectedLength = values[0] === 'vt' ? 3 : 4;
        assert.equal(values.length, expectedLength, `${name} ${values[0]} width`);
        assert.ok(values.slice(1).every(v => Number.isFinite(Number(v))), `${name} finite ${values[0]}`);
        if (values[0] === 'v') positions++;
        else if (values[0] === 'vn') normals++;
        else uvs++;
      } else if (values[0] === 'f') {
        assert.equal(values.length, 4, `${name} triangular faces`);
        for (const corner of values.slice(1)) {
          const indices = corner.split('/').map(Number);
          assert.equal(indices.length, 3);
          assert.ok(indices.every(i => Number.isInteger(i) && i >= 1 && i <= vertexCount), `${name} valid face index`);
        }
        faces++;
      }
    }
    assert.deepEqual([positions, normals, uvs, faces], [vertexCount, vertexCount, vertexCount, faceCount]);
    // Even a fully expanded triangle-list importer can use 16-bit indices.
    assert.ok(faceCount * 3 < 65536);
  }
  for (const name of ['windows', 'wall_lower', 'wall_upper'])
    assert.equal(readFileSync(building(`${name}.jpg`)).subarray(0, 3).toString('hex'), 'ffd8ff');
});
