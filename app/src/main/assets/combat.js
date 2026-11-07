/* Small independent combat model: cooldowns, web energy, combos, dodge and stun. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicCombat=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function create(){return {energy:100,attackCooldown:0,webCooldown:0,dodgeCooldown:0,combo:0,comboWindow:0};}
 function tick(c,p,dt){dt=Math.max(0,Math.min(dt,1/30));c.attackCooldown=Math.max(0,c.attackCooldown-dt);c.webCooldown=Math.max(0,c.webCooldown-dt);c.dodgeCooldown=Math.max(0,c.dodgeCooldown-dt);c.comboWindow=Math.max(0,c.comboWindow-dt);p.invulnerable=Math.max(0,(p.invulnerable||0)-dt);c.energy=Math.min(100,c.energy+10*dt);if(!c.comboWindow)c.combo=0;}
 function nearest(p,targets,range,visible=()=>true){let found=null,best=range;for(const t of targets){if(!t||t.hp<=0||!visible(t))continue;const d=Math.hypot(t.x-p.x,(t.y||0)+1-p.y-1,t.z-p.z);if(d<=best){best=d;found=t;}}return found;}
 function melee(c,p,targets,visible){if(c.attackCooldown>0)return {ok:false,reason:'cooldown'};c.attackCooldown=.42;const target=nearest(p,targets,3.2,visible);if(!target)return {ok:false,reason:'range'};c.combo=c.comboWindow>0?c.combo%3+1:1;c.comboWindow=1.7;const damage=[0,20,25,30][c.combo];target.hp=Math.max(0,target.hp-damage);target.hitFlash=.18;return {ok:true,target,damage,combo:c.combo};}
 function web(c,p,targets,visible){if(c.webCooldown>0)return {ok:false,reason:'cooldown'};if(c.energy<25)return {ok:false,reason:'energy'};const target=nearest(p,targets,20,visible);if(!target)return {ok:false,reason:'range'};c.energy-=25;c.webCooldown=.6;target.stun=Math.max(target.stun||0,2);target.state='chase';target.hitFlash=.18;return {ok:true,target};}
 function dodge(c,p,dx,dz){if(c.dodgeCooldown>0)return false;const len=Math.hypot(dx,dz);if(len<.001)return false;c.dodgeCooldown=1.4;p.invulnerable=.55;p.rope=null;p.vx=dx/len*13;p.vz=dz/len*13;return true;}
 return {create,tick,nearest,melee,web,dodge};
});
