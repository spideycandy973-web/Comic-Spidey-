/* Small, deterministic ambient city simulation. NPCs walk a plaza loop and can speak. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicCity=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const lines=[['Thanks for looking out for us!','The rooftops have the best views.'],['Stay safe out there, hero!','I saw someone swinging overhead!'],['This city never slows down.','Those villains had better watch out.'],['Nice day to explore the city.','I think the action is in the plaza.']];
  const loop=112;
  function at(distance){const t=((distance%loop)+loop)%loop;if(t<28)return{x:-14+t,z:14,angle:-Math.PI/2};if(t<56)return{x:14,z:14-(t-28),angle:0};if(t<84)return{x:14-(t-56),z:-14,angle:Math.PI/2};return{x:-14,z:-14+(t-84),angle:Math.PI};}
  function create(){return Array.from({length:8},(_,i)=>({id:i,position:i*14,speed:1.05+(i%3)*.18,line:0,...at(i*14)}));}
  function step(npcs,dt){for(const npc of npcs){npc.position=(npc.position+npc.speed*dt)%loop;Object.assign(npc,at(npc.position));}}
  function nearest(npcs,p,max=3.2){if(p.y>2.5)return null;let found=null,best=max;for(const npc of npcs){const d=Math.hypot(npc.x-p.x,npc.z-p.z);if(d<best){found=npc;best=d;}}return found;}
  function talk(npc){const phrases=lines[npc.id%lines.length];const text=phrases[npc.line%phrases.length];npc.line++;return text;}
  return {create,step,nearest,talk};
});
