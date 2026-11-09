import { createCanvas, GlobalFonts } from '@napi-rs/canvas';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';

// Original vector sign artwork, rendered with the included OFL Bangers font.
const repo = process.argv[2] || process.cwd();
const dest = path.join(repo, 'godot/assets/signs');
mkdirSync(dest, { recursive: true });
GlobalFonts.registerFromPath(path.join(repo, 'godot/fonts/Bangers-Regular.ttf'), 'Bangers');
const signs = [
  ['comics', 'COMICS', '#f7cd50', '#d94b4d'],
  ['pizza', 'PIZZA!', '#ec6650', '#ffe5a5'],
  ['bugle', 'DAILY BUGLE', '#f5edcf', '#163b50'],
  ['cafe', 'CAFE', '#59aab1', '#f8de7b'],
];
for (const [file, label, background, accent] of signs) {
  const canvas = createCanvas(512, 192), c = canvas.getContext('2d');
  c.fillStyle = '#171429'; c.fillRect(0, 0, 512, 192);
  c.fillStyle = background; c.fillRect(10, 10, 492, 172);
  c.fillStyle = accent;
  for (let x = -192; x < 600; x += 54) {
    c.beginPath(); c.moveTo(x, 10); c.lineTo(x + 28, 10); c.lineTo(x + 142, 182); c.lineTo(x + 114, 182); c.closePath(); c.globalAlpha = .20; c.fill(); c.globalAlpha = 1;
  }
  c.font = label.length > 8 ? '80px Bangers' : '114px Bangers';
  c.textAlign = 'center'; c.textBaseline = 'middle';
  c.lineJoin = 'round'; c.lineWidth = 12; c.strokeStyle = '#171429'; c.strokeText(label, 256, 99);
  c.fillStyle = '#fff6d9'; c.fillText(label, 256, 99);
  c.fillStyle = '#171429'; c.fillRect(20, 21, 20, 8); c.fillRect(472, 163, 20, 8);
  writeFileSync(path.join(dest, `${file}.png`), canvas.toBuffer('image/png'));
}
