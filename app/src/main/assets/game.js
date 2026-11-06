/* Local WebGL prototype. The simulation lives in physics.js; this file handles presentation and input. */
(() => {
'use strict';
const $=id=>document.getElementById(id), P=window.ComicPhysics, City=window.ComicCity, Story=window.ComicStory;
let renderer;
try { renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'}); }
catch(e){ $('error').classList.remove('hidden'); return; }
renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.outputColorSpace=THREE.SRGBColorSpace;
$('gameView').appendChild(renderer.domElement);
const scene=new THREE.Scene(), camera=new THREE.PerspectiveCamera(65,innerWidth/innerHeight,.1,220);scene.add(camera);
const world=P.createWorld();let player=P.createPlayer(),boss=P.createBoss(0),bossIndex=0,storyStage=0,mode='story',state='menu',previous='menu',view='third',yaw=0,pitch=0,last=0,clock=0,attackCooldown=0,noticeTimer=0;
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
// A custom spider-themed suit: rounded low-poly anatomy, webbed mask and an original emblem.
function makeHero(){
 const group=new THREE.Group();
 function oval(parent,rx,ry,rz,material,x,y,z){const o=sphere(parent,1,material,x,y,z);o.scale.set(rx,ry,rz);return o;}
 function limb(x,y,material,length,r){const pivot=new THREE.Group();pivot.position.set(x,y,0);group.add(pivot);oval(pivot,r,length/2,r,material,0,-length/2,0);return pivot;}
 oval(group,.47,.62,.29,navy,0,1.15,0);oval(group,.42,.47,.30,red,0,1.27,0);
 oval(group,.37,.24,.27,navy,0,.66,0);oval(group,.22,.18,.19,red,0,1.66,0);
 const canvas=document.createElement('canvas');canvas.width=256;canvas.height=128;const c=canvas.getContext('2d');
 c.fillStyle='#e84442';c.fillRect(0,0,256,128);c.strokeStyle='#592a38';c.lineWidth=1.3;
 for(let x=0;x<=256;x+=16){c.beginPath();c.moveTo(x,0);c.lineTo(x,128);c.stroke();}
 for(let y=18;y<120;y+=16){c.beginPath();for(let x=0;x<=256;x+=8){const yy=y+Math.sin(x*Math.PI/16)*3;if(x===0)c.moveTo(x,yy);else c.lineTo(x,yy);}c.stroke();}
 const tex=new THREE.CanvasTexture(canvas);tex.colorSpace=THREE.SRGBColorSpace;
 oval(group,.37,.43,.34,new THREE.MeshToonMaterial({map:tex}),0,1.99,0);
 // High-contrast angular lenses on the front of the mask.
 function lens(sign){const shape=new THREE.Shape();shape.moveTo(sign*.04,2.07);shape.lineTo(sign*.33,2.17);shape.lineTo(sign*.28,1.98);shape.lineTo(sign*.12,1.94);shape.closePath();const outline=new THREE.Mesh(new THREE.ShapeGeometry(shape),ink);outline.position.z=-.326;outline.rotation.y=Math.PI;outline.scale.x=-1;group.add(outline);const inner=outline.clone();inner.material=white;inner.position.z=-.331;inner.scale.set(-.78,.68,1);inner.position.x=sign*.02;inner.position.y=.66;group.add(inner);}
 lens(-1);lens(1);
 const armL=limb(-.57,1.56,red,.83,.16),armR=limb(.57,1.56,red,.83,.16);
 const legL=limb(-.22,.69,navy,.67,.19),legR=limb(.22,.69,navy,.67,.19);
 oval(legL,.15,.24,.17,red,0,-.52,-.02);oval(legR,.15,.24,.17,red,0,-.52,-.02);
 // Original white angular spider motif on both chest and back.
 function emblem(z){oval(group,.08,.13,.025,white,0,1.28,z);for(let i=0;i<4;i++)for(const sign of [-1,1]){const points=[new THREE.Vector3(sign*.04,1.35-i*.045,z),new THREE.Vector3(sign*.20,1.43-i*.08,z),new THREE.Vector3(sign*.27,1.38-i*.09,z)];group.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:0xf5f0de})));}}
 emblem(-.302);emblem(.302);
 return {group,armL,armR,legL,legR};
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
const ground=box(scene,440,.3,440,mat(0x45516a),0,-.2,0);
const road=mat(0x30394d),stripe=mat(0xd9c992),pavement=mat(0x7e8996);
for(let pos=-160;pos<=160;pos+=80){box(scene,440,.02,15,road,0,0,pos);box(scene,15,.02,440,road,pos,.005,0);}
for(let i=-210;i<=210;i+=8){box(scene,3,.03,.18,stripe,i,.02,0);box(scene,.18,.03,3,stripe,0,.025,i);}
// An open arena makes the boss encounters readable.
box(scene,24,.05,24,pavement,0,.03,0);
for(let i=-10;i<=10;i+=5){box(scene,.04,.01,24,ink,i,.06,0);box(scene,24,.01,.04,ink,0,.06,i);}
function windowTexture(seed){
 const c=document.createElement('canvas');c.width=256;c.height=256;const x=c.getContext('2d');x.fillStyle=['#54647d','#645c78','#4b6074','#725b6b'][seed%4];x.fillRect(0,0,256,256);
 x.fillStyle='#25324a';for(let y=12;y<256;y+=31)for(let z=12;z<256;z+=27){x.fillRect(z,y,16,20);x.fillStyle=((z+y+seed)%4===0)?'#f3d69a':'#9cb2ba';x.fillRect(z+3,y+3,10,13);x.fillStyle='#25324a';}
 const texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;return texture;
}
const buildingMats=Array.from({length:4},(_,i)=>new THREE.MeshToonMaterial({map:windowTexture(i)}));
// Build and unload nearby 80m chunks. Simulation data remains deterministic and lightweight.
const buildingMeshes=[], chunkSources=new Map(), activeChunks=new Map(), chunkSize=80;
const edgeMat=new THREE.LineBasicMaterial({color:0x273044}), roofDetail=mat(0x66738a);
function chunkKey(x,z){return Math.floor((x+chunkSize/2)/chunkSize)+','+Math.floor((z+chunkSize/2)/chunkSize);}
world.buildings.forEach((b,i)=>{const k=chunkKey(b.x,b.z);if(!chunkSources.has(k))chunkSources.set(k,[]);chunkSources.get(k).push({b,i});});
let currentChunk='';
function updateChunks(x,z){
 const key=chunkKey(x,z);if(key===currentChunk)return;currentChunk=key;
 const [cx,cz]=key.split(',').map(Number),desired=new Set();
 for(let dx=-1;dx<=1;dx++)for(let dz=-1;dz<=1;dz++)desired.add((cx+dx)+','+(cz+dz));
 for(const [k,chunk] of activeChunks){if(!desired.has(k)){scene.remove(chunk.group);chunk.group.traverse(o=>{if(o.geometry)o.geometry.dispose();});activeChunks.delete(k);}}
 for(const k of desired){if(activeChunks.has(k)||!chunkSources.has(k))continue;
  const group=new THREE.Group(),meshes=[];
  for(const {b,i} of chunkSources.get(k)){
   const mesh=box(group,b.w,b.h,b.d,buildingMats[i%4],b.x,b.h/2,b.z);meshes.push(mesh);
   mesh.add(new THREE.LineSegments(new THREE.EdgesGeometry(mesh.geometry),edgeMat));
   box(group,b.w+.4,.35,b.d+.4,ink,b.x,b.h+.16,b.z);box(group,3,1.1,2.5,roofDetail,b.x-2,b.h+.7,b.z+2);
  }
  scene.add(group);activeChunks.set(k,{group,meshes});
 }
 buildingMeshes.length=0;for(const chunk of activeChunks.values())buildingMeshes.push(...chunk.meshes);
}
updateChunks(0,9);
// Simple props at the edge of the central plaza.
for(const x of [-11,11])for(const z of [-11,11]){box(scene,.18,3,.18,ink,x,1.5,z);sphere(scene,.28,gold,x,3,z);}
// Pedestrians are simulated separately from their meshes so their behavior is testable.
const citizens=City.create(), citizenModels=[];
const clothing=[0xeea664,0x65a7bc,0xa7799c,0x78a67a,0xd6b45c,0x8a91c0,0xd77b72,0x8aa1a7];
for(let i=0;i<citizens.length;i++){
 const g=new THREE.Group(), clothes=mat(clothing[i]), skin=mat([0xdba782,0x9d6d4f,0xf2c8a5,0x744f42][i%4]);
 box(g,.65,.75,.35,clothes,0,1.08,0);sphere(g,.24,skin,0,1.73,0);
 const left=box(g,.2,.63,.23,navy,-.19,.32,0),right=box(g,.2,.63,.23,navy,.19,.32,0);
 box(g,.18,.65,.2,clothes,-.43,1.1,0);box(g,.18,.65,.2,clothes,.43,1.1,0);scene.add(g);citizenModels.push({g,left,right});
}
// Traffic is decorative: it moves on streets but has no collision/damage simulation yet.
const cars=[];
for(let i=0;i<4;i++){const g=new THREE.Group(),paint=mat([0xf3b84c,0x67a7bc,0xe77b6e,0xd8d8c7][i]);box(g,2.5,.7,1.25,paint,0,.55,0);box(g,1.2,.6,1.05,mat(0x9dc8d2),-.1,1.15,0);for(const x of [-.8,.8])for(const z of [-.65,.65])sphere(g,.25,ink,x,.28,z);scene.add(g);cars.push(g);}
const web=new THREE.Mesh(new THREE.CylinderGeometry(.045,.045,1,6),new THREE.MeshBasicMaterial({color:0xe8ffff}));web.visible=false;scene.add(web);
const anchorMarker=new THREE.Mesh(new THREE.SphereGeometry(.24,10,8),new THREE.MeshBasicMaterial({color:0xffe36f}));anchorMarker.visible=false;scene.add(anchorMarker);
const beacon=new THREE.Group();
const beam=new THREE.Mesh(new THREE.CylinderGeometry(.45,.45,18,12),new THREE.MeshBasicMaterial({color:0xffdb55,transparent:true,opacity:.3,depthWrite:false}));beam.position.y=9;beacon.add(beam);
const beaconRing=new THREE.Mesh(new THREE.RingGeometry(2,2.4,32),new THREE.MeshBasicMaterial({color:0xffdf68,side:THREE.DoubleSide}));beaconRing.rotation.x=-Math.PI/2;beaconRing.position.y=.12;beacon.add(beaconRing);beacon.visible=false;scene.add(beacon);
function saveStory(){save('comic-story-v1',{stage:storyStage});}
function savedStage(){const saved=load('comic-story-v1',null);return saved&&Story.valid(saved.stage)&&Story.stage(saved.stage).type!=='complete'?saved.stage:null;}
function updateContinue(){$('continueStory').classList.toggle('hidden',savedStage()===null);}
function hideBoss(){boss=null;scene.remove(enemy.group);$('bossHud').classList.add('hidden');}
function applyStoryStage(){
 const stage=Story.stage(storyStage);$('objective').textContent=stage.title;$('tip').textContent=stage.hint;
 beacon.visible=stage.type==='travel';
 if(stage.type==='travel'){hideBoss();beacon.position.set(stage.x,0,stage.z);message(stage.hint.toUpperCase(),5);}
 else if(stage.type==='boss'){setBoss(stage.boss);if(stage.boss===1){boss.x=0;boss.z=-85;}message(stage.hint.toUpperCase(),5);}
 else{hideBoss();finish(true);}
 saveStory();
}
function advanceStory(event){const next=Story.advance(storyStage,event);if(next!==storyStage){storyStage=next;applyStoryStage();}}
updateContinue();
function message(text,seconds=3){$('notice').textContent=text;noticeTimer=seconds;$('notice').classList.remove('hidden');}
function clearInput(){Object.assign(input,{forward:false,back:false,left:false,right:false,jx:0,jy:0,jump:false,swing:false});player.rope=null;$('stick').style.transform='translate(0,0)';document.querySelectorAll('.pressed').forEach(x=>x.classList.remove('pressed'));}
function setBoss(index){bossIndex=index;boss=P.createBoss(index);scene.remove(enemy.group);if(boss){enemy=makeBoss(boss.id);scene.add(enemy.group);$('bossHud').classList.remove('hidden');$('bossName').textContent=boss.name;$('bossSubtitle').textContent=boss.subtitle;$('objective').textContent='Defeat '+boss.name;message(boss.name+' HAS ENTERED THE FIGHT!',3);}else{$('bossHud').classList.add('hidden');finish(true);}}
function start(selectedMode='story',continueSaved=false){
 clearInput();mode=selectedMode;player=P.createPlayer();yaw=0;pitch=0;view='third';attackCooldown=0;state='playing';last=0;
 storyStage=continueSaved?(savedStage()??0):0;
 if(mode==='story'){const spawn=Story.stage(storyStage).spawn;player.x=spawn.x;player.z=spawn.z;}
 camera.position.set(player.x,4,player.z+7);updateChunks(player.x,player.z);
 $('menu').classList.add('hidden');$('dialog').classList.add('hidden');$('hud').classList.remove('hidden');updateView();
 if(mode==='story')applyStoryStage();else{hideBoss();beacon.visible=false;$('objective').textContent='Explore the city';$('tip').textContent='Drag the view to look around';message('HOLD SWING TO LAUNCH • DRAG TO LOOK',5);}
 updateHud();
}
function showDialog(panel){$('dialog').classList.remove('hidden');['pause','settings','result'].forEach(p=>$(p+'Panel').classList.toggle('hidden',p!==panel));$('lighting').value=settings.lighting;$('assist').checked=!!settings.assist;}
function pause(){if(state!=='playing')return;clearInput();state='paused';previous='paused';showDialog('pause');}
function resume(){state='playing';last=0;$('dialog').classList.add('hidden');}
function menu(){clearInput();state='menu';$('dialog').classList.add('hidden');$('hud').classList.add('hidden');$('menu').classList.remove('hidden');beacon.visible=false;updateContinue();}
function finish(won){clearInput();state='result';$('resultTag').textContent=won?'CITY SAVED':'DOWN BUT NOT OUT';$('resultTitle').textContent=won?'VICTORY!':'DEFEATED';$('resultText').textContent=won?'You stopped both villains in this short original story. The larger game is still in development.':'The villains won this round. Try again and dodge their warning rings.';showDialog('result');}
window.comicGame={pause};$('play').onclick=()=>start('story');$('continueStory').onclick=()=>start('story',true);$('freeRoam').onclick=()=>start('free');$('retry').onclick=()=>start('story',true);$('pause').onclick=pause;$('resume').onclick=resume;$('toMenu').onclick=menu;$('resultMenu').onclick=menu;
$('settingsOpen').onclick=()=>{previous='menu';showDialog('settings');};$('pauseSettings').onclick=()=>{previous='paused';showDialog('settings');};
function closeSettings(){if(previous==='paused')showDialog('pause');else $('dialog').classList.add('hidden');}
$('settingsDone').onclick=closeSettings;$('closeDialog').onclick=()=>{if(!$('settingsPanel').classList.contains('hidden'))closeSettings();else if(state==='paused')resume();else if(state==='result')menu();};
$('lighting').onchange=e=>{settings.lighting=e.target.value;save('comic3d-settings',settings);lighting();};$('assist').onchange=e=>{settings.assist=e.target.checked;save('comic3d-settings',settings);};
function updateView(){hands.visible=view==='first';hero.group.visible=view!=='first';$('camera').innerHTML='◉<small>'+(view==='first'?'1ST':'3RD')+'</small>';$('camera').setAttribute('aria-label',view==='first'?'Switch to third person':'Switch to first person');}
function toggleCamera(){if(state!=='playing')return;view=view==='third'?'first':'third';updateView();message(view==='first'?'FIRST-PERSON CAMERA':'THIRD-PERSON CAMERA',2);}
$('camera').onclick=toggleCamera;
function talk(){if(state!=='playing')return;const npc=City.nearest(citizens,player);message(npc?'CIVILIAN: '+City.talk(npc):'MOVE CLOSER TO A CIVILIAN TO TALK',3);}
$('talk').onclick=talk;
function hit(){if(state!=='playing'||attackCooldown>0)return;if(!boss){message('NO VILLAIN NEARBY',1.5);return;}attackCooldown=.42;if(P.attack(player,boss)){message('HIT!  •  '+boss.name,1);if(boss.hp<=0){player.health=Math.min(100,player.health+35);if(mode==='story')advanceStory({type:'defeated',boss:bossIndex});}}else message('GET CLOSER TO ATTACK',1);}
function swingOn(){if(state!=='playing'||input.swing)return;input.swing=true;if(!P.attach(player,world,settings.assist,{x:-Math.sin(yaw),z:-Math.cos(yaw)}))message('NO ROOFTOP AHEAD • TURN TOWARD A BUILDING',2);else message(settings.assist?'WEB ATTACHED • RELEASE TO LAUNCH':'WEB ATTACHED • JUMP AND MOVE TO SWING',2);}
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
window.addEventListener('keydown',e=>{const k=keys[e.key]||keys[e.key.toLowerCase()];if(k){e.preventDefault();if(state==='playing')input[k]=true;}if(e.code==='Space'){e.preventDefault();if(state==='playing'&&!e.repeat)input.jump=true;}if(e.key==='Shift'){e.preventDefault();swingOn();}if(e.key.toLowerCase()==='f'&&!e.repeat)hit();if(e.key.toLowerCase()==='c'&&!e.repeat)toggleCamera();if(e.key.toLowerCase()==='e'&&!e.repeat)talk();if(e.key==='Escape'&&!e.repeat){if(state==='playing')pause();else if(state==='paused'&&!$('pausePanel').classList.contains('hidden'))resume();}});
window.addEventListener('keyup',e=>{const k=keys[e.key]||keys[e.key.toLowerCase()];if(k)input[k]=false;if(e.key==='Shift')swingOff();});
document.addEventListener('visibilitychange',()=>{if(document.hidden)pause();});window.addEventListener('blur',pause);
function updateHud(){ $('webStatus').textContent=player.rope?'WEB ATTACHED • '+Math.round(player.y)+'M':'WEB READY';$('webStatus').dataset.altitude=player.y.toFixed(2);$('talk').dataset.nearby=City.nearest(citizens,player)?'true':'false';$('webStatus').classList.toggle('attached',!!player.rope);$('playerHealth').textContent=Math.ceil(player.health);$('playerBar').style.width=player.health+'%';if(boss){$('bossBar').style.width=(boss.hp/boss.health*100)+'%';$('bossPhase').textContent=boss.hp<=boss.health/2?'PHASE 2':'PHASE 1';} }
function resize(){camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);}window.addEventListener('resize',resize);
const desired=new THREE.Vector3(),target=new THREE.Vector3(), ray=new THREE.Raycaster(),rayDirection=new THREE.Vector3(),webStart=new THREE.Vector3(),webEnd=new THREE.Vector3();
function frame(now){const dt=last?Math.min((now-last)/1000,1/30):0;last=now;clock+=dt;
 if(state==='playing'){
  const sx=(input.right?1:0)-(input.left?1:0)+input.jx,sz=(input.back?1:0)-(input.forward?1:0)+input.jy;
  const mx=Math.cos(yaw)*sx+Math.sin(yaw)*sz,mz=-Math.sin(yaw)*sx+Math.cos(yaw)*sz;
  City.step(citizens,dt);
  P.stepPlayer(player,world,{x:mx,z:mz,jump:input.jump},dt);updateChunks(player.x,player.z);input.jump=false;P.stepBoss(boss,player,dt);attackCooldown=Math.max(0,attackCooldown-dt);
  if(Math.hypot(mx,mz)>.1)hero.group.rotation.y=Math.atan2(-mx,-mz);
  if(mode==='story')advanceStory({type:'position',x:player.x,z:player.z});
  if(player.health<=0)finish(false);
  if(noticeTimer>0){noticeTimer-=dt;if(noticeTimer<=0)$('notice').classList.add('hidden');}
  updateHud();
 }
 hero.group.position.set(player.x,player.y,player.z);const moving=Math.hypot(player.vx,player.vz)>.8&&player.grounded;hero.group.rotation.x=player.rope?Math.max(-.38,Math.min(.38,-player.vy*.025)):0;hero.group.rotation.z=player.rope?Math.max(-.2,Math.min(.2,player.vx*.015)):0;hero.legL.rotation.x=moving?Math.sin(clock*9)*.45:(player.rope?.45:0);hero.legR.rotation.x=moving?-hero.legL.rotation.x:(player.rope?-.35:0);hero.armL.rotation.x=player.rope?-.7:-hero.legL.rotation.x;hero.armR.rotation.x=player.rope?-2:hero.legL.rotation.x;
 if(boss){enemy.group.position.set(boss.x,0,boss.z);enemy.group.rotation.y=Math.atan2(boss.x-player.x,boss.z-player.z);enemy.ring.material.color.setHex(boss.state==='windup'?0xff3939:(boss.id==='volt'?0x62f3f5:0xffcb51));enemy.ring.scale.setScalar(boss.state==='windup'?1.2+Math.sin(clock*20)*.15:1);enemy.l.rotation.x=boss.state==='windup'?-1:Math.sin(clock*6)*.12;enemy.r.rotation.x=enemy.l.rotation.x;}
 citizens.forEach((npc,i)=>{const m=citizenModels[i];m.g.position.set(npc.x,0,npc.z);m.g.rotation.y=npc.angle;m.left.rotation.x=Math.sin(clock*6+i)*.25;m.right.rotation.x=-m.left.rotation.x;});
 cars.forEach((car,i)=>{const pos=((clock*(i%2?7:9)+i*36)%144)-72;car.position.set(i<2?pos:(i===2?-3:3),0,i<2?(i===0?-3:3):pos);car.rotation.y=i<2?(i===0?0:Math.PI):(i===2?-Math.PI/2:Math.PI/2);});
 web.visible=!!player.rope;anchorMarker.visible=!!player.rope;
 if(player.rope){if(view==='first'){camera.updateMatrixWorld(true);hands.localToWorld(webStart.set(.32,-.35,-1.05));}else{hero.group.updateMatrixWorld(true);hero.armR.localToWorld(webStart.set(0,-.76,0));}webEnd.set(player.rope.x,player.rope.y,player.rope.z);web.position.copy(webStart).add(webEnd).multiplyScalar(.5);web.scale.y=webStart.distanceTo(webEnd);web.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),webEnd.sub(webStart).normalize());anchorMarker.position.set(player.rope.x,player.rope.y,player.rope.z);}
 if(state==='menu'){camera.position.set(15+Math.sin(clock*.13)*2,8,20);camera.lookAt(0,2,0);hero.group.visible=true;hands.visible=false;}
 else if(view==='first'){camera.position.set(player.x,player.y+1.8,player.z);target.set(player.x-Math.sin(yaw)*Math.cos(pitch)*10,player.y+1.8+Math.sin(pitch)*10,player.z-Math.cos(yaw)*Math.cos(pitch)*10);camera.lookAt(target);}
 else{desired.set(player.x+Math.sin(yaw)*6,Math.max(player.y+.5,player.y+3.5-pitch*4),player.z+Math.cos(yaw)*6);target.set(player.x,player.y+1.4+pitch*3,player.z);rayDirection.copy(desired).sub(target);const distance=rayDirection.length();ray.set(target,rayDirection.normalize());ray.far=distance;const intersections=ray.intersectObjects(buildingMeshes,false);if(intersections.length)desired.copy(target).addScaledVector(rayDirection,Math.max(.4,intersections[0].distance-.5));camera.position.lerp(desired,Math.min(1,dt*8));camera.lookAt(target);}
 renderer.render(scene,camera);requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
})();
