// Copy this script to a Citizen Maker checkout; see godot/README.md for dependencies.
import fs from 'node:fs/promises';import {fileURLToPath} from 'node:url';import {GLTFExporter} from 'three/addons/exporters/GLTFExporter.js';
globalThis.document={createElement:()=>({width:0,height:0,getContext:()=>({createRadialGradient:()=>({addColorStop(){}}),fillRect(){}})})};
const {makePerson}=await import('./js/people.js');const {forExport,bake}=await import('./js/export-pack.js');
const origFetch=globalThis.fetch;globalThis.fetch=async(url,...rest)=>{if(String(url).startsWith('file:')){const buf=await fs.readFile(fileURLToPath(url));return new Response(buf);}return origFetch(url,...rest);};
globalThis.FileReader=class {readAsArrayBuffer(blob){blob.arrayBuffer().then(b=>{this.result=b;this.onloadend?.();});}readAsDataURL(blob){blob.arrayBuffer().then(b=>{this.result='data:'+blob.type+';base64,'+Buffer.from(b).toString('base64');this.onloadend?.();});}};
const specs = [
  {body:{age:32,sex:0.08,weight:0.32,muscle:0.35,height:0.35}, skin:0xb78361, top:0x286e6b, bottom:0x454052, hair:0x241c16, hairStyle:'ponytail', topType:'tee'},
  {body:{age:54,sex:0.88,weight:0.7,muscle:0.4,height:0.6}, skin:0x654232, top:0x73622f, bottom:0x313b47, hair:0x554d44, hairStyle:'curly', topType:'turtleneck'}
];
for (let i=0; i<specs.length; i++) {
 const p=await makePerson({render:'realistic',style:'real', ...specs[i]});
 for(const b of p.sk.bones)b.name=b.name.replaceAll('.','_DOT_');
 p.motion.pose('idle',0);const nodes=p.sk.bones.map(obj=>({obj,name:obj.name,rest:{q:obj.quaternion.toArray(),p:obj.position.toArray()}}));
 const clips=['walk','run'].map(name=>bake(name,1/p.motion.cycle(name),nodes,t=>p.motion.pose(name,t)));
 p.motion.pose('idle',0);
 const root=forExport(p.group,p.body.P.stature/1.7);const binary=await new GLTFExporter().parseAsync(root,{binary:true,animations:clips});
 await fs.writeFile(`${process.env.OUTPUT_DIR || '.'}/citizen${i+3}.glb`,new Uint8Array(binary));console.log('Generated',i+3,binary.byteLength);
}
