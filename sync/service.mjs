import {createAdapter,providerCatalogue} from './providers/index.mjs';
// Host-neutral service boundary: the HTTP host must authenticate the user and map to an owner-scoped instance.
// No method accepts an arbitrary third-party URL or returns provider credentials to a client.
export class AccountService {
 constructor({engine,vault,oauth,providerConfiguration={}}){Object.assign(this,{engine,vault,oauth,providerConfiguration});}
 list(){return Object.values(this.engine.state.accounts).map(a=>({id:a.id,provider:a.provider,label:a.label,lastSync:a.lastSync,pending:Object.keys(a.pending).length,error:a.error}));}
 providers(){return providerCatalogue.map(p=>({...p,configured:p.id==='inoreader'?!!this.oauth:p.id==='freshrss'?!!this.providerConfiguration.freshrss?.base:['feedbin','newsblur'].includes(p.id)}));}
 async connect({id,provider,label,username,password}){
  if(!['feedbin','newsblur','freshrss'].includes(provider))throw new Error('Use the registered OAuth flow for this provider');
  if(this.engine.state.accounts[id])throw new Error('Account ID already exists');
  if(!username||!password)throw new Error('Enter account credentials');
  const config=this.providerConfiguration[provider]||{};
  if(provider==='freshrss'&&!config.base)throw new Error('FreshRSS server must be configured on the trusted backend');
  const adapter=await createAdapter(provider,{...config,username,password,apiPassword:password});
  const initial=await adapter.pull(); // Confirm credentials before replacing or exposing any account.
  await this.vault.set(id,provider==='newsblur'?{session:adapter.session}:{username,password});
  try{await this.engine.attach({id,provider,label},adapter);const cached={...adapter,pull:async()=>initial};this.engine.adapters.set(id,cached);try{await this.engine.sync(id)}finally{this.engine.adapters.set(id,adapter)}}catch(error){await this.vault.delete(id);if(this.engine.state.accounts[id])await this.engine.disconnect(id);throw error}
  return this.engine.snapshot(id);
 }
 beginInoreader(id){if(!this.oauth)throw new Error('Leaf Reader Inoreader registration is not configured');if(this.engine.state.accounts[id])throw new Error('Account ID already exists');return this.oauth.begin(id);}
 async completeInoreader(id,callback){if(!this.oauth)throw new Error('Inoreader is not configured');await this.oauth.callback(id,callback);const adapter=await createAdapter('inoreader',{accessToken:()=>this.oauth.accessToken(id)});try{await this.engine.attach({id,provider:'inoreader',label:'Inoreader'},adapter);return await this.engine.sync(id)}catch(error){await this.oauth.disconnect(id);if(this.engine.state.accounts[id])await this.engine.disconnect(id);throw error}}
 async restore(){for(const account of Object.values(this.engine.state.accounts)){try{let config={...this.providerConfiguration[account.provider]};if(account.provider==='inoreader'){if(!this.oauth)continue;config.accessToken=()=>this.oauth.accessToken(account.id)}else{const credentials=await this.vault.get(account.id);if(!credentials)continue;config={...config,...credentials,apiPassword:credentials.password}}const adapter=await createAdapter(account.provider,config);this.engine.adapters.set(account.id,adapter)}catch{account.error={kind:'reauthenticate',message:'Sign in to this account again.'}}}await this.engine.save();}
 async change(id,change){return this.engine.set(id,change.itemId,change.field,change.value)}
 async refresh(id){return this.engine.sync(id)}
 snapshot(id){return this.engine.snapshot(id)}
 async disconnect(id){await this.engine.disconnect(id);if(this.oauth)await this.oauth.disconnect(id);await this.vault.delete(id)}
}
