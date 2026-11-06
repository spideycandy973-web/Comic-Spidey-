const {test} = require('node:test');
const assert = require('node:assert/strict');
const P = require('../app/src/main/assets/physics.js');
test('gravity lands the player on a rooftop', () => {
  const world = P.createWorld(), player = P.createPlayer();
  for (let i = 0; i < 180; i++) P.step(player, world, {}, 1/60);
  assert.equal(player.grounded, true);
  assert.ok(player.y < world.floor);
});
test('jump requires ground and moves upward', () => {
  const world = P.createWorld(), player = P.createPlayer();
  for (let i = 0; i < 180; i++) P.step(player, world, {}, 1/60);
  const y = player.y;
  P.step(player, world, {jump: true}, 1/60);
  assert.ok(player.y < y);
});
test('web attachment validates range and holds rope length', () => {
  const world = P.createWorld(), player = P.createPlayer();
  player.x = 100; player.y = 500;
  assert.equal(P.attach(player, world, true), true);
  const rope = player.rope;
  for (let i = 0; i < 120; i++) P.step(player, world, {move: 1}, 1/60);
  assert.ok(Math.hypot(player.x-rope.x, player.y-rope.y) <= rope.length + 0.01);
  player.y = -1000;
  assert.equal(P.attach(player, world, false), false);
  assert.equal(player.rope, null);
});
