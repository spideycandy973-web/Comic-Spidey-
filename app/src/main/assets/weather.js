/* Deterministic, pausable cosmetic weather. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicWeather=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function create(mode){return {mode:mode||'clear',elapsed:0,raining:mode==='rain'};}
 function setMode(w,mode){w.mode=['clear','rain','cycle'].includes(mode)?mode:'clear';w.elapsed=0;w.raining=w.mode==='rain';}
 function step(w,dt){w.elapsed+=Math.max(0,dt);w.raining=w.mode==='rain'||(w.mode==='cycle'&&(w.elapsed%120)>=75);return w.raining;}
 return {create,setMode,step};
});
