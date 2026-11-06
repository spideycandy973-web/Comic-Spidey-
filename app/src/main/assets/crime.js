/* Local free-roam crime encounters, on clear road corridors. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicCrime=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function create(){return {phase:'waiting',timer:4,enemies:[],location:null,completed:0,sequence:0};}
 function spawn(s,p,bound){const direction=s.sequence%2?-1:1;s.sequence++;const roadLimit=Math.floor(bound/80)*80,x=Math.max(-roadLimit,Math.min(roadLimit,Math.round(p.x/80)*80));const z=Math.max(-bound+20,Math.min(bound-20,p.z-35*direction));s.location={x,z};s.enemies=[-2,2].map((dx,i)=>({id:i,x:x+dx,z:z+(i?2:-2),y:0,hp:60,health:60,speed:2.6+i*.4,range:2.1,damage:8,windup:.8,cooldown:1.4,state:'chase',timer:0,stun:0,hitFlash:0}));s.phase='active';return 'spawned';}
 function tick(s,p,dt,bound){if(s.phase==='waiting'){s.timer-=dt;if(s.timer<=0)return spawn(s,p,bound);}else if(s.enemies.every(e=>e.hp<=0)){s.phase='waiting';s.timer=25;s.completed++;s.enemies=[];s.location=null;p.health=Math.min(100,p.health+12);return 'completed';}return null;}
 return {create,tick};
});
