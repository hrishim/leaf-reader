// Shared client protocol. This object stores no provider credentials and must only use a trusted backend.
export class SyncClient {
 constructor({base,accessKey,fetcher=fetch}){const u=new URL(base);if(u.protocol!=='https:'&&!(u.protocol==='http:'&&['127.0.0.1','localhost','[::1]'].includes(u.hostname)))throw new Error('Use an HTTPS backend');if(u.username||u.password||u.search||u.hash)throw new Error('Invalid backend address');this.base=u.origin;this.accessKey=accessKey;this.fetcher=fetcher;}
 async request(path,{method='GET',body}={}){if(!path.startsWith('/')||path.startsWith('//'))throw new Error('Invalid backend route');const headers={Accept:'application/json'};if(this.accessKey)headers.Authorization='Bearer '+this.accessKey;if(body!==undefined)headers['Content-Type']='application/json';const response=await this.fetcher(this.base+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),credentials:'include',redirect:'error',signal:AbortSignal.timeout(45000)});if(!response.ok){const e=new Error(response.status===401?'Sign in to the sync backend again':response.status===429?'Sync rate limit reached':'Sync backend request failed');e.status=response.status;throw e}return response.json();}
 signIn(key){return this.request('/session',{method:'POST',body:{key}})}
 list(){return this.request('/accounts')}
 providers(){return this.request('/providers')}
 snapshot(id){return this.request('/accounts/'+encodeURIComponent(id))}
 refresh(id){return this.request('/accounts/'+encodeURIComponent(id)+'/sync',{method:'POST'})}
 change(id,changes){return this.request('/accounts/'+encodeURIComponent(id)+'/changes',{method:'POST',body:{changes}})}
 connect(provider,credentials){return this.request('/accounts',{method:'POST',body:{provider,...credentials}})}
 startInoreader(){return this.request('/oauth/inoreader/start',{method:'POST'})}
 disconnect(id){return this.request('/accounts/'+encodeURIComponent(id),{method:'DELETE'})}
 signOut(){return this.request('/session',{method:'DELETE'})}
}
