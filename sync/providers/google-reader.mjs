import {transport,articleID,validateChange} from '../http.mjs';
export function shortID(id){id=articleID(id);const prefix='tag:google.com,2005:reader/item/';if(id.startsWith(prefix))return BigInt.asIntN(64,BigInt('0x'+id.slice(prefix.length))).toString();if(!/^-?\d+$/.test(id))throw new Error('Invalid Google Reader article ID');return BigInt(id).toString();}
export function googleReader({base,headers,fetcher,maxPages=100}){
 const request=transport(base,headers,fetcher);
 async function pages(path,key){let result=[],cursor,seen=new Set();for(let page=0;page<maxPages;page++){const glue=path.includes('?')?'&':'?';const response=await request(path+(cursor?glue+'c='+encodeURIComponent(cursor):''));if(!response||typeof response!=='object')throw new Error('Invalid provider response');result.push(...(response[key]||[]));if(!response.continuation)return result;cursor=response.continuation;if(seen.has(cursor))throw new Error('Repeated pagination cursor');seen.add(cursor)}throw new Error('Sync exceeds page limit; previous snapshot kept');}
 const tag=field=>'user/-/state/com.google/'+(field==='read'?'read':'starred');
 return {
  async pull(){
   const subscription=await request('reader/api/0/subscription/list');if(!Array.isArray(subscription?.subscriptions))throw new Error('Invalid subscription list');
   const feeds=subscription.subscriptions.map(f=>({id:articleID(f.id),name:f.title||f.url||f.id,url:f.url||f.id.replace(/^feed\//,''),folders:(f.categories||[]).map(c=>c.label).filter(Boolean)}));
   const raw=await pages('reader/api/0/stream/contents/'+encodeURIComponent('user/-/state/com.google/reading-list')+'?n=100','items');
   // State-only streams also update locally cached older items, without downloading their bodies again.
   const unread=await pages('reader/api/0/stream/items/ids?s='+encodeURIComponent('user/-/state/com.google/reading-list')+'&xt='+encodeURIComponent(tag('read'))+'&n=1000','itemRefs');
   const starred=await pages('reader/api/0/stream/items/ids?s='+encodeURIComponent(tag('saved'))+'&n=1000','itemRefs');
   const unreadIDs=unread.map(x=>shortID(x.id)),savedIDs=starred.map(x=>shortID(x.id));const u=new Set(unreadIDs),s=new Set(savedIDs);
   const items=raw.map(a=>({id:shortID(a.id),feedId:a.origin?.streamId||'',title:a.title||'Untitled',url:a.canonical?.[0]?.href||a.alternate?.[0]?.href||'',contentHTML:a.summary?.content||a.content?.content||'',date:a.published?new Date(a.published*1000).toISOString():'',author:a.author||'',read:!u.has(shortID(a.id)),saved:s.has(shortID(a.id))}));
   return {feeds,items,unreadIDs,savedIDs,statesComplete:true};
  },
  async push(changes){for(const c of changes){validateChange(c);const form={i:shortID(c.itemId),[c.value?'a':'r']:tag(c.field)};const result=await request('reader/api/0/edit-tag',{method:'POST',form});if(result!=='OK')throw new Error('Provider did not acknowledge state change')}},
  request
 };
}
export function inoreader({accessToken,fetcher}){return googleReader({base:'https://www.inoreader.com/',headers:async()=>({Authorization:'Bearer '+await accessToken()}),fetcher});}
export async function freshRSS({base,username,apiPassword,fetcher}){
 const request=transport(base,async()=>({}),fetcher);const text=await request('accounts/ClientLogin',{method:'POST',form:{Email:username,Passwd:apiPassword}});const token=String(text).match(/^Auth=(.+)$/m)?.[1]?.trim();if(!token)throw new Error('FreshRSS sign-in failed');return googleReader({base,headers:async()=>({Authorization:'GoogleLogin auth='+token}),fetcher});
}
