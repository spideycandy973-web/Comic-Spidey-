/* Responsive normalized positions for six customizable touch controls. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ComicLayout=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 const keys=['move','dodge','webShot','jump','swing','attack'];
 function clamp(value,min,max){return Math.max(min,Math.min(max,value));}
 function point(x,y,width,height,halfWidth,halfHeight){width=Math.max(1,width);height=Math.max(1,height);const hx=Math.min(.5,Math.max(0,halfWidth)/width),hy=Math.min(.5,Math.max(0,halfHeight)/height);return {x:clamp(x/width,hx,1-hx),y:clamp(y/height,hy,1-hy)};}
 function valid(layout){return !!layout&&keys.every(k=>layout[k]&&Number.isFinite(layout[k].x)&&layout[k].x>=0&&layout[k].x<=1&&Number.isFinite(layout[k].y)&&layout[k].y>=0&&layout[k].y<=1);}
 return {keys,point,valid};
});
