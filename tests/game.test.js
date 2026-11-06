const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const physics = require('../app/src/main/assets/physics.js');

test('menu, settings, play and pause wire up without browser APIs beyond the documented surface', () => {
  const elements = new Map();
  function el(id) {
    if (!elements.has(id)) {
      const classes = new Set(['dialog','hud','pausePanel','settingsPanel'].includes(id) ? ['hidden'] : []);
      elements.set(id, {id, value:'', checked:false, textContent:'', classList:{add:x=>classes.add(x),remove:x=>classes.delete(x),contains:x=>classes.has(x),toggle:(x,on)=>on?classes.add(x):classes.delete(x)}, addEventListener(){}, setPointerCapture(){}});
    }
    return elements.get(id);
  }
  const store = {};
  const context = {
    document:{getElementById:el, querySelectorAll:()=>[], addEventListener(){}, hidden:false},
    window:{ComicPhysics:physics, addEventListener(){}, innerWidth:1280, innerHeight:720},
    localStorage:{getItem:k=>store[k],setItem:(k,v)=>store[k]=v}, requestAnimationFrame(){}, Math, Number, JSON
  };
  el('world').getContext = () => ({});
  vm.runInNewContext(fs.readFileSync('app/src/main/assets/game.js','utf8'), context);
  el('settingsOpen').onclick();
  assert.equal(el('settingsPanel').classList.contains('hidden'), false);
  el('lighting').onchange({target:{value:'night'}});
  assert.equal(JSON.parse(store['comic-settings']).lighting, 'night');
  el('settingsDone').onclick();
  el('play').onclick();
  assert.equal(el('menu').classList.contains('hidden'), true);
  assert.equal(el('hud').classList.contains('hidden'), false);
  el('pause').onclick();
  assert.equal(el('pausePanel').classList.contains('hidden'), false);
  assert.ok(JSON.parse(store['comic-progress']).x >= 0);
  el('resume').onclick();
  assert.equal(el('dialog').classList.contains('hidden'), true);
});
