"""Extract one building's window and wall meshes from the supplied city GLB.

Usage: python3 unity/tools/convert_neighborhood_building.py /path/to/Untitled.glb
Source: source/Untitled.glb in the supplied neighborhood archive. Mesh 20 is
an assembled building, exported as many primitives; group by colour texture so
Unity only needs four renderers (windows split for 16-bit index safety). Plants, billboards, and AC units are omitted
for the prototype's mobile budget. This is not an export of the full city.
"""
import json
import pathlib
import struct
import sys

root = pathlib.Path(__file__).resolve().parents[2]
data = pathlib.Path(sys.argv[1]).read_bytes()
magic, version, size = struct.unpack_from('<4sII', data)
if (magic, version, size) != (b'glTF', 2, len(data)):
    raise ValueError('Expected complete GLB v2')
length, kind = struct.unpack_from('<I4s', data, 12)
if kind != b'JSON':
    raise ValueError('Missing JSON chunk')
model = json.loads(data[20:20 + length])
bin_size, kind = struct.unpack_from('<I4s', data, 20 + length)
if kind != b'BIN\0':
    raise ValueError('Missing BIN chunk')
binary = data[28 + length:28 + length + bin_size]
mesh = next(m for m in model['meshes'] if m.get('name') == '3_Window_0.002')


def read(index, component, width):
    a = model['accessors'][index]
    view = model['bufferViews'][a['bufferView']]
    if a['componentType'] != component or view['buffer'] != 0 or a.get('sparse'):
        raise ValueError('Unexpected accessor format')
    code = {5126: 'f', 5123: 'H'}[component] * width
    step = view.get('byteStride', struct.calcsize('<' + code))
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    end = start + (a['count'] - 1) * step + struct.calcsize('<' + code)
    if end > len(binary) or end > view.get('byteOffset', 0) + view['byteLength']:
        raise ValueError('Accessor outside buffer view')
    return [struct.unpack_from('<' + code, binary, start + i * step) for i in range(a['count'])]


out = root / 'unity/ComicSpidey/Assets/Resources/City/Building'
out.mkdir(parents=True, exist_ok=True)
for image_index, label, expected_primitives, start, stop in (
        (23, 'windows_a', 51, 0, 25), (23, 'windows_b', 51, 25, 51),
        (26, 'wall_lower', 7, 0, 7), (36, 'wall_upper', 48, 0, 48)):
    chunks = []
    for primitive in mesh['primitives']:
        mat = model['materials'][primitive['material']]
        texture_index = mat['pbrMetallicRoughness']['baseColorTexture']['index']
        if model['textures'][texture_index]['source'] == image_index:
            chunks.append(primitive)
    if len(chunks) != expected_primitives:
        raise ValueError(f'{label}: unexpected source primitive count')
    chunks = chunks[start:stop]
    lines = [f'# Supplied neighborhood building {label}; see ASSET_CREDITS.md', f'o {label}']
    count = 0
    faces = []
    for p in chunks:
        if p.get('mode', 4) != 4:
            raise ValueError('Expected triangles')
        a = p['attributes']
        positions = read(a['POSITION'], 5126, 3)
        normals = read(a['NORMAL'], 5126, 3)
        uvs = read(a['TEXCOORD_0'], 5126, 2)
        indices = [x[0] for x in read(p['indices'], 5123, 1)]
        if not len(positions) == len(normals) == len(uvs) or len(indices) % 3:
            raise ValueError('Invalid primitive')
        # The building mesh is Z-up; swap Y/Z and reverse winding.
        lines += [f'v {x:.7g} {z:.7g} {y:.7g}' for x, y, z in positions]
        lines += [f'vt {u:.7g} {1-v:.7g}' for u, v in uvs]
        lines += [f'vn {x:.7g} {z:.7g} {y:.7g}' for x, y, z in normals]
        for i in range(0, len(indices), 3):
            face = (indices[i], indices[i + 2], indices[i + 1])
            if any(v >= len(positions) for v in face):
                raise ValueError('Invalid face index')
            face = [v + count + 1 for v in face]
            faces.append('f ' + ' '.join(f'{v}/{v}/{v}' for v in face))
        count += len(positions)
    lines.extend(faces)
    (out / f'{label}.obj').write_text('\n'.join(lines) + '\n')
    image = model['images'][image_index]
    if image['mimeType'] != 'image/jpeg':
        raise ValueError('Unexpected image format')
    view = model['bufferViews'][image['bufferView']]
    offset = view.get('byteOffset', 0)
    jpeg = binary[offset:offset + view['byteLength']]
    if not jpeg.startswith(b'\xff\xd8\xff'):
        raise ValueError('Invalid JPEG')
    texture_name = 'windows' if image_index == 23 else label
    (out / f'{texture_name}.jpg').write_bytes(jpeg)
    print(f'{label}: {count} vertices, {len(faces)} triangles, {len(chunks)} source primitives')
