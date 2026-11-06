/* A small original four-objective story, independent of rendering and persistence. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicStory=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const stages=[
  {type:'travel',title:'Investigate the plaza',hint:'A disturbance has been reported downtown.',x:0,z:-8,radius:5,spawn:{x:0,z:9}},
  {type:'boss',title:'Stop Volt',hint:'Volt is attacking the plaza!',boss:0,spawn:{x:0,z:-2}},
  {type:'travel',title:'Reach the north crossing',hint:'Ironclad is heading north. Follow the beacon.',x:0,z:-85,radius:6,spawn:{x:0,z:-8}},
  {type:'boss',title:'Stop Ironclad',hint:'Ironclad is threatening the crossing!',boss:1,spawn:{x:0,z:-79}},
  {type:'complete',title:'City secured',hint:'The city is safe for now.',spawn:{x:0,z:-79}}
 ];
 function valid(index){return Number.isInteger(index)&&index>=0&&index<stages.length;}
 function stage(index){return stages[valid(index)?index:0];}
 function advance(index,event){const s=stage(index);if(s.type==='travel'&&event.type==='position'&&Math.hypot(event.x-s.x,event.z-s.z)<s.radius)return index+1;if(s.type==='boss'&&event.type==='defeated'&&event.boss===s.boss)return index+1;return valid(index)?index:0;}
 return {stages,stage,advance,valid};
});
