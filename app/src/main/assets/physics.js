/* Standalone, deterministic side-view movement model. Coordinates are in world pixels. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.ComicPhysics = factory();
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const GRAVITY = 1250, SPEED = 360, RADIUS = 14;
  function buildings() {
    const result = [];
    // Fixed seed-like pattern makes rooftops and web anchors predictable across sessions.
    for (let i = 0; i < 90; i++) {
      const x = i * 230 - 180;
      const h = 125 + ((i * 73 + 45) % 210);
      result.push({x, y: 610 - h, w: 185 + ((i * 17) % 30), h});
    }
    return result;
  }
  function createWorld() { return {buildings: buildings(), width: 20450, floor: 610}; }
  function createPlayer() { return {x: 110, y: 250, vx: 0, vy: 0, grounded: false, rope: null}; }
  function attach(p, world, assist) {
    let best = null, bestDist = Infinity;
    for (const b of world.buildings) {
      const ax = b.x + b.w / 2, ay = b.y - 20;
      const d = Math.hypot(ax - p.x, ay - p.y);
      if (ay < p.y - 10 && d < (assist ? 430 : 310) && d < bestDist) {
        best = {x: ax, y: ay, length: Math.max(65, d)}; bestDist = d;
      }
    }
    p.rope = best;
    return !!best;
  }
  function step(p, world, input, dt) {
    dt = Math.max(0, Math.min(dt, 1 / 30));
    const direction = Math.max(-1, Math.min(1, input.move || 0));
    const wasGrounded = p.grounded;
    p.vx += direction * (p.rope ? 650 : 1050) * dt;
    if (!direction && wasGrounded) p.vx *= Math.pow(0.002, dt);
    p.vx = Math.max(-SPEED * 1.8, Math.min(SPEED * 1.8, p.vx));
    if (input.jump && wasGrounded) { p.vy = -530; p.grounded = false; }
    p.vy += GRAVITY * dt;
    const oldBottom = p.y + RADIUS;
    p.x += p.vx * dt; p.y += p.vy * dt;
    if (p.rope) {
      const dx = p.x - p.rope.x, dy = p.y - p.rope.y;
      const dist = Math.hypot(dx, dy) || 1;
      if (dist > p.rope.length) {
        const nx = dx / dist, ny = dy / dist;
        p.x = p.rope.x + nx * p.rope.length;
        p.y = p.rope.y + ny * p.rope.length;
        const radial = p.vx * nx + p.vy * ny;
        if (radial > 0) { p.vx -= radial * nx; p.vy -= radial * ny; }
      }
    }
    p.grounded = false;
    if (p.vy >= 0) {
      let surface = world.floor;
      for (const b of world.buildings) {
        if (p.x + RADIUS > b.x && p.x - RADIUS < b.x + b.w && oldBottom <= b.y + 3 && p.y + RADIUS >= b.y) surface = Math.min(surface, b.y);
      }
      if (p.y + RADIUS >= surface && oldBottom <= surface + 3) { p.y = surface - RADIUS; p.vy = 0; p.grounded = true; }
    }
    p.x = Math.max(RADIUS, Math.min(world.width - RADIUS, p.x));
    // Recovery prevents a missed collision from trapping the player below the world.
    if (p.y > world.floor + 100) { p.y = world.floor - RADIUS; p.vy = 0; p.rope = null; p.grounded = true; }
  }
  return {createWorld, createPlayer, attach, step};
});
