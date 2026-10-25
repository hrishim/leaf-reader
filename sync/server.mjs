import http from 'node:http';
import {createHash,randomBytes,timingSafeEqual,randomUUID} from 'node:crypto';
import {fileURLToPath} from 'node:url';import path from 'node:path';
import {SyncEngine} from './engine.mjs';import {JsonFileStore} from './store.mjs';import {CredentialVault} from './vault.mjs';import {InoreaderOAuth} from './oauth.mjs';import {AccountService} from './service.mjs';
function equal(a,b){return timingSafeEqual(createHash('sha256').update(String(a)).digest(),createHash('sha256').update(String(b)).digest())}
function json(res,status,value){res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(JSON.stringify(value))}
async function body(req){let size=0,text='';for await(const chunk of req){size+=chunk.length;if(size>65536)throw Object.assign(new Error('Request too large'),{status:413});text+=chunk}try{return JSON.parse(text||'{}')}catch{throw Object.assign(new Error('Invalid JSON'),{status:400})}}
export function createSyncHandler({service,ownerKey,origin,clock=()=>Date.now()}){
 if(typeof ownerKey!=='string'||ownerKey.length<32)throw new Error('Set a strong backend owner access key (at least 32 characters)');
 const sessions=new Map(),oauthSessions=new Map();
 const expectedOrigin=()=>typeof origin==='function'?origin():origin;
 return async(req,res)=>{try{
  const base=new URL(expectedOrigin());if(base.protocol!=='https:'&&!(base.protocol==='http:'&&['127.0.0.1','localhost','[::1]'].includes(base.hostname)))throw new Error('Backend requires HTTPS');
  if(req.headers.host!==base.host)return json(res,400,{error:'Unexpected request host'});
  const url=new URL(req.url,base);if(req.headers.origin&&req.headers.origin!==base.origin)return json(res,403,{error:'Unexpected request origin'});
  res.setHeader('Referrer-Policy','no-referrer');res.setHeader('Content-Security-Policy',"default-src 'none'; frame-ancestors 'none'; base-uri 'none'");
  for(const [id,expiry]of sessions)if(expiry<=clock())sessions.delete(id);
  for(const [id,p]of oauthSessions)if(p.expires<=clock())oauthSessions.delete(id);
  const bearer=req.headers.authorization?.startsWith('Bearer ')?req.headers.authorization.slice(7):null;
  const cookie=req.headers.cookie?.split(';').map(s=>s.trim()).find(s=>s.startsWith('leaf_session='))?.slice(13);
  const native=!!bearer&&equal(bearer,ownerKey),browser=!!cookie&&sessions.has(cookie),authenticated=native||browser;
  const mutating=!['GET','HEAD'].includes(req.method);
  if(mutating&&!native&&req.headers.origin!==base.origin)return json(res,403,{error:'Same-origin browser request required'});
  if(url.pathname==='/session'&&req.method==='POST'){
   if(!req.headers['content-type']?.startsWith('application/json'))return json(res,415,{error:'Use JSON'});
   const data=await body(req);if(!equal(data.key||'',ownerKey))return json(res,401,{error:'Access key rejected'});
   if(sessions.size>=100)return json(res,429,{error:'Too many sessions'});
   const id=randomBytes(32).toString('base64url');sessions.set(id,clock()+43200000);
   res.setHeader('Set-Cookie',`leaf_session=${id}; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200${base.protocol==='https:'?'; Secure':''}`);return json(res,200,{authenticated:true});
  }
  if(!authenticated)return json(res,401,{error:'Sign in to the Leaf Reader sync backend'});
  if(url.pathname==='/session'&&req.method==='DELETE'){if(cookie)sessions.delete(cookie);res.setHeader('Set-Cookie','leaf_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0');return json(res,200,{signedOut:true})}
  if(url.pathname==='/health'&&req.method==='GET')return json(res,200,{service:'Leaf Reader Sync',authenticated:true});
  if(url.pathname==='/providers'&&req.method==='GET')return json(res,200,{providers:service.providers()});
  if(url.pathname==='/accounts'&&req.method==='GET')return json(res,200,{accounts:service.list()});
  if(url.pathname==='/accounts'&&req.method==='POST'){const data=await body(req);const account=await service.connect({id:randomUUID(),provider:data.provider,label:data.label,username:data.username,password:data.password});return json(res,201,{account})}
  if(url.pathname==='/oauth/inoreader/start'&&req.method==='POST'){
   // OAuth callback must be in the same authenticated browser session which initiated it.
   if(!browser)return json(res,400,{error:'Open backend sign-in in your browser before starting OAuth'});
   const id=randomUUID(),authorizeURL=service.beginInoreader(id),state=new URL(authorizeURL).searchParams.get('state');oauthSessions.set(state,{id,session:cookie,expires:clock()+600000});return json(res,200,{authorizeURL});
  }
  if(url.pathname==='/oauth/inoreader/callback'&&req.method==='GET'){
   const state=url.searchParams.get('state'),pending=oauthSessions.get(state);oauthSessions.delete(state);
   if(!browser||!pending||pending.session!==cookie)return json(res,400,{error:'OAuth session expired or changed'});
   await service.completeInoreader(pending.id,{code:url.searchParams.get('code'),state});res.writeHead(303,{'Location':'/connected','Cache-Control':'no-store'});return res.end();
  }
  if(url.pathname==='/connected'&&req.method==='GET')return json(res,200,{connected:true,message:'Account authorized. Return to Leaf Reader to synchronize.'});
  const match=url.pathname.match(/^\/accounts\/([a-zA-Z0-9_-]{1,100})(?:\/(sync|changes))?$/);
  if(!match)return json(res,404,{error:'Unknown sync endpoint'});
  const [,id,action]=match;
  if(req.method==='GET'&&!action)return json(res,200,{account:service.snapshot(id)});
  if(req.method==='DELETE'&&!action){await service.disconnect(id);return json(res,200,{disconnected:true})}
  if(req.method==='POST'&&action==='sync')return json(res,200,{account:await service.refresh(id)});
  if(req.method==='POST'&&action==='changes'){const data=await body(req);if(!Array.isArray(data.changes)||!data.changes.length||data.changes.length>1000)return json(res,400,{error:'Supply 1–1000 reading changes'});for(const c of data.changes){if(!c||typeof c.itemId!=='string'||!['read','saved'].includes(c.field)||typeof c.value!=='boolean')return json(res,400,{error:'Invalid reading change'})}for(const c of data.changes)await service.change(id,c);return json(res,202,{account:service.snapshot(id)})}
  return json(res,405,{error:'Method not supported'});
 }catch(error){const status=[400,401,403,404,413,429].includes(error.status)?error.status:502;return json(res,status,{error:status===401?'Provider sign-in expired':status===429?'Provider rate limit reached':status===413?'Request too large':'Request failed; saved and pending data are retained.'})}};
}
export async function configuredService(env=process.env){
 if(!env.LEAF_SYNC_DATA_DIR||!path.isAbsolute(env.LEAF_SYNC_DATA_DIR))throw new Error('Set an absolute backend data directory');
 const key=Buffer.from(env.LEAF_VAULT_KEY||'','base64');if(key.length!==32)throw new Error('Set a base64-encoded 32-byte LEAF_VAULT_KEY in backend secrets');
 const root=env.LEAF_SYNC_DATA_DIR,engine=await new SyncEngine(new JsonFileStore(path.join(root,'library'))).load(),vault=new CredentialVault(new JsonFileStore(path.join(root,'credentials')),key);
 let oauth;if(env.INOREADER_CLIENT_ID||env.INOREADER_CLIENT_SECRET){if(!env.LEAF_SYNC_ORIGIN?.startsWith('https://'))throw new Error('Inoreader OAuth requires an HTTPS backend origin');oauth=new InoreaderOAuth({clientId:env.INOREADER_CLIENT_ID,clientSecret:env.INOREADER_CLIENT_SECRET,redirectURI:new URL('/oauth/inoreader/callback',env.LEAF_SYNC_ORIGIN).href,tokenStore:vault})}
 const service=new AccountService({engine,vault,oauth,providerConfiguration:env.FRESHRSS_API_BASE?{freshrss:{base:env.FRESHRSS_API_BASE}}:{}});await service.restore();return service;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const env=process.env,origin=env.LEAF_SYNC_ORIGIN||'http://127.0.0.1:8781';const service=await configuredService(env);const handler=createSyncHandler({service,ownerKey:env.LEAF_OWNER_KEY,origin});const port=Number(env.LEAF_SYNC_PORT||8781);const server=http.createServer(handler);server.listen(port,'127.0.0.1',()=>process.stdout.write('Leaf Reader sync backend listening on loopback. No public endpoint is configured automatically.\n'));
}
