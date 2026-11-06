/* Comic Spidey: an original, local-only traversal prototype. */
(() => {
  'use strict';
  const P = window.ComicPhysics, canvas = document.getElementById('world'), ctx = canvas.getContext('2d');
  const $ = id => document.getElementById(id);
  const world = P.createWorld();
  const pages = Array.from({length: 12}, (_, i) => { const b = world.buildings[2 + i * 4]; return {x:b.x+b.w/2, y:b.y-48}; });
  const defaults = {lighting:'sunset', assist:true};
  function load(key, fallback) { try { return JSON.parse(localStorage.getItem(key)) || fallback; } catch (_) { return fallback; } }
  function save(key, value) { try { localStorage.setItem(key, JSON.stringify(value)); } catch (_) {} }
  const settings = Object.assign({}, defaults, load('comic-settings', {}));
  if (!['sunset','day','night'].includes(settings.lighting)) settings.lighting = 'sunset';
  let state = 'menu', previous = 'menu', player = P.createPlayer(), collected = [], cameraX = 0, last = 0, t = 0;
  const input = {left:false,right:false,jump:false,swing:false};
  function resetInput() { input.left = input.right = input.jump = input.swing = false; player.rope = null; document.querySelectorAll('.pressed').forEach(el => el.classList.remove('pressed')); }
  function saveProgress() { save('comic-progress', {x:player.x, y:player.y, collected}); }
  function start() {
    const progress = load('comic-progress', null);
    player = P.createPlayer(); collected = [];
    if (progress && Number.isFinite(progress.x) && Number.isFinite(progress.y)) {
      player.x = Math.max(14, Math.min(world.width-14, progress.x)); player.y = Math.max(-1000, Math.min(world.floor-14, progress.y));
      collected = Array.isArray(progress.collected) ? progress.collected.filter(i => Number.isInteger(i) && i >= 0 && i < pages.length) : [];
    }
    cameraX = Math.max(0, player.x - 260); state = 'playing'; last = 0;
    $('menu').classList.add('hidden'); $('dialog').classList.add('hidden'); $('hud').classList.remove('hidden'); updateCount();
  }
  function updateCount() { $('count').textContent = `${collected.length} / ${pages.length}`; }
  function showDialog(panel) {
    $('dialog').classList.remove('hidden'); $('pausePanel').classList.toggle('hidden', panel !== 'pause'); $('settingsPanel').classList.toggle('hidden', panel !== 'settings');
    $('lighting').value = settings.lighting; $('assist').checked = !!settings.assist;
  }
  function pause() { if (state !== 'playing') return; resetInput(); saveProgress(); state = 'paused'; previous = 'paused'; showDialog('pause'); }
  function resume() { state = 'playing'; last = 0; $('dialog').classList.add('hidden'); }
  window.comicGame = {pause};
  $('play').onclick = start; $('pause').onclick = pause; $('resume').onclick = resume;
  $('settingsOpen').onclick = () => { previous = 'menu'; showDialog('settings'); };
  $('pauseSettings').onclick = () => { previous = 'paused'; showDialog('settings'); };
  function closeDialog() { if (previous === 'paused') showDialog('pause'); else $('dialog').classList.add('hidden'); }
  $('closeDialog').onclick = () => { if (!$('settingsPanel').classList.contains('hidden')) closeDialog(); else resume(); };
  $('settingsDone').onclick = closeDialog;
  $('toMenu').onclick = () => { saveProgress(); resetInput(); state='menu'; $('dialog').classList.add('hidden'); $('hud').classList.add('hidden'); $('menu').classList.remove('hidden'); };
  $('lighting').onchange = e => { settings.lighting = e.target.value; save('comic-settings', settings); };
  $('assist').onchange = e => { settings.assist = e.target.checked; save('comic-settings', settings); };
  function swingOn() { if (state === 'playing' && !input.swing) { input.swing = true; P.attach(player, world, settings.assist); } }
  function swingOff() { input.swing = false; player.rope = null; }
  function bindHold(id, down, up) {
    const el = $(id);
    el.addEventListener('pointerdown', e => { if (state !== 'playing') return; e.preventDefault(); el.setPointerCapture(e.pointerId); el.classList.add('pressed'); down(); });
    const release = e => { e.preventDefault(); el.classList.remove('pressed'); up(); };
    el.addEventListener('pointerup', release); el.addEventListener('pointercancel', release); el.addEventListener('lostpointercapture', release);
  }
  bindHold('left', () => input.left=true, () => input.left=false);
  bindHold('right', () => input.right=true, () => input.right=false);
  bindHold('jump', () => input.jump=true, () => {});
  bindHold('swing', swingOn, swingOff);
  const keymap = {ArrowLeft:'left',a:'left',A:'left',ArrowRight:'right',d:'right',D:'right'};
  window.addEventListener('keydown', e => {
    if (keymap[e.key]) { e.preventDefault(); if (state === 'playing') input[keymap[e.key]]=true; }
    if (e.code === 'Space') { e.preventDefault(); if (state === 'playing' && !e.repeat) input.jump=true; }
    if (e.key === 'Shift') { e.preventDefault(); swingOn(); }
    if (e.key === 'Escape' && !e.repeat) { if (state === 'playing') pause(); else if (state === 'paused' && !$('pausePanel').classList.contains('hidden')) resume(); }
  });
  window.addEventListener('keyup', e => { if (keymap[e.key]) input[keymap[e.key]]=false; if (e.key === 'Shift') swingOff(); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
  window.addEventListener('blur', () => { if (state === 'playing') pause(); });
  function rect(x,y,w,h,color) { ctx.fillStyle=color; ctx.fillRect(x,y,w,h); }
  function line(x1,y1,x2,y2,color,width=1) { ctx.strokeStyle=color;ctx.lineWidth=width;ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke(); }
  function poly(points,color,stroke='#101528',width=3) {ctx.beginPath();ctx.moveTo(points[0][0],points[0][1]);for(let i=1;i<points.length;i++)ctx.lineTo(points[i][0],points[i][1]);ctx.closePath();ctx.fillStyle=color;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=width;ctx.stroke();}}
  const palettes = {
    sunset: {top:'#64547f',bottom:'#f2a18a',sun:'#ffd49a',back:'#967d91',mid:'#665d78',front:'#343e59',window:'#ffdca6'},
    day: {top:'#60a4cb',bottom:'#c6e0d5',sun:'#fff0be',back:'#8eb5c0',mid:'#7893a5',front:'#415c72',window:'#c8e5e5'},
    night: {top:'#101b3b',bottom:'#4e547f',sun:'#f5e7ba',back:'#353c5d',mid:'#28314f',front:'#1e2941',window:'#ffcf73'}
  };
  function drawCity(w,h,cam,scale) {
    const pal=palettes[settings.lighting], sky=ctx.createLinearGradient(0,0,0,h);sky.addColorStop(0,pal.top);sky.addColorStop(1,pal.bottom);rect(0,0,w,h,sky);
    // Sun and restrained halftone-style rays.
    const sunX=w*.73, sunY=h*.25, sunR=Math.min(w,h)*.18;
    ctx.beginPath();ctx.arc(sunX,sunY,sunR,0,Math.PI*2);ctx.fillStyle=pal.sun;ctx.globalAlpha=.75;ctx.fill();ctx.globalAlpha=1;
    ctx.strokeStyle='#fff';ctx.globalAlpha=.13;ctx.lineWidth=1;for(let i=0;i<15;i++){const a=i*Math.PI*2/15;line(sunX+Math.cos(a)*sunR*1.1,sunY+Math.sin(a)*sunR*1.1,sunX+Math.cos(a)*sunR*1.7,sunY+Math.sin(a)*sunR*1.7,'#fff',1);}ctx.globalAlpha=1;
    // Parallax silhouettes, independently offset from gameplay geometry.
    for(let layer=0;layer<2;layer++){
      let unit=layer?105:75, shift=(cam*scale*(layer?.38:.15))%unit;
      for(let i=-2;i<Math.ceil(w/unit)+2;i++){
        let n=i+Math.floor(cam*scale*(layer?.38:.15)/unit); let height=(layer?130:190)+Math.abs((n*67+23)%110);
        let x=i*unit-shift, y=h*.79-height*scale;
        rect(x,y,unit-3,h-y,layer?pal.mid:pal.back);
        rect(x+unit*.15,y-8*scale,unit*.7,8*scale,layer?pal.mid:pal.back);
        if(layer) {ctx.globalAlpha=.28;for(let wy=y+20*scale;wy<h*.8;wy+=24*scale)for(let wx=x+15*scale;wx<x+unit-10;wx+=22*scale)rect(wx,wy,5*scale,9*scale,pal.window);ctx.globalAlpha=1;}
      }
    }
    // World origin is at the left of the camera; ground always sits near the bottom.
    ctx.save(); ctx.translate(-cam*scale, h-110*scale-610*scale);ctx.scale(scale,scale);
    rect(cam-30,610,w/scale+60,150,'#202b40');rect(cam-30,610,w/scale+60,8,'#12192b');
    for(const [i,b] of world.buildings.entries()){
      if(b.x+b.w<cam-40||b.x>cam+w/scale+40)continue;
      rect(b.x+7,b.y+8,b.w,b.h,'#19243b');rect(b.x,b.y,b.w,b.h,pal.front);
      rect(b.x,b.y,b.w,9,'#1b2438');rect(b.x-5,b.y-7,b.w+10,8,'#172034');
      rect(b.x+b.w-14,b.y+9,10,b.h-9,'#243047');
      for(let wy=b.y+24;wy<610;wy+=35) for(let wx=b.x+17;wx<b.x+b.w-20;wx+=32){rect(wx,wy,14,20,'#202b3c');if((Math.floor(wx+wy+i)%5)!==0){ctx.globalAlpha=settings.lighting==='night'?.85:.34;rect(wx+2,wy+2,10,15,pal.window);ctx.globalAlpha=1;}}
      if(i%3===0){rect(b.x+28,b.y-20,35,13,'#27354b');rect(b.x+33,b.y-27,25,7,'#27354b');}
    }
    if(state==='playing'||state==='paused'){
      pages.forEach((page,i)=>{if(collected.includes(i))return;ctx.save();ctx.translate(page.x,page.y+Math.sin(t*3+i)*4);ctx.rotate(-.15);rect(-10,-13,20,26,'#f6c939');rect(-7,-10,14,20,'#fff8dd');line(-4,-5,4,-5,'#f04c49',2);line(-4,0,4,0,'#293b59',1);line(-4,4,3,4,'#293b59',1);ctx.restore();});
      if(player.rope){line(player.x,player.y,player.rope.x,player.rope.y,'#f9f7df',2);ctx.beginPath();ctx.arc(player.rope.x,player.rope.y,4,0,Math.PI*2);ctx.fillStyle='#fff';ctx.fill();}
      drawHero(player.x,player.y,1, player.rope ? -.35 : Math.max(-.2,Math.min(.2,player.vx/1500)));
    }
    ctx.restore();
  }
  function drawHero(x,y,s,angle) {
    ctx.save();ctx.translate(x,y);ctx.rotate(angle);ctx.scale(s,s);
    // Bold original red-and-navy silhouette with inked edges, not licensed artwork.
    ctx.lineCap='round';ctx.lineJoin='round';
    line(-4,12,-12,27,'#11172c',10);line(5,12,13,27,'#11172c',10);line(-4,12,-12,27,'#d93d40',6);line(5,12,13,27,'#d93d40',6);
    line(-8,-2,-18,12,'#11172c',9);line(8,-2,18,8,'#11172c',9);line(-8,-2,-18,12,'#e94b49',5);line(8,-2,18,8,'#e94b49',5);
    poly([[-9,-9],[9,-9],[8,13],[0,17],[-8,13]],'#e94b49');poly([[-8,2],[-2,4],[0,16],[-8,13]],'#273b62',null);poly([[8,2],[2,4],[0,16],[8,13]],'#273b62',null);
    ctx.beginPath();ctx.ellipse(0,-18,10,12,0,0,Math.PI*2);ctx.fillStyle='#ed514b';ctx.fill();ctx.strokeStyle='#11172c';ctx.lineWidth=3;ctx.stroke();
    poly([[-8,-21],[-2,-19],[-4,-15],[-7,-16]],'#fdf6e4','#11172c',1);poly([[8,-21],[2,-19],[4,-15],[7,-16]],'#fdf6e4','#11172c',1);
    ctx.restore();
  }
  function render() {
    const dpr=Math.min(window.devicePixelRatio||1,2), w=window.innerWidth,h=window.innerHeight;
    if(canvas.width!==Math.round(w*dpr)||canvas.height!==Math.round(h*dpr)){canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);}
    ctx.setTransform(dpr,0,0,dpr,0,0);
    const scale=h/720; const cam=state==='menu'?270:cameraX;
    drawCity(w,h,cam,scale);
    if(state==='menu'){
      // Oversized original comic figure gives the cover its focal point.
      ctx.save();ctx.translate(w*.69,h*.60);ctx.rotate(-.25);drawHero(0,0,Math.min(h/105,5),0);ctx.restore();
      line(w*.70,h*.29,w*.92,0,'#fff8e6',2);
      ctx.save();ctx.translate(w*.55,h*.69);ctx.rotate(-.15);ctx.fillStyle='#ffd74a';ctx.font=`italic 900 ${Math.max(16,h*.04)}px Arial`;ctx.fillText('THWIP!',0,0);ctx.restore();
    }
  }
  function frame(now) {
    const dt=last ? Math.min((now-last)/1000,1/30) : 0;last=now;t+=dt;
    if(state==='playing'){
      P.step(player,world,{move:(input.right?1:0)-(input.left?1:0),jump:input.jump},dt);input.jump=false;
      pages.forEach((page,i)=>{if(!collected.includes(i)&&Math.hypot(player.x-page.x,player.y-page.y)<28){collected.push(i);updateCount();saveProgress();}});
      const viewWidth=window.innerWidth/(window.innerHeight/720);const target=Math.max(0,Math.min(world.width-viewWidth,player.x-viewWidth*.38));cameraX+=(target-cameraX)*Math.min(1,dt*4);
    }
    render();requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();
