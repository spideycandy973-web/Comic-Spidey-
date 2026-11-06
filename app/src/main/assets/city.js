/* Small, deterministic ambient city simulation. NPCs walk a plaza loop and can speak. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicCity=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const lines=[['Thanks for looking out for us!','The rooftops have the best views.'],['Stay safe out there, hero!','I saw someone swinging overhead!'],['This city never slows down.','Those villains had better watch out.'],['Nice day to explore the city.','I think the action is in the plaza.']];
  const loop=112;
  function at(distance,radius=14){const edge=radius*2,perimeter=edge*4,t=((distance%perimeter)+perimeter)%perimeter;if(t<edge)return{x:-radius+t,z:radius,angle:-Math.PI/2};if(t<2*edge)return{x:radius,z:radius-(t-edge),angle:0};if(t<3*edge)return{x:radius-(t-2*edge),z:-radius,angle:Math.PI/2};return{x:-radius,z:-radius+(t-3*edge),angle:Math.PI};}
  function create(){return Array.from({length:8},(_,i)=>({id:i,position:i*14,speed:1.05+(i%3)*.18,line:0,...at(i*14)}));}
  function step(npcs,dt){for(const npc of npcs){const radius=npc.radius||14,perimeter=radius*8;npc.position=(npc.position+npc.speed*dt)%perimeter;const point=at(npc.position,radius);npc.x=(npc.centerX||0)+point.x;npc.z=(npc.centerZ||0)+point.z;npc.angle=point.angle;}}
  // Reuse the same bounded crowd at a nearby street junction as the player explores.
  function recenter(npcs,p,bound=810){if(!npcs.length)return;const first=npcs[0];if(Math.hypot(p.x-(first.centerX||0),p.z-(first.centerZ||0))<125)return;const limit=Math.floor(bound/80)*80,cx=Math.max(-limit,Math.min(limit,Math.round(p.x/80)*80)),cz=Math.max(-limit,Math.min(limit,Math.round(p.z/80)*80));npcs.forEach((npc,i)=>{npc.centerX=cx;npc.centerZ=cz;npc.radius=6;npc.position=i*6;});step(npcs,0);}
  function nearest(npcs,p,max=3.2){if(p.y>2.5)return null;let found=null,best=max;for(const npc of npcs){const d=Math.hypot(npc.x-p.x,npc.z-p.z);if(d<best){found=npc;best=d;}}return found;}
  function talk(npc){const phrases=lines[npc.id%lines.length];const text=phrases[npc.line%phrases.length];npc.line++;return text;}
  return {create,step,recenter,nearest,talk};
});
