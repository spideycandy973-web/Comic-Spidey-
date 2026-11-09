/* Deterministic repeatable street events. Timer counts only simulated play time. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicCrime=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const types=['assault','rescue','sabotage'];
 function create(){return {phase:'waiting',timer:4,enemies:[],location:null,completed:0,failed:0,sequence:0,type:null,remaining:0,pending:null};}
 function spawn(s,p,bound){
  const direction=s.sequence%2?-1:1;s.type=types[s.sequence%types.length];s.sequence++;
  const roadLimit=Math.floor(bound/80)*80,x=Math.max(-roadLimit,Math.min(roadLimit,Math.round(p.x/80)*80));const z=Math.max(-bound+20,Math.min(bound-20,p.z-35*direction));s.location={x,z};
  const offsets=s.type==='rescue'?[-3,0,3]:[-2,2];
  s.enemies=offsets.map((dx,i)=>({id:i,x:x+dx,z:z+(i%2?2:-2),y:0,hp:60,health:60,speed:2.6+i*.3,range:2.1,damage:8,windup:.8,cooldown:1.4,state:'chase',timer:0,stun:0,hitFlash:0}));
  s.phase='active';s.remaining=s.type==='sabotage'?90:0;s.pending=null;return 'spawned';
 }
 function finish(s,p,success){if(success){s.completed++;p.health=Math.min(100,p.health+12);}else s.failed++;s.phase='waiting';s.timer=25;s.enemies=[];s.location=null;s.pending=null;return success?'completed':'failed';}
 function tick(s,p,dt,bound){
  dt=Math.max(0,dt);
  if(s.phase==='waiting'){s.timer-=dt;if(s.timer<=0)return spawn(s,p,bound);return null;}
  if(s.pending==='completed')return finish(s,p,true);
  if(s.type==='sabotage'){s.remaining=Math.max(0,s.remaining-dt);if(s.remaining<=0)return finish(s,p,false);}
  if(s.phase==='active'&&s.enemies.every(e=>e.hp<=0)){
   if(s.type==='assault')return finish(s,p,true);
   s.phase=s.type==='rescue'?'rescue':'disarm';return 'ready';
  }
  return null;
 }
 function interact(s,p){if(!['rescue','disarm'].includes(s.phase)||!s.location||p.y>=3||Math.hypot(p.x-s.location.x,p.z-s.location.z)>=4)return false;s.pending='completed';return true;}
 return {create,tick,interact};
});
