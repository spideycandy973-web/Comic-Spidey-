/* Validated free-roam saves. Story progress remains in its own checkpoint. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicSave=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function snapshot(p,c,yaw,pitch){return {version:1,x:p.x,y:p.y,z:p.z,health:p.health,energy:c.energy,yaw,pitch};}
 function valid(s,bound){return !!s&&s.version===1&&['x','y','z','health','energy','yaw','pitch'].every(k=>typeof s[k]==='number'&&Number.isFinite(s[k]))&&Math.abs(s.x)<=bound&&Math.abs(s.z)<=bound&&s.y>=0&&s.y<=250&&s.health>0&&s.health<=100&&s.energy>=0&&s.energy<=100&&Math.abs(s.yaw)<=100000&&Math.abs(s.pitch)<=.65;}
 function restore(s,world,nearby){if(!valid(s,world.bound))return null;let floor=0;for(const b of nearby(world,s.x,s.z,16)){if(Math.abs(s.x-b.x)<b.w/2+.45&&Math.abs(s.z-b.z)<b.d/2+.45)floor=Math.max(floor,b.h);}const y=Math.max(s.y,floor);return {x:s.x,y,z:s.z,health:s.health,energy:s.energy,yaw:s.yaw%(2*Math.PI),pitch:s.pitch,grounded:Math.abs(y-floor)<.05};}
 function actor(s,bound,maxHealth,allowZero=false){return !!s&&Number.isFinite(s.x)&&Number.isFinite(s.z)&&Math.abs(s.x)<=bound&&Math.abs(s.z)<=bound&&Number.isFinite(s.hp)&&s.hp>=(allowZero?0:Number.MIN_VALUE)&&s.hp<=maxHealth;}
 return {snapshot,valid,restore,actor};
});
