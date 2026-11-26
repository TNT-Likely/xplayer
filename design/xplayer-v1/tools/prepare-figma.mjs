import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');const tok=JSON.parse(fs.readFileSync(path.join(root,'tokens/xplayer.tokens.json'),'utf8'));
const helperRoot='/Users/sunxiao/.codex/plugins/cache/openai-curated-remote/figma/16.0.0/skills/figma-generate-library/scripts';
let code=fs.readFileSync(path.join(helperRoot,'createVariableCollection.js'),'utf8')+'\n'+fs.readFileSync(path.join(helperRoot,'createSemanticTokens.js'),'utf8');
code+=`\nconst tokens=${JSON.stringify(tok)};
const createdNodeIds=[],mutatedNodeIds=[],pages={};
const pageNames=['00 · 导览、基础与组件','10 · A 静夜 · 主方案','20 · B C · 保留备选'];
for(const [i,name] of pageNames.entries()){let p=figma.root.children.find(p=>p.name===name);if(!p){if(i===0&&figma.root.children[0].name==='Page 1'){p=figma.root.children[0];p.name=name;mutatedNodeIds.push(p.id)}else{p=figma.createPage();p.name=name;createdNodeIds.push(p.id)}}pages[name]=p.id}
const existing=await figma.variables.getLocalVariableCollectionsAsync();const collections={},variables={};
for(const [theme,t] of Object.entries(tokens.themes)){
 const collectionName='XPlayer / '+t.name;let coll=existing.find(c=>c.name===collectionName);if(coll){collections[theme]=coll.id;continue}
 const made=await createVariableCollection(collectionName,['Value']);coll=made.collection;collections[theme]=coll.id;
 const defs=[];
 for(const [key,val] of Object.entries(t.values)){if(!val.startsWith('#'))continue;defs.push({name:'primitive/'+key,type:'COLOR',values:{Value:val},scopes:[],codeSyntax:{WEB:'var(--'+key+')'}})}
 const raw=(await createSemanticTokens(coll,made.modeIds,defs)).variables;
 const semantic=[];for(const [key,val] of Object.entries(t.values)){if(!val.startsWith('#'))continue;semantic.push({name:'color/'+key,type:'COLOR',values:{Value:{type:'VARIABLE_ALIAS',id:raw['primitive/'+key].id}},scopes:key==='border'?['STROKE_COLOR']:['fg','muted','quiet','accent-ink'].includes(key)?['TEXT_FILL']:['FRAME_FILL','SHAPE_FILL','TEXT_FILL'],codeSyntax:{WEB:'var(--'+key+')'}})}
 const sem=(await createSemanticTokens(coll,made.modeIds,semantic)).variables;variables[theme]=Object.fromEntries(Object.entries(sem).map(([k,v])=>[k,v.id]));
}
let metrics=existing.find(c=>c.name==='XPlayer / Metrics');if(!metrics){const made=await createVariableCollection('XPlayer / Metrics',['Value']);metrics=made.collection;const defs=[...tokens.spacing.map(v=>({name:'space/'+v,type:'FLOAT',values:{Value:v},scopes:['GAP'],codeSyntax:{WEB:v+'px'}})),...[3,7,8,9,12,14,16,18].map(v=>({name:'radius/'+v,type:'FLOAT',values:{Value:v},scopes:['CORNER_RADIUS'],codeSyntax:{WEB:v+'px'}}))];const vv=(await createSemanticTokens(metrics,made.modeIds,defs)).variables;variables.metrics=Object.fromEntries(Object.entries(vv).map(([k,v])=>[k,v.id]))}collections.metrics=metrics.id;
await figma.loadFontAsync({family:'Inter',style:'Regular'});await figma.loadFontAsync({family:'Inter',style:'Medium'});await figma.loadFontAsync({family:'Noto Sans SC',style:'Regular'});await figma.loadFontAsync({family:'Noto Sans SC',style:'Medium'});
const styles={};const existingStyles=await figma.getLocalTextStylesAsync();for(const [role,size] of Object.entries({Caption:10,Metadata:12,Body:14,Label:16,Section:18,Title:28,Hero:44,TV:39})){let s=existingStyles.find(s=>s.name==='XPlayer / '+role);if(!s){s=figma.createTextStyle();s.name='XPlayer / '+role;s.fontName={family:'Noto Sans SC',style:role==='Body'||role==='Caption'||role==='Metadata'?'Regular':'Medium'};s.fontSize=size;s.lineHeight={unit:'PERCENT',value:150}}styles[role]=s.id}
return {createdNodeIds,mutatedNodeIds,pages,collections,variables,styles,collectionCount:Object.keys(collections).length,variableCount:(await figma.variables.getLocalVariablesAsync()).length,fontMapping:{latin:'Inter',cjk:'Noto Sans SC'}};`;
fs.writeFileSync(path.join(root,'figma/01-foundations.js'),code);
console.log('figma/01-foundations.js 已生成');
