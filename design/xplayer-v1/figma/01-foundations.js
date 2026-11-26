/**
 * createVariableCollection
 *
 * Creates a new Figma variable collection with the specified name and modes.
 * If `modeNames` has more than one entry, the first mode is renamed from
 * Figma's default "Mode 1" to the first name, and additional modes are added.
 *
 * @param {string} name - The display name of the collection (e.g. "Color", "Spacing").
 * @param {string[]} modeNames - Ordered list of mode names (e.g. ["Light", "Dark"] or ["Value"]).
 * @returns {Promise<{
 *   collection: VariableCollection,
 *   modeIds: Record<string, string>
 * }>}
 *   `modeIds` maps each mode name to its modeId string.
 */
async function createVariableCollection(name, modeNames) {
  if (!modeNames || modeNames.length === 0) {
    throw new Error('createVariableCollection: modeNames must have at least one entry.')
  }

  // Create the collection — Figma always creates it with one mode named "Mode 1".
  const collection = figma.variables.createVariableCollection(name)

  // modeIds accumulator
  const modeIds = {}

  // Rename the default first mode
  const defaultMode = collection.modes[0]
  collection.renameMode(defaultMode.modeId, modeNames[0])
  modeIds[modeNames[0]] = defaultMode.modeId

  // Add additional modes
  for (let i = 1; i < modeNames.length; i++) {
    const newModeId = collection.addMode(modeNames[i])
    modeIds[modeNames[i]] = newModeId
  }

  return { collection, modeIds }
}

/**
 * createSemanticTokens
 *
 * Creates a batch of Figma variables in the given collection, one per entry in
 * `tokenMap`. Supports raw values, variable alias references, code syntax, and
 * scopes. Returns a map of token name → Variable for use in subsequent steps.
 *
 * @param {VariableCollection} collection - The target variable collection.
 * @param {Record<string, string>} modeIds - Map of {modeName: modeId} from createVariableCollection.
 * @param {Array<{
 *   name: string,
 *   type: 'COLOR' | 'FLOAT' | 'STRING' | 'BOOLEAN' | 'TIMING' | 'EASING',
 *   values: Record<string, string | number | boolean | MotionEasing | {type: 'VARIABLE_ALIAS', id: string}>,
 *   scopes?: VariableScope[],
 *   codeSyntax?: {WEB?: string, ANDROID?: string, iOS?: string}
 * }>} tokenMap - Ordered list of token definitions.
 *   - `name`: Variable name using slash hierarchy (e.g. "color/bg/primary").
 *   - `type`: Figma variable type.
 *   - `values`: Map of {modeName: value}. Values can be raw (hex string for COLOR,
 *     number for FLOAT) or alias objects {type: 'VARIABLE_ALIAS', id: variableId}.
 *     For COLOR, raw values are accepted as hex strings ("#rrggbb" or "#rrggbbaa")
 *     and converted to {r, g, b, a} automatically.
 *   - `scopes`: Array of VariableScope strings. Omit to use [] (hidden/primitive).
 *   - `codeSyntax`: Platform code syntax strings. Omit to skip.
 * @returns {Promise<{variables: Record<string, Variable>}>}
 *   `variables` maps each token name to its created Variable object.
 */
async function createSemanticTokens(collection, modeIds, tokenMap) {
  const variables = {}

  for (const token of tokenMap) {
    // Create the variable
    const variable = figma.variables.createVariable(token.name, collection, token.type)

    // Set values for each mode
    for (const [modeName, rawValue] of Object.entries(token.values)) {
      const modeId = modeIds[modeName]
      if (!modeId) {
        throw new Error(
          `createSemanticTokens: mode "${modeName}" not found in modeIds for token "${token.name}". ` +
            `Available modes: ${Object.keys(modeIds).join(', ')}`,
        )
      }

      let value = rawValue

      // Convert hex strings to Figma RGBA for COLOR type
      if (token.type === 'COLOR' && typeof rawValue === 'string' && rawValue.startsWith('#')) {
        value = hexToFigmaColor(rawValue)
      }

      variable.setValueForMode(modeId, value)
    }

    // Set scopes (default: empty array = hidden from property pickers / primitives)
    variable.scopes = token.scopes || []

    // Set code syntax per platform
    if (token.codeSyntax) {
      if (token.codeSyntax.WEB) {
        variable.setVariableCodeSyntax('WEB', token.codeSyntax.WEB)
      }
      if (token.codeSyntax.ANDROID) {
        variable.setVariableCodeSyntax('ANDROID', token.codeSyntax.ANDROID)
      }
      if (token.codeSyntax.iOS) {
        variable.setVariableCodeSyntax('iOS', token.codeSyntax.iOS)
      }
    }

    variables[token.name] = variable
  }

  return { variables }
}

/**
 * Converts a hex color string to a Figma RGBA object.
 * Supports "#rgb", "#rrggbb", and "#rrggbbaa".
 *
 * @param {string} hex
 * @returns {{ r: number, g: number, b: number, a: number }}
 */
function hexToFigmaColor(hex) {
  let h = hex.replace('#', '')

  // Expand shorthand #rgb → #rrggbb
  if (h.length === 3) {
    h = h
      .split('')
      .map((c) => c + c)
      .join('')
  }

  const r = parseInt(h.substring(0, 2), 16) / 255
  const g = parseInt(h.substring(2, 4), 16) / 255
  const b = parseInt(h.substring(4, 6), 16) / 255
  const a = h.length === 8 ? parseInt(h.substring(6, 8), 16) / 255 : 1

  return { r, g, b, a }
}

const tokens={"version":"1.0.0","confirmedOn":"2026-10-25","primaryTheme":"nocturne","sourceOfTruth":"经用户确认的 HTML 交互设计稿","themes":{"nocturne":{"name":"A · 静夜","status":"primary","values":{"bg":"#0f1915","surface":"#14211b","raised":"#1b2a22","border":"#29382e","fg":"#edf2e9","muted":"#8d9c8d","quiet":"#627566","accent":"#b5e6bb","accent-ink":"#17371e","accent-wash":"#b5e6bb13","radius":"16px","sidebar":"216px","header":"76px"}},"paper":{"name":"B · 留白","status":"retained-alternative","values":{"bg":"#f6f4ed","surface":"#fffef9","raised":"#ecebe3","border":"#dfdfd5","fg":"#263531","muted":"#849087","quiet":"#9fa79d","accent":"#3567cd","accent-ink":"#fff","accent-wash":"#3567cd0c","radius":"9px","sidebar":"216px","header":"76px"}},"signal":{"name":"C · 信号","status":"retained-alternative","values":{"bg":"#181b1b","surface":"#202525","raised":"#2a3030","border":"#39403d","fg":"#f0f1e8","muted":"#9aaba1","quiet":"#71857a","accent":"#efb25b","accent-ink":"#30210a","accent-wash":"#efb25b12","radius":"3px","sidebar":"216px","header":"76px"}}},"spacing":[4,8,12,16,20,24,28,32,36,44,48,60,84],"typography":{"web":["Inter","-apple-system","BlinkMacSystemFont","PingFang SC","Microsoft YaHei","sans-serif"],"figma":{"latin":"Inter","cjk":"Noto Sans SC","note":"Figma 云端未提供 PingFang SC，中文采用 Noto Sans SC；布局以 HTML 为准。"},"roles":{"pageTitle":{"phone":27,"ipad":29,"desktop":29,"tv":39},"sectionTitle":{"phone":18,"ipad":18,"desktop":18,"tv":28},"heroTitle":{"phone":39,"ipad":37,"desktop":44,"tv":65}}},"devices":{"phone":{"width":390,"height":844,"navigation":"bottom","touchTarget":44},"ipad":{"width":1194,"height":834,"navigation":"rail","sidebar":82},"desktop":{"width":1440,"height":960,"navigation":"sidebar","sidebar":216},"tv":{"width":1920,"height":1080,"navigation":"top","focusRing":4,"focusOffset":5}},"motion":{"fast":150,"normal":200,"imageHover":500,"reducedMotion":true}};
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
return {createdNodeIds,mutatedNodeIds,pages,collections,variables,styles,collectionCount:Object.keys(collections).length,variableCount:(await figma.variables.getLocalVariablesAsync()).length,fontMapping:{latin:'Inter',cjk:'Noto Sans SC'}};