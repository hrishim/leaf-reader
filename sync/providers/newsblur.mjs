import {transport,articleID,validateChange} from '../http.mjs';
export async function newsblur({username,password,session,fetcher=fetch,maxPages=100}){
 if(!session){
  const response=await fetcher('https://newsblur.com/api/login',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({username,password}),redirect:'error',signal:AbortSignal.timeout(30000)});
  if(!response.ok)throw new Error('NewsBlur sign-in failed');const body=await response.json();if(!body.authenticated)throw new Error('NewsBlur sign-in failed');session=response.headers.get('set-cookie')?.match(/(?:^|[,;]\s*)newsblur_sessionid=([^;]+)/)?.[1];if(!session)throw new Error('NewsBlur session missing');
 }
 const request=transport('https://newsblur.com/',async()=>({Cookie:'newsblur_sessionid='+session}),fetcher);
 function folderMap(tree,path=[],result=new Map()) {for(const node of tree||[]){if(typeof node==='number'||typeof node==='string'){result.set(String(node),path);continue}for(const [name,children]of Object.entries(node))folderMap(children,[...path,name],result)}return result;}
 return {
  async pull(){const list=await request('reader/feeds?include_favicons=false');if(!list?.feeds||!Array.isArray(list.folders))throw new Error('Invalid NewsBlur subscriptions');const paths=folderMap(list.folders);const feeds=Object.values(list.feeds).map(f=>({id:articleID(f.id),name:f.feed_title||f.feed_address,url:f.feed_address,folders:paths.get(String(f.id))||[]}));let items=[];
   for(const feed of feeds){let complete=false;for(let page=1;page<=maxPages;page++){const result=await request('reader/feed/'+encodeURIComponent(feed.id)+'?read_filter=all&order=newest&page='+page);if(!Array.isArray(result?.stories))throw new Error('Invalid NewsBlur stories');for(const a of result.stories){if(a.read_status!==0&&a.read_status!==1)throw new Error('NewsBlur reading status missing');items.push({id:articleID(a.story_hash),feedId:feed.id,url:a.story_permalink||'',title:a.story_title||'Untitled',date:a.story_date||'',contentHTML:a.story_content||'',author:a.story_authors||'',read:a.read_status===1,saved:!!a.starred})}if(result.stories.length===0){complete=true;break}}if(!complete)throw new Error('Sync exceeds page limit; previous snapshot kept')}
   return {feeds,items,statesComplete:false};
  },
  async push(changes){for(const c of changes){validateChange(c);const path=c.field==='read'?(c.value?'mark_story_hashes_as_read':'mark_story_hash_as_unread'):(c.value?'mark_story_hash_as_starred':'mark_story_hash_as_unstarred');const result=await request('reader/'+path,{method:'POST',form:{story_hash:articleID(c.itemId)}});if(typeof result!=='object'||result.code!==1)throw new Error('NewsBlur rejected the item state change')}},
  session
 };
}
