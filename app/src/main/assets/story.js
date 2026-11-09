/* Original story objectives and companion movement, independent of rendering. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicStory=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const stages=[
  {type:'travel',title:'Investigate the plaza',hint:'A disturbance has been reported downtown.',x:0,z:-8,radius:5,spawn:{x:0,z:9}},
  {type:'boss',title:'Stop Volt',hint:'Volt is attacking the plaza!',boss:0,x:0,z:-8,spawn:{x:0,z:-2}},
  {type:'travel',title:'Reach the north crossing',hint:'Doctor Octopus is heading north. Follow the beacon.',x:0,z:-85,radius:6,spawn:{x:0,z:-8}},
  {type:'boss',title:'Stop Doctor Octopus',hint:'Doctor Octopus is threatening the crossing!',boss:1,x:0,z:-85,spawn:{x:0,z:-79}},
  {type:'travel',title:'Find the power relay',hint:'Octopus escaped. Trace his signal east.',x:80,z:-160,radius:6,spawn:{x:0,z:-85}},
  {type:'interact',title:'Disable the power relay',hint:'Stand by the relay and press USE.',x:80,z:-160,radius:4,spawn:{x:80,z:-155}},
  {type:'travel',title:'Find the stranded civilian',hint:'A civilian needs help at the next crossing.',x:160,z:-160,radius:6,spawn:{x:80,z:-160}},
  {type:'escort',title:'Escort the civilian',hint:'Stay close and lead the civilian to the safe crossing.',x:160,z:-160,destX:160,destZ:-80,radius:6,spawn:{x:160,z:-160}},
  {type:'travel',title:'Follow the getaway crew',hint:'The crew is moving east. Follow the beacon.',x:240,z:-80,radius:6,spawn:{x:160,z:-80}},
  {type:'crew',title:'Stop the getaway crew',hint:'Defeat all three attackers.',x:240,z:-80,spawn:{x:240,z:-74}},
  {type:'travel',title:'Reach the generator',hint:'Octopus is at the northern generator.',x:240,z:-160,radius:6,spawn:{x:240,z:-80}},
  {type:'boss',title:'Confront Doctor Octopus',hint:'Stop Octopus before the generator overloads.',boss:1,x:240,z:-160,spawn:{x:240,z:-154}},
  {type:'interact',title:'Stabilize the generator',hint:'Stand by the generator and press USE.',x:240,z:-160,radius:4,spawn:{x:240,z:-155}},
  {type:'complete',title:'City secured',hint:'The city is safe for now.',spawn:{x:240,z:-155}}
 ];
 function valid(index){return Number.isInteger(index)&&index>=0&&index<stages.length;}
 function stage(index){return stages[valid(index)?index:0];}
 function inRange(x,z,px,pz,r){return Math.hypot(px-x,pz-z)<r;}
 function advance(index,event){const s=stage(index);if(s.type==='travel'&&event.type==='position'&&(event.y||0)<3&&inRange(s.x,s.z,event.x,event.z,s.radius))return index+1;if(s.type==='interact'&&event.type==='interact'&&(event.y||0)<3&&inRange(s.x,s.z,event.x,event.z,s.radius))return index+1;if(s.type==='boss'&&event.type==='defeated'&&event.boss===s.boss)return index+1;if(s.type==='crew'&&event.type==='crew-cleared')return index+1;if(s.type==='escort'&&event.type==='escorted'&&(event.y||0)<3&&inRange(s.destX,s.destZ,event.x,event.z,s.radius)&&inRange(s.destX,s.destZ,event.companion.x,event.companion.z,s.radius))return index+1;return valid(index)?index:0;}
 function createEscort(s){return {x:s.x,z:s.z,angle:0};}
 // The civilian follows on the ground and only moves while the player stays nearby.
 function stepEscort(e,p,dt,blocked=()=>false){const dx=p.x-e.x,dz=p.z-e.z,d=Math.hypot(dx,dz);if(p.y>=3||d<2.8||d>30)return;const step=Math.min(d-2.8,5*Math.max(0,dt)),nx=e.x+dx/d*step,nz=e.z+dz/d*step;if(!blocked(nx,e.z))e.x=nx;if(!blocked(e.x,nz))e.z=nz;e.angle=Math.atan2(-dx,-dz);}
 return {stages,stage,advance,valid,createEscort,stepEscort};
});
