/* Original synthesized sound effects; no audio assets or network access required. */
(function(root){'use strict';let ctx=null,enabled=true;
 function configure(value){enabled=!!value;if(!enabled&&ctx&&ctx.state==='running')ctx.suspend().catch(()=>{});}
 function unlock(){if(!enabled)return;try{const C=root.AudioContext||root.webkitAudioContext;if(!C)return;if(!ctx)ctx=new C();if(ctx.state==='suspended')ctx.resume().catch(()=>{});}catch(e){/* audio is optional */}}
 function play(kind){if(!enabled||!ctx||ctx.state!=='running')return;try{const tones={jump:[450,610,.12],swing:[250,680,.18],hit:[155,70,.13],web:[780,340,.15],dodge:[440,230,.12],damage:[160,55,.25],success:[520,850,.3]};const t=tones[kind];if(!t)return;const now=ctx.currentTime,osc=ctx.createOscillator(),gain=ctx.createGain();osc.type=kind==='hit'||kind==='damage'?'square':'sine';osc.frequency.setValueAtTime(t[0],now);osc.frequency.exponentialRampToValueAtTime(t[1],now+t[2]);gain.gain.setValueAtTime(.0001,now);gain.gain.exponentialRampToValueAtTime(.07,now+.015);gain.gain.exponentialRampToValueAtTime(.0001,now+t[2]);osc.connect(gain);gain.connect(ctx.destination);osc.start(now);osc.stop(now+t[2]+.01);}catch(e){/* audio is optional */}}
 root.ComicAudio={configure,unlock,play};
})(window);
