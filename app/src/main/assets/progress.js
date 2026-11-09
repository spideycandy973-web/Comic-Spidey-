/* Persistent, cosmetic progression. Story checkpoints grant XP only once. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicProgress=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const tints={classic:{color:0xffffff,xp:0},midnight:{color:0x819de5,xp:100},sunset:{color:0xffcb8d,xp:250}};
 function create(raw,legacyCrimes=0){raw=raw&&typeof raw==='object'?raw:{};return {xp:Number.isSafeInteger(raw.xp)&&raw.xp>=0?Math.min(raw.xp,10000000):0,crimes:Number.isSafeInteger(raw.crimes)&&raw.crimes>=0?raw.crimes:Math.max(0,Number.isSafeInteger(legacyCrimes)?legacyCrimes:0),claimed:Array.isArray(raw.claimed)?[...new Set(raw.claimed.filter(n=>Number.isInteger(n)&&n>=0&&n<100))]:[]};}
 function awardStory(p,index){if(!Number.isInteger(index)||index<0||index>=100||p.claimed.includes(index))return false;p.claimed.push(index);p.xp=Math.min(10000000,p.xp+25);return true;}
 function awardCrime(p){p.crimes++;p.xp=Math.min(10000000,p.xp+40);}
 function rank(p){return Math.floor(p.xp/100)+1;}
 function unlocked(p,tint){return !!tints[tint]&&p.xp>=tints[tint].xp;}
 return {tints,create,awardStory,awardCrime,rank,unlocked};
});
