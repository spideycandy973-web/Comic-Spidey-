/* Standard Gamepad API mapping, with dead zones and button edge detection. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicGamepad=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const names={jump:0,dodge:1,attack:2,web:3,talk:4,camera:5,swing:7,pause:9};
 function axis(value){value=Number.isFinite(value)?Math.max(-1,Math.min(1,value)):0;return Math.abs(value)<.18?0:Math.sign(value)*Math.min(1,(Math.abs(value)-.18)/.82);}
 function sample(previous,pad){const connected=!!pad&&pad.connected!==false&&pad.mapping==='standard',held={},pressed={},released={};for(const [name,index] of Object.entries(names)){held[name]=connected&&!!((pad.buttons||[])[index]&&(pad.buttons||[])[index].pressed);pressed[name]=held[name]&&!previous[name];released[name]=!held[name]&&!!previous[name];}return {connected,held,pressed,released,x:connected?axis((pad.axes||[])[0]):0,z:connected?axis((pad.axes||[])[1]):0,lookX:connected?axis((pad.axes||[])[2]):0,lookY:connected?axis((pad.axes||[])[3]):0};}
 return {sample};
});
