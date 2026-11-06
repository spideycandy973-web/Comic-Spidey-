/* Testable 3D movement and encounter rules. Coordinates: Y up, player position at feet. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicPhysics=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const villains = [
    {id:'volt',name:'VOLT',subtitle:'THE LIVE WIRE',health:100,speed:3.8,range:2.4,damage:12,windup:.65,cooldown:1.2},
    {id:'ironclad',name:'IRONCLAD',subtitle:'THE WRECKING MACHINE',health:160,speed:2.5,range:2.9,damage:22,windup:1.05,cooldown:1.65}
  ];
  function createWorld(){
    const buildings=[];
    for(let gx=-3;gx<=3;gx++)for(let gz=-3;gz<=3;gz++){
      if(Math.abs(gx)<2 && Math.abs(gz)<2)continue;
      const x=gx*20,z=gz*20,h=10+((Math.abs(gx*31+gz*17)*7)%15);
      buildings.push({x,z,w:12+(Math.abs(gz)%2)*2,d:12+(Math.abs(gx)%2)*2,h});
    }
    return {buildings,bound:70};
  }
  function createPlayer(){return {x:0,y:0,z:9,vx:0,vy:0,vz:0,grounded:true,health:100,rope:null};}
  function createBoss(index){const def=villains[index];return def?{...def,x:index===0?0:3,z:index===0?-8:-12,hp:def.health,state:'chase',timer:0,hitFlash:0}:null;}
  function attach(p,world,assist){
    let best=null,bestScore=Infinity;const range=assist?42:30;
    for(const b of world.buildings){
      const y=b.h+1,dx=b.x-p.x,dy=y-(p.y+1.4),dz=b.z-p.z,dist=Math.hypot(dx,dy,dz);
      if(dy>1&&dist<range&&dist<bestScore){best={x:b.x,y,z:b.z,length:Math.max(3,dist)};bestScore=dist;}
    }
    p.rope=best;return !!best;
  }
  function stepPlayer(p,world,move,dt){
    dt=Math.max(0,Math.min(1/30,dt));
    const mx=move.x||0,mz=move.z||0,mag=Math.hypot(mx,mz)||1;
    const accel=p.grounded?30:11; p.vx+=(mx/Math.max(1,mag)*accel)*dt; p.vz+=(mz/Math.max(1,mag)*accel)*dt;
    const damping=Math.pow(p.grounded?.0003:.7,dt);p.vx*=damping;p.vz*=damping;
    const speed=Math.hypot(p.vx,p.vz), cap=p.rope?18:8;if(speed>cap){p.vx*=cap/speed;p.vz*=cap/speed;}
    if(move.jump&&p.grounded){p.vy=10;p.grounded=false;}
    p.vy-=22*dt;
    const ox=p.x,oy=p.y,oz=p.z;p.x+=p.vx*dt;p.y+=p.vy*dt;p.z+=p.vz*dt;
    if(p.rope){const dx=p.x-p.rope.x,dy=p.y+1.4-p.rope.y,dz=p.z-p.rope.z,d=Math.hypot(dx,dy,dz)||1;
      if(d>p.rope.length){const nx=dx/d,ny=dy/d,nz=dz/d;p.x=p.rope.x+nx*p.rope.length;p.y=p.rope.y+ny*p.rope.length-1.4;p.z=p.rope.z+nz*p.rope.length;const radial=p.vx*nx+p.vy*ny+p.vz*nz;if(radial>0){p.vx-=radial*nx;p.vy-=radial*ny;p.vz-=radial*nz;}}
    }
    p.grounded=false;let floor=0;
    for(const b of world.buildings){
      const inside=Math.abs(p.x-b.x)<b.w/2+.45&&Math.abs(p.z-b.z)<b.d/2+.45;
      if(!inside)continue;
      if(oy>=b.h-.05&&p.y<=b.h&&p.vy<=0){floor=Math.max(floor,b.h);}
      else if(p.y<b.h-.05 && p.y+1.7>0){ // Solid walls: reject the entering horizontal component.
        const wasX=Math.abs(ox-b.x)<b.w/2+.45,wasZ=Math.abs(oz-b.z)<b.d/2+.45;
        if(!wasX){p.x=ox;p.vx=0;} else if(!wasZ){p.z=oz;p.vz=0;} else {p.x=ox;p.z=oz;p.vx=p.vz=0;}
      }
    }
    if(p.y<=floor && p.vy<=0){p.y=floor;p.vy=0;p.grounded=true;}
    p.x=Math.max(-world.bound,Math.min(world.bound,p.x));p.z=Math.max(-world.bound,Math.min(world.bound,p.z));
  }
  function attack(p,b){if(!b||b.hp<=0)return false;const distance=Math.hypot(p.x-b.x,p.z-b.z);if(distance>3.2||p.y>2.7)return false;b.hp=Math.max(0,b.hp-20);b.hitFlash=.18;return true;}
  function stepBoss(b,p,dt){
    if(!b||b.hp<=0||p.health<=0)return;
    b.hitFlash=Math.max(0,b.hitFlash-dt);const dx=p.x-b.x,dz=p.z-b.z,dist=Math.hypot(dx,dz)||1;
    const phase=b.hp<=b.health/2?1.3:1;
    if(b.state==='chase'){
      if(dist<b.range && p.y<2.5){b.state='windup';b.timer=b.windup/phase;}
      else if(dist<38){const step=Math.min(dist,b.speed*phase*dt);b.x+=dx/dist*step;b.z+=dz/dist*step;}
    }else if(b.state==='windup'){
      b.timer-=dt;if(b.timer<=0){if(dist<b.range+0.6&&p.y<2.5)p.health=Math.max(0,p.health-b.damage);b.state='cooldown';b.timer=b.cooldown;}
    }else {b.timer-=dt;if(b.timer<=0)b.state='chase';}
  }
  return {villains,createWorld,createPlayer,createBoss,attach,stepPlayer,stepBoss,attack};
});
