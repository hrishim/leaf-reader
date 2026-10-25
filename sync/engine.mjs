import {validateChange,articleID} from './http.mjs';
export class SyncEngine {
 constructor(store){this.store=store;this.adapters=new Map();this.locks=new Map();}
 async load(){this.state=await this.store.load()||{version:1,accounts:{},revision:0};if(this.state.version!==1)throw new Error('Unsupported sync-state version');return this;}
 async attach(account,adapter){if(!/^[a-zA-Z0-9_-]{1,100}$/.test(account.id)||['__proto__','constructor','prototype'].includes(account.id))throw new Error('Invalid account ID');this.adapters.set(account.id,adapter);if(!this.state.accounts[account.id])this.state.accounts[account.id]={id:account.id,provider:account.provider,label:account.label||account.provider,feeds:[],items:{},pending:{},lastSync:null,error:null};else if(this.state.accounts[account.id].provider!==account.provider)throw new Error('Account provider cannot change');await this.save();}
 account(id){const a=this.state.accounts[id];if(!a)throw new Error('Unknown account');return a;}
 async save(){await this.store.save(this.state);}
 async set(accountId,itemId,field,value){const a=this.account(accountId);itemId=articleID(itemId);validateChange({itemId,field,value});if(!a.items[itemId])throw new Error('Article is not in this account');const revision=++this.state.revision;const change={itemId,field,value,revision};a.pending[itemId+':'+field]=change;a.items[itemId][field]=value;await this.save();return change;}
 snapshot(id){return structuredClone(this.account(id));}
 sync(id){if(this.locks.has(id))return this.locks.get(id);const run=this.run(id).finally(()=>this.locks.delete(id));this.locks.set(id,run);return run;}
 async run(id){const a=this.account(id),adapter=this.adapters.get(id);if(!adapter)throw new Error('Account needs sign-in');try{
   const changes=Object.values(a.pending).sort((x,y)=>x.revision-y.revision);
   if(changes.length)await adapter.push(changes);
   // A failed or truncated pull never commits a partial replacement of the server state.
   const remote=await adapter.pull();if(!Array.isArray(remote.feeds)||!Array.isArray(remote.items))throw new Error('Invalid account snapshot');
   const next=structuredClone(a.items);for(const item of remote.items){const key=articleID(item.id);if(typeof item.read!=='boolean'||typeof item.saved!=='boolean')throw new Error('Missing remote item state');next[key]={...next[key],...item,id:key,accountId:id};}
   if(remote.statesComplete===true){if(!Array.isArray(remote.unreadIDs)||!Array.isArray(remote.savedIDs))throw new Error('Incomplete reading-state snapshot');const unread=new Set(remote.unreadIDs),saved=new Set(remote.savedIDs);for(const item of Object.values(next)){item.read=!unread.has(item.id);item.saved=saved.has(item.id)}}
   for(const c of changes){const key=c.itemId+':'+c.field;if(a.pending[key]?.revision===c.revision&&next[c.itemId]?.[c.field]===c.value)delete a.pending[key]}
   // Edits made while awaiting provider requests override the older response and remain queued.
   for(const change of Object.values(a.pending))if(next[change.itemId])next[change.itemId][change.field]=change.value;
   a.items=next;a.feeds=remote.feeds;a.lastSync=new Date().toISOString();a.error=Object.keys(a.pending).length?{kind:'pending',message:'Some reading changes are waiting for provider confirmation.'}:null;await this.save();return this.snapshot(id);
  }catch(error){a.error={kind:error.status===401?'reauthenticate':error.status===429?'rate-limit':'sync-failed',message:'Sync did not complete; pending changes are retained.'};await this.save();throw error;}}
 async disconnect(id){if(this.locks.has(id))throw new Error('Wait for the current sync before disconnecting');this.adapters.delete(id);delete this.state.accounts[id];await this.save();}
}
