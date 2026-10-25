export class ProviderError extends Error {
 constructor(status,message='Provider request failed'){super(`${message} (${status})`);this.name='ProviderError';this.status=status;}
}
export function transport(base,headers,fetcher=fetch){
 const origin=new URL(base);if(origin.protocol!=='https:'||origin.username||origin.password)throw new Error('Provider API must use HTTPS without embedded credentials');
 return async function request(path,{method='GET',form,json}={}){
  const url=new URL(base.replace(/\/$/,'')+'/'+path.replace(/^\//,''));if(url.origin!==origin.origin)throw new Error('Provider origin changed');
  const h={Accept:'application/json',...await headers()};let body;
  if(form){h['Content-Type']='application/x-www-form-urlencoded';body=new URLSearchParams(form)}
  if(json!==undefined){h['Content-Type']='application/json';body=JSON.stringify(json)}
  const r=await fetcher(url,{method,headers:h,body,redirect:'error',signal:AbortSignal.timeout(30000)});
  if(!r.ok)throw new ProviderError(r.status,r.status===401?'Sign in again':r.status===429?'Provider rate limit reached':'Provider request failed');
  if(r.status===204)return null;const text=await r.text();if(!text)return null;try{return JSON.parse(text)}catch{return text}
 };
}
export function articleID(value){
 if(typeof value==='number'&&!Number.isSafeInteger(value))throw new Error('Provider returned an unsafe numeric article ID');
 const s=String(value);if(!s||['undefined','null','__proto__','constructor','prototype'].includes(s))throw new Error('Missing provider article ID');return s;
}
export function validateChange(change){if(!['read','saved'].includes(change.field)||typeof change.value!=='boolean')throw new Error('Invalid reading-state change');articleID(change.itemId);}
