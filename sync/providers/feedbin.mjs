import {transport,articleID,validateChange} from '../http.mjs';
export function feedbin({username,password,fetcher,maxPages=100}){
 const request=transport('https://api.feedbin.com/v2/',async()=>({Authorization:'Basic '+Buffer.from(username+':'+password).toString('base64')}),fetcher);
 return {
  async pull(){
   const [subscriptions,unread,starred,tags]=await Promise.all([request('subscriptions.json'),request('unread_entries.json'),request('starred_entries.json'),request('taggings.json')]);if(![subscriptions,unread,starred,tags].every(Array.isArray))throw new Error('Invalid Feedbin snapshot');
   const feeds=subscriptions.map(f=>({id:articleID(f.feed_id),name:f.title||f.feed_url,url:f.feed_url,folders:tags.filter(t=>t.feed_id===f.feed_id).map(t=>t.name)}));
   const unreadIDs=unread.map(articleID),savedIDs=starred.map(articleID),u=new Set(unreadIDs),s=new Set(savedIDs);let rows=[],complete=false;
   for(let page=1;page<=maxPages;page++){const batch=await request('entries.json?per_page=100&page='+page);if(!Array.isArray(batch))throw new Error('Invalid entries response');rows.push(...batch);if(batch.length<100){complete=true;break}}
   if(!complete)throw new Error('Sync exceeds page limit; previous snapshot kept');
   return {feeds,unreadIDs,savedIDs,statesComplete:true,items:rows.map(a=>({id:articleID(a.id),feedId:articleID(a.feed_id),url:a.url||'',title:a.title||'Untitled',date:a.published||'',contentHTML:a.content||'',author:a.author||'',read:!u.has(articleID(a.id)),saved:s.has(articleID(a.id))}))};
  },
  async push(changes){for(const c of changes){validateChange(c);const id=articleID(c.itemId);if(!/^\d+$/.test(id)||!Number.isSafeInteger(Number(id)))throw new Error('Invalid Feedbin entry ID');const field=c.field==='read'?'unread_entries':'starred_entries';const add=c.field==='read'?!c.value:c.value;const result=await request(field+'.json',{method:add?'POST':'DELETE',json:{[field]:[Number(id)]}});if(!Array.isArray(result)||!result.some(x=>articleID(x)===id))throw new Error('Feedbin rejected the item state change')}}
 };
}
