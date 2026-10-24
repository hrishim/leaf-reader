const LeafPreferences={
 defaults:{articleSize:19,interfaceSize:13,font:'serif',spacing:1.85,titleScale:2.1,theme:'system'},
 normalise(value={}){
  const clamp=(v,a,b,d)=>Number.isFinite(Number(v))?Math.max(a,Math.min(b,Number(v))):d;
  return {articleSize:clamp(value.articleSize,14,36,19),interfaceSize:clamp(value.interfaceSize,11,20,13),font:['serif','sans'].includes(value.font)?value.font:'serif',spacing:clamp(value.spacing,1.3,2.2,1.85),titleScale:clamp(value.titleScale,1.3,2.5,2.1),theme:['system','light','dark'].includes(value.theme)?value.theme:'system'};
 }
};
let leafPreferences;
try{leafPreferences=LeafPreferences.normalise(JSON.parse(localStorage.getItem('leaf-preferences')||'null')||{articleSize:Number(localStorage.getItem('leaf-size')||19),theme:localStorage.getItem('leaf-dark')==='1'?'dark':'system'});}catch{leafPreferences={...LeafPreferences.defaults};}
function leafApplyPreferences(save=false){
 const p=leafPreferences,style=document.documentElement.style;
 style.setProperty('--size',p.articleSize+'px');style.setProperty('--ui-size',p.interfaceSize+'px');style.setProperty('--reader-font',p.font==='sans'?'-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif':'Georgia,"Times New Roman",serif');style.setProperty('--reader-spacing',p.spacing);style.setProperty('--title-scale',p.titleScale);
 document.body.classList.toggle('dark',p.theme==='dark'||p.theme==='system'&&matchMedia('(prefers-color-scheme: dark)').matches);
 if(save){try{localStorage.setItem('leaf-preferences',JSON.stringify(p));localStorage.setItem('leaf-size',String(p.articleSize));localStorage.setItem('leaf-dark',document.body.classList.contains('dark')?'1':'0');}catch{toast('Your browser could not save the appearance settings.');}}
}
function leafOpenSettings(){
 let d=document.querySelector('#settingsDialog');
 if(!d){d=document.createElement('dialog');d.id='settingsDialog';d.setAttribute('aria-labelledby','settingsTitle');d.innerHTML=`<h2 id="settingsTitle">Settings</h2><h3>Reading</h3><label>Article text size <output id="articleSizeValue"></output><input id="articleSize" type="range" min="14" max="36" step="1"></label><label>Article font<select id="articleFont"><option value="serif">Serif</option><option value="sans">System sans serif</option></select></label><label>Line spacing <output id="spacingValue"></output><input id="articleSpacing" type="range" min="1.3" max="2.2" step="0.05"></label><label>Title size <output id="titleScaleValue"></output><input id="titleScale" type="range" min="1.3" max="2.5" step="0.1"></label><h3>Appearance</h3><label>Interface text size <output id="interfaceSizeValue"></output><input id="interfaceSize" type="range" min="11" max="20" step="1"></label><label>Theme<select id="appearanceTheme"><option value="system">System</option><option value="light">Light</option><option value="dark">Dark</option></select></label><div class="settingsPreview"><h4>Reading preview · தமிழ்</h4><p>Your article text appears at the selected size and spacing.</p></div><p>Changes apply immediately and are saved in this browser. Subscriptions and reading status stay on this device.</p><footer><button id="resetAppearance">Reset appearance</button><button id="settingsDone" class="primary">Done</button></footer>`;document.body.append(d);
  const bindings={articleSize:'articleSize',interfaceSize:'interfaceSize',articleFont:'font',articleSpacing:'spacing',titleScale:'titleScale',appearanceTheme:'theme'};
  for(const [id,key] of Object.entries(bindings)){d.querySelector('#'+id).oninput=e=>{leafPreferences=LeafPreferences.normalise({...leafPreferences,[key]:e.target.value});leafApplyPreferences(true);leafFillSettings(d);};}
  d.querySelector('#settingsDone').onclick=()=>d.close();d.querySelector('#resetAppearance').onclick=()=>{leafPreferences={...LeafPreferences.defaults};leafApplyPreferences(true);leafFillSettings(d);};
 }
 leafFillSettings(d);d.showModal();
}
function leafFillSettings(d){const p=leafPreferences;for(const [id,key] of Object.entries({articleSize:'articleSize',interfaceSize:'interfaceSize',articleFont:'font',articleSpacing:'spacing',titleScale:'titleScale',appearanceTheme:'theme'}))d.querySelector('#'+id).value=p[key];for(const [id,text] of Object.entries({articleSizeValue:p.articleSize+' px',interfaceSizeValue:p.interfaceSize+' px',spacingValue:p.spacing.toFixed(2),titleScaleValue:p.titleScale.toFixed(1)+'×'}))d.querySelector('#'+id).textContent=text;}
