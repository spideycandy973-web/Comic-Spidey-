"""Convert the repository's supplied static Doctor Octopus GLB to three Unity OBJs.

Usage: python3 unity/tools/convert_doctor_octopus.py
The source has no skeleton or animations. The three independently textured
meshes remain static. Blender/Unity import and appearance must still be tested.
"""
import json
import pathlib
import struct

root = pathlib.Path(__file__).resolve().parents[2]
data = (root / 'godot/assets/doctor_octopus.glb').read_bytes()
magic, version, total = struct.unpack_from('<4sII', data)
if (magic, version, total) != (b'glTF', 2, len(data)):
    raise ValueError('Invalid source GLB')
length, kind = struct.unpack_from('<I4s', data, 12)
if kind != b'JSON':
    raise ValueError('Missing GLB JSON')
model = json.loads(data[20:20 + length])
length_bin, kind = struct.unpack_from('<I4s', data, 20 + length)
if kind != b'BIN\0':
    raise ValueError('Missing GLB binary')
binary = data[28 + length:28 + length + length_bin]
# The source root is a 90-degree X rotation, and Unity uses opposite
# handedness: together these give (x,z,y). Reflection reverses winding.
expected_matrix = [1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1]
matrix = model['nodes'][0]['matrix']
if len(matrix) != 16 or any(abs(a-b) > 1e-7 for a, b in zip(matrix, expected_matrix)):
    raise ValueError('Unexpected source scene transform')


def values(index, component, count):
    a = model['accessors'][index]
    v = model['bufferViews'][a['bufferView']]
    code = {5126: 'f', 5125: 'I'}.get(a['componentType'])
    if a['componentType'] != component or v['buffer'] != 0 or a.get('sparse'):
        raise ValueError('Unsupported source accessor')
    stride = v.get('byteStride', struct.calcsize('<' + code * count))
    start = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    end = start + (a['count'] - 1) * stride + struct.calcsize('<' + code * count)
    if end > len(binary) or end > v.get('byteOffset', 0) + v['byteLength']:
        raise ValueError('Accessor exceeds buffer view')
    return [struct.unpack_from('<' + code * count, binary, start + i * stride)
            for i in range(a['count'])]


out = root / 'unity/ComicSpidey/Assets/Resources/DoctorOctopus'
out.mkdir(parents=True, exist_ok=True)
for i, mesh in enumerate(model['meshes']):
    if len(mesh['primitives']) != 1:
        raise ValueError('Unexpected number of submeshes')
    primitive = mesh['primitives'][0]
    if primitive.get('mode', 4) != 4:
        raise ValueError('Expected triangles')
    attr = primitive['attributes']
    pos = values(attr['POSITION'], 5126, 3)
    normal = values(attr['NORMAL'], 5126, 3)
    uv = values(attr['TEXCOORD_0'], 5126, 2)
    index = [v[0] for v in values(primitive['indices'], 5125, 1)]
    if not len(pos) == len(normal) == len(uv) or len(index) % 3:
        raise ValueError('Invalid mesh data')
    lines = ['# Static Doctor Octopus from supplied GLB; see ASSET_CREDITS.md', f'o octopus_part_{i}']
    lines += [f'v {x:.8g} {z:.8g} {y:.8g}' for x, y, z in pos]
    lines += [f'vt {u:.8g} {1-v:.8g}' for u, v in uv]
    lines += [f'vn {x:.8g} {z:.8g} {y:.8g}' for x, y, z in normal]
    for f in range(0, len(index), 3):
        face = [index[f] + 1, index[f+2] + 1, index[f+1] + 1]
        if not all(1 <= n <= len(pos) for n in face):
            raise ValueError('Face index out of range')
        lines.append('f ' + ' '.join(f'{n}/{n}/{n}' for n in face))
    (out / f'part_{i}.obj').write_text('\n'.join(lines) + '\n')
    material = model['materials'][primitive['material']]
    texture = model['textures'][material['pbrMetallicRoughness']['baseColorTexture']['index']]
    image = model['images'][texture['source']]
    if image['mimeType'] != 'image/png':
        raise ValueError('Unexpected texture format')
    view = model['bufferViews'][image['bufferView']]
    start = view.get('byteOffset', 0)
    png = binary[start:start + view['byteLength']]
    if not png.startswith(b'\x89PNG\r\n\x1a\n'):
        raise ValueError('Invalid PNG')
    (out / f'part_{i}.png').write_bytes(png)
    print(f'part {i}: {len(pos)} vertices, {len(index)//3} triangles, texture {len(png)} bytes')
if len(model['meshes']) != 3:
    raise ValueError('Unexpected mesh count')
