'use strict';
// Public URLs only. Reading state never leaves this browser.
function leafPublic(raw, base) {
  const u = new URL(raw, base), h = u.hostname.toLowerCase();
  if (u.protocol === 'http:') u.protocol = 'https:';
  if (u.protocol !== 'https:' || u.username || u.password || u.port && u.port !== '443' ||
      !h.includes('.') || /[\[\]:]/.test(h) || /^\d+(?:\.\d+){3}$/.test(h) ||
      /(^|\.)(localhost|local|internal|test|invalid|onion)$/.test(h) ||
      [...u.searchParams.keys()].some(k => /token|auth|key|signature|password|secret/i.test(k))) {
    throw Error('Use a public HTTPS URL without passwords or private feed tokens.');
  }
  u.hash = '';
  return u.href;
}
readerPublic = leafPublic;
const leafRequests = new Map();
async function leafFetch(raw) {
  const url = leafPublic(raw);
  const read = async target => {
    const response = await fetch(target, {credentials:'omit', referrerPolicy:'no-referrer', signal:AbortSignal.timeout(14000)});
    if (!response.ok) throw Error('HTTP '+response.status+(response.status===429?' — please wait before refreshing.':''));
    if (Number(response.headers.get('content-length')) > 2500000) throw Error('Publisher response is too large.');
    const reader = response.body.getReader(), chunks=[];
    let size=0;
    while (true) {
      const {done,value}=await reader.read();
      if (done) break;
      size+=value.length;
      if(size>2500000){await reader.cancel();throw Error('Publisher response is too large.');}
      chunks.push(value);
    }
    const bytes=new Uint8Array(size);let offset=0;
    for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
    return new TextDecoder().decode(bytes);
  };
  try {return await read(url);} catch {
    try {return await read('https://proxy.cors.dev/'+url);}
    catch(e){throw Error('Could not retrieve this public page ('+e.message+'). Try Original, or retry later.');}
  }
}
async function leafApi(action, raw) {
  if(!['feed','article'].includes(action))throw Error('Reading state is stored only in this browser.');
  const url=leafPublic(raw),key=action+url,hit=leafRequests.get(key);
  if(hit && Date.now()-hit.at<60000)return hit.promise;
  const promise=(async()=>{
    if(action==='article')return readerParseArticle(await leafFetch(url),url);
    let current=url;
    for(let i=0;i<3;i++){
      const result=readerParseFeed(await leafFetch(current),current);
      if(!result.discover)return result;
      current=leafPublic(result.discover,current);
    }
    throw Error('Too many feed-discovery redirects. Use the RSS or Atom feed URL.');
  })();
  leafRequests.set(key,{at:Date.now(),promise});
  try{return await promise;}catch(e){leafRequests.delete(key);throw e;}
  finally{if(leafRequests.size>60)leafRequests.delete(leafRequests.keys().next().value);}
}
