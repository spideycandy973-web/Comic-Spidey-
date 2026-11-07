/* Gentle procedural deformation for the supplied static Doc Ock tentacle meshes.
 * Coordinates are the original GLB mesh coordinates (Z up, Y pointing backward).
 * It is not a skeletal rig; the actor's body remains static. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicTentacles=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function deform(base,out,time,windup){const intensity=windup?1.5:1;for(let i=0;i<base.length;i+=3){const x=base[i],y=base[i+1],z=base[i+2],weight=Math.max(0,Math.min(1,(y-.2)/1.5)),phase=time*2+x*1.4+z*1.3;out[i]=x+weight*.12*intensity*Math.sin(phase);out[i+1]=y+weight*.05*intensity*Math.cos(phase*.8);out[i+2]=z+weight*.11*intensity*Math.sin(phase+1.1);}}
 return {deform};
});
