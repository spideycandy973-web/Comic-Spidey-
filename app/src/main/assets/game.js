/* Local WebGL prototype. The simulation lives in physics.js; this file handles presentation and input. */
(() => {
'use strict';
const $=id=>document.getElementById(id), P=window.ComicPhysics;
let renderer;
try { renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'}); }
catch(e){ $('error').classList.remove('hidden'); return; }
renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.outputColorSpace=THREE.SRGBColorSpace;
$('gameView').appendChild(renderer.domElement);
const scene=new THREE.Scene(), camera=new THREE.PerspectiveCamera(65,innerWidth/innerHeight,.1,220);scene.add(camera);
const world=P.createWorld();let player=P.createPlayer(),boss=P.createBoss(0),bossIndex=0,state='menu',previous='menu',view='third',yaw=0,pitch=0,last=0,clock=0,attackCooldown=0,noticeTimer=0;
const input={forward:false,back:false,left:false,right:false,jx:0,jy:0,jump:false,swing:false};
function load(key,fallback){try{return JSON.parse(localStorage.getItem(key))||fallback;}catch(e){return fallback;}}
function save(key,value){try{localStorage.setItem(key,JSON.stringify(value));}catch(e){}}
const settings=Object.assign({lighting:'sunset',assist:true},load('comic3d-settings',{}));
if(!['sunset','day','night'].includes(settings.lighting))settings.lighting='sunset';
const palettes={sunset:{sky:0xe89b88,fog:0xe89b88,ambient:0xffd5bb,sun:0xffe5c8},day:{sky:0x93c7dc,fog:0x93c7dc,ambient:0xe2efff,sun:0xfff4d8},night:{sky:0x222d50,fog:0x222d50,ambient:0x7088c4,sun:0x819ade}};
const ambient=new THREE.HemisphereLight(0xffffff,0x39435b,2);scene.add(ambient);
const sun=new THREE.DirectionalLight(0xffffff,2.1);sun.position.set(-25,60,15);scene.add(sun);
function lighting(){const v=palettes[settings.lighting];scene.background=new THREE.Color(v.sky);scene.fog=new THREE.Fog(v.fog,65,175);ambient.color.setHex(v.ambient);sun.color.setHex(v.sun);ambient.intensity=settings.lighting==='night'?1.15:2;sun.intensity=settings.lighting==='night'?.8:2.1;}
lighting();
const mat=(color)=>new THREE.MeshToonMaterial({color});
const ink=mat(0x101b30),red=mat(0xe84747),navy=mat(0x263a66),white=mat(0xf8f4df),gold=mat(0xffd753),purple=mat(0x6c4abd),steel=mat(0x637889),cyan=mat(0x45e7ef);
function box(parent,w,h,d,m,x,y,z){const o=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),m);o.position.set(x,y,z);parent.add(o);return o;}
function sphere(parent,r,m,x,y,z){const o=new THREE.Mesh(new THREE.SphereGeometry(r,12,8),m);o.position.set(x,y,z);parent.add(o);return o;}
function makeHero(){
 const group=new THREE.Group();
 box(group,.85,1,.48,red,0,1.1,0);box(group,.85,.3,.49,navy,0,.7,0);
 const head=sphere(group,.39,red,0,1.9,0);head.scale.set(1,1.12,.95);
 box(group,.25,.11,.04,white,-.18,1.97,-.36).rotation.z=-.2;box(group,.25,.11,.04,white,.18,1.97,-.36).rotation.z=.2;
 const armL=box(group,.25,.8,.28,red,-.56,1.1,0),armR=box(group,.25,.8,.28,red,.56,1.1,0);
 const legL=box(group,.28,.7,.32,navy,-.23,.36,0),legR=box(group,.28,.7,.32,navy,.23,.36,0);
 box(group,.24,.13,.03,ink,0,1.25,-.255);return {group,armL,armR,legL,legR};
}
function makeBoss(id){
 const g=new THREE.Group(), primary=id==='volt'?purple:steel,accent=id==='volt'?cyan:gold;
 box(g,1.25,1.35,.7,primary,0,1.3,0);box(g,1.3,.25,.75,ink,0,.75,0);sphere(g,.46,primary,0,2.25,0);
 box(g,.55,.12,.04,accent,0,2.29,-.44);box(g,.2,.55,.05,accent,0,1.45,-.37);
 const l=box(g,.4,1,.4,primary,-.85,1.3,0),r=box(g,.4,1,.4,primary,.85,1.3,0);
 box(g,.45,.7,.48,ink,-.35,.35,0);box(g,.45,.7,.48,ink,.35,.35,0);
 if(id==='ironclad'){box(g,.48,.2,.6,gold,-.85,1.8,0);box(g,.48,.2,.6,gold,.85,1.8,0);}
 else{sphere(g,.18,cyan,-.85,.78,0);sphere(g,.18,cyan,.85,.78,0);}
 const ring=new THREE.Mesh(new THREE.RingGeometry(1.3,1.48,32),new THREE.MeshBasicMaterial({color:id==='volt'?0x62f3f5:0xffcb51,side:THREE.DoubleSide,transparent:true,opacity:.9}));ring.rotation.x=-Math.PI/2;ring.position.y=.03;g.add(ring);
 return {group:g,ring,l,r};
}
const hero=makeHero();scene.add(hero.group);let enemy=makeBoss('volt');scene.add(enemy.group);
// First-person forearms are attached to the camera and hidden in third-person view.
const hands=new THREE.Group();camera.add(hands);
box(hands,.18,.18,.65,red,-.32,-.35,-.75).rotation.x=-.3;box(hands,.18,.18,.65,red,.32,-.35,-.75).rotation.x=-.3;hands.visible=false;
// Procedural city meshes and hand-drawn window textures; all assets are original.
const ground=box(scene,160,.3,160,mat(0x45516a),0,-.2,0);
const road=mat(0x30394d),stripe=mat(0xd9c992),pavement=mat(0x7e8996);
box(scene,160,.02,15,road,0,0,0);box(scene,15,.02,160,road,0,.005,0);
for(let i=-70;i<=70;i+=8){box(scene,3,.03,.18,stripe,i,.02,0);box(scene,.18,.03,3,stripe,0,.025,i);}
// An open arena makes the boss encounters readable.
box(scene,24,.05,24,pavement,0,.03,0);
for(let i=-10;i<=10;i+=5){box(scene,.04,.01,24,ink,i,.06,0);box(scene,24,.01,.04,ink,0,.06,i);}
function windowTexture(seed){
 const c=document.createElement('canvas');c.width=256;c.height=256;const x=c.getContext('2d');x.fillStyle=['#54647d','#645c78','#4b6074','#725b6b'][seed%4];x.fillRect(0,0,256,256);
 x.fillStyle='#25324a';for(let y=12;y<256;y+=31)for(let z=12;z<256;z+=27){x.fillRect(z,y,16,20);x.fillStyle=((z+y+seed)%4===0)?'#f3d69a':'#9cb2ba';x.fillRect(z+3,y+3,10,13);x.fillStyle='#25324a';}
 const texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;return texture;
}
const buildingMats=Array.from({length:4},(_,i)=>new THREE.MeshToonMaterial({map:windowTexture(i)}));
world.buildings.forEach((b,i)=>{
 const mesh=box(scene,b.w,b.h,b.d,buildingMats[i%4],b.x,b.h/2,b.z);
 const edges=new THREE.LineSegments(new THREE.EdgesGeometry(mesh.geometry),new THREE.LineBasicMaterial({color:0x273044}));mesh.add(edges);
 box(scene,b.w+.4,.35,b.d+.4,ink,b.x,b.h+.16,b.z);
 box(scene,3,1.1,2.5,mat(0x66738a),b.x-2,b.h+.7,b.z+2);
});
// Simple props at the edge of the central plaza.
for(const x of [-11,11])for(const z of [-11,11]){box(scene,.18,3,.18,ink,x,1.5,z);sphere(scene,.28,gold,x,3,z);}
const webGeom=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(),new THREE.Vector3()]);const web=new THREE.Line(webGeom,new THREE.LineBasicMaterial({color:0xffffff}));web.visible=false;scene.add(web);
function message(text,seconds=3){$('notice').textContent=text;noticeTimer=seconds;$('notice').classList.remove('hidden');}
function clearInput(){Object.assign(input,{forward:false,back:false,left:false,right:false,jx:0,jy:0,jump:false,swing:false});player.rope=null;$('stick').style.transform='translate(0,0)';document.querySelectorAll('.pressed').forEach(x=>x.classList.remove('pressed'));}
function setBoss(index){bossIndex=index;boss=P.createBoss(index);scene.remove(enemy.group);if(boss){enemy=makeBoss(boss.id);scene.add(enemy.group);$('bossHud').classList.remove('hidden');$('bossName').textContent=boss.name;$('bossSubtitle').textContent=boss.subtitle;$('objective').textContent='Defeat '+boss.name;message(boss.name+' HAS ENTERED THE FIGHT!',3);}else{$('bossHud').classList.add('hidden');finish(true);}}
function start(){clearInput();player=P.createPlayer();yaw=0;pitch=0;view='third';attackCooldown=0;state='playing';last=0;camera.position.set(0,4,16);setBoss(0);$('menu').classList.add('hidden');$('dialog').classList.add('hidden');$('hud').classList.remove('hidden');updateView();updateHud();message('MOVE TOWARD VOLT • DRAG TO LOOK',5);}
function showDialog(panel){$('dialog').classList.remove('hidden');['pause','settings','result'].forEach(p=>$(p+'Panel').classList.toggle('hidden',p!==panel));$('lighting').value=settings.lighting;$('assist').checked=!!settings.assist;}
function pause(){if(state!=='playing')return;clearInput();state='paused';previous='paused';showDialog('pause');}
function resume(){state='playing';last=0;$('dialog').classList.add('hidden');}
function menu(){clearInput();state='menu';$('dialog').classList.add('hidden');$('hud').classList.add('hidden');$('menu').classList.remove('hidden');}
function finish(won){clearInput();state='result';$('resultTag').textContent=won?'CITY SAVED':'DOWN BUT NOT OUT';$('resultTitle').textContent=won?'VICTORY!':'DEFEATED';$('resultText').textContent=won?'You defeated both villains in this prototype. The larger game is still in development.':'The villains won this round. Try again and dodge their warning rings.';showDialog('result');}
window.comicGame={pause};$('play').onclick=start;$('retry').onclick=start;$('pause').onclick=pause;$('resume').onclick=resume;$('toMenu').onclick=menu;$('resultMenu').onclick=menu;
$('settingsOpen').onclick=()=>{previous='menu';showDialog('settings');};$('pauseSettings').onclick=()=>{previous='paused';showDialog('settings');};
function closeSettings(){if(previous==='paused')showDialog('pause');else $('dialog').classList.add('hidden');}
$('settingsDone').onclick=closeSettings;$('closeDialog').onclick=()=>{if(!$('settingsPanel').classList.contains('hidden'))closeSettings();else if(state==='paused')resume();else if(state==='result')menu();};
$('lighting').onchange=e=>{settings.lighting=e.target.value;save('comic3d-settings',settings);lighting();};$('assist').onchange=e=>{settings.assist=e.target.checked;save('comic3d-settings',settings);};
function updateView(){hands.visible=view==='first';hero.group.visible=view!=='first';$('camera').innerHTML='◉<small>'+(view==='first'?'1ST':'3RD')+'</small>';$('camera').setAttribute('aria-label',view==='first'?'Switch to third person':'Switch to first person');}
function toggleCamera(){if(state!=='playing')return;view=view==='third'?'first':'third';updateView();message(view==='first'?'FIRST-PERSON CAMERA':'THIRD-PERSON CAMERA',2);}
$('camera').onclick=toggleCamera;
function hit(){if(state!=='playing'||attackCooldown>0)return;attackCooldown=.42;if(P.attack(player,boss)){message('HIT!  •  '+boss.name,1);if(boss.hp<=0){player.health=Math.min(100,player.health+35);setBoss(bossIndex+1);}}else message('GET CLOSER TO ATTACK',1);}
function swingOn(){if(state!=='playing'||input.swing)return;input.swing=true;if(!P.attach(player,world,settings.assist))message('NO ROOFTOP IN RANGE',1.5);}
function swingOff(){input.swing=false;player.rope=null;}
function bindHold(id,down,up=()=>{}){const el=$(id);el.addEventListener('pointerdown',e=>{if(state!=='playing')return;e.preventDefault();el.setPointerCapture(e.pointerId);el.classList.add('pressed');down();});const release=()=>{el.classList.remove('pressed');up();};el.addEventListener('pointerup',release);el.addEventListener('pointercancel',release);el.addEventListener('lostpointercapture',release);}
bindHold('jump',()=>{input.jump=true;});bindHold('swing',swingOn,swingOff);bindHold('attack',hit);
const joy=$('joystick');let joyId=null;
function joyMove(e){const r=joy.getBoundingClientRect(),dx=(e.clientX-(r.left+r.width/2))/(r.width*.38),dy=(e.clientY-(r.top+r.height/2))/(r.height*.38),length=Math.max(1,Math.hypot(dx,dy));input.jx=dx/length;input.jy=dy/length;$('stick').style.transform=`translate(${input.jx*r.width*.28}px,${input.jy*r.height*.28}px)`;}
joy.addEventListener('pointerdown',e=>{if(state!=='playing'||joyId!==null)return;e.preventDefault();joyId=e.pointerId;joy.setPointerCapture(e.pointerId);joyMove(e);});joy.addEventListener('pointermove',e=>{if(e.pointerId===joyId)joyMove(e);});function joyEnd(e){if(e.pointerId!==joyId)return;joyId=null;input.jx=input.jy=0;$('stick').style.transform='translate(0,0)';}joy.addEventListener('pointerup',joyEnd);joy.addEventListener('pointercancel',joyEnd);joy.addEventListener('lostpointercapture',joyEnd);
let lookId=null,lookX=0,lookY=0;const surface=renderer.domElement;
surface.addEventListener('pointerdown',e=>{if(state!=='playing'||lookId!==null)return;lookId=e.pointerId;lookX=e.clientX;lookY=e.clientY;surface.setPointerCapture(e.pointerId);});
surface.addEventListener('pointermove',e=>{if(e.pointerId!==lookId)return;yaw-=(e.clientX-lookX)*.005;pitch=Math.max(-.65,Math.min(.65,pitch-(e.clientY-lookY)*.004));lookX=e.clientX;lookY=e.clientY;});function lookEnd(e){if(e.pointerId===lookId)lookId=null;}surface.addEventListener('pointerup',lookEnd);surface.addEventListener('pointercancel',lookEnd);surface.addEventListener('lostpointercapture',lookEnd);
const keys={w:'forward',ArrowUp:'forward',s:'back',ArrowDown:'back',a:'left',ArrowLeft:'left',d:'right',ArrowRight:'right'};
window.addEventListener('keydown',e=>{const k=keys[e.key]||keys[e.key.toLowerCase()];if(k){e.preventDefault();if(state==='playing')input[k]=true;}if(e.code==='Space'){e.preventDefault();if(state==='playing'&&!e.repeat)input.jump=true;}if(e.key==='Shift'){e.preventDefault();swingOn();}if(e.key.toLowerCase()==='f'&&!e.repeat)hit();if(e.key.toLowerCase()==='c'&&!e.repeat)toggleCamera();if(e.key==='Escape'&&!e.repeat){if(state==='playing')pause();else if(state==='paused'&&!$('pausePanel').classList.contains('hidden'))resume();}});
window.addEventListener('keyup',e=>{const k=keys[e.key]||keys[e.key.toLowerCase()];if(k)input[k]=false;if(e.key==='Shift')swingOff();});
document.addEventListener('visibilitychange',()=>{if(document.hidden)pause();});window.addEventListener('blur',pause);
function updateHud(){ $('playerHealth').textContent=Math.ceil(player.health);$('playerBar').style.width=player.health+'%';if(boss){$('bossBar').style.width=(boss.hp/boss.health*100)+'%';$('bossPhase').textContent=boss.hp<=boss.health/2?'PHASE 2':'PHASE 1';} }
function resize(){camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);}window.addEventListener('resize',resize);
const desired=new THREE.Vector3(),target=new THREE.Vector3();
function frame(now){const dt=last?Math.min((now-last)/1000,1/30):0;last=now;clock+=dt;
 if(state==='playing'){
  const sx=(input.right?1:0)-(input.left?1:0)+input.jx,sz=(input.back?1:0)-(input.forward?1:0)+input.jy;
  const mx=Math.cos(yaw)*sx+Math.sin(yaw)*sz,mz=-Math.sin(yaw)*sx+Math.cos(yaw)*sz;
  P.stepPlayer(player,world,{x:mx,z:mz,jump:input.jump},dt);input.jump=false;P.stepBoss(boss,player,dt);attackCooldown=Math.max(0,attackCooldown-dt);
  if(Math.hypot(mx,mz)>.1)hero.group.rotation.y=Math.atan2(-mx,-mz);
  if(player.health<=0)finish(false);
  if(noticeTimer>0){noticeTimer-=dt;if(noticeTimer<=0)$('notice').classList.add('hidden');}
  updateHud();
 }
 hero.group.position.set(player.x,player.y,player.z);const moving=Math.hypot(player.vx,player.vz)>.8&&player.grounded;hero.legL.rotation.x=moving?Math.sin(clock*9)*.45:0;hero.legR.rotation.x=-hero.legL.rotation.x;hero.armL.rotation.x=-hero.legL.rotation.x;hero.armR.rotation.x=player.rope?-2:hero.legL.rotation.x;
 if(boss){enemy.group.position.set(boss.x,0,boss.z);enemy.group.rotation.y=Math.atan2(boss.x-player.x,boss.z-player.z);enemy.ring.material.color.setHex(boss.state==='windup'?0xff3939:(boss.id==='volt'?0x62f3f5:0xffcb51));enemy.ring.scale.setScalar(boss.state==='windup'?1.2+Math.sin(clock*20)*.15:1);enemy.l.rotation.x=boss.state==='windup'?-1:Math.sin(clock*6)*.12;enemy.r.rotation.x=enemy.l.rotation.x;}
 web.visible=!!player.rope;if(player.rope){web.geometry.setFromPoints([new THREE.Vector3(player.x,player.y+1.4,player.z),new THREE.Vector3(player.rope.x,player.rope.y,player.rope.z)]);}
 if(state==='menu'){camera.position.set(15+Math.sin(clock*.13)*2,8,20);camera.lookAt(0,2,0);hero.group.visible=true;hands.visible=false;}
 else if(view==='first'){camera.position.set(player.x,player.y+1.8,player.z);target.set(player.x-Math.sin(yaw)*Math.cos(pitch)*10,player.y+1.8+Math.sin(pitch)*10,player.z-Math.cos(yaw)*Math.cos(pitch)*10);camera.lookAt(target);}
 else{desired.set(player.x+Math.sin(yaw)*6,player.y+3.5-pitch*4,player.z+Math.cos(yaw)*6);camera.position.lerp(desired,Math.min(1,dt*8));target.set(player.x,player.y+1.4+pitch*3,player.z);camera.lookAt(target);}
 renderer.render(scene,camera);requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
})();
