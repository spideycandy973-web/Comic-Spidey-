/* A small recycled traffic pool follows the player on the road grid. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicTraffic=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function updatePosition(car){if(car.axis==='x'){car.x=car.centerX+car.offset;car.z=car.centerZ+car.lane;}else{car.x=car.centerX+car.lane;car.z=car.centerZ+car.offset;}}
 function create(){return Array.from({length:4},(_,i)=>{const car={axis:i<2?'x':'z',direction:i%2?-1:1,lane:i%2?3:-3,speed:7+i,offset:-65+i*35,centerX:0,centerZ:0,min:-72,max:72,stopped:false};updatePosition(car);return car;});}
 function recenter(cars,player,bound){if(!cars.length||Math.hypot(player.x-cars[0].centerX,player.z-cars[0].centerZ)<125)return false;const limit=Math.floor(bound/80)*80,cx=Math.max(-limit,Math.min(limit,Math.round(player.x/80)*80)),cz=Math.max(-limit,Math.min(limit,Math.round(player.z/80)*80));cars.forEach((car,i)=>{car.centerX=cx;car.centerZ=cz;const center=car.axis==='x'?cx:cz;car.min=Math.max(-72,-bound-center);car.max=Math.min(72,bound-center);car.offset=Math.max(car.min,Math.min(car.max,-65+i*35));updatePosition(car);});return true;}
 function step(cars,obstacles,dt){
  dt=Math.max(0,Math.min(dt,1/30));
  for(const car of cars){car.stopped=obstacles.some(o=>{if((o.y||0)>2)return false;const forward=car.axis==='x'?(o.x-car.x)*car.direction:(o.z-car.z)*car.direction,side=car.axis==='x'?Math.abs(o.z-car.z):Math.abs(o.x-car.x);return forward>=0&&forward<5&&side<1.8;});
   if(!car.stopped){car.offset+=car.speed*car.direction*dt;if(car.offset>car.max)car.offset=car.min;if(car.offset<car.min)car.offset=car.max;}updatePosition(car);
  }
 }
 return {create,recenter,step};
});
