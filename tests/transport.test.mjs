import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {execFileSync} from 'node:child_process';
const source=fs.readFileSync(new URL('../web/transport.js',import.meta.url),'utf8');
function context(fetch){return vm.createContext({URL,AbortSignal,TextDecoder,Uint8Array,readerPublic:()=>{},fetch,readerParseFeed:(text,url)=>({items:[{title:text}],url}),readerParseArticle:(text,url)=>({blocks:[{text}],url})});}
test('public URL validation rejects secrets, local addresses and executable URLs',()=>{
  const c=context();vm.runInContext(source,c);
  for(const raw of ['javascript:alert(1)','https://u:p@example.com/feed','http://127.0.0.1/feed','https://example.local/feed','https://[::1]/feed','https://example.com:8443/feed','https://example.com/feed?access_token=secret','https://example.com/feed?password=secret'])assert.throws(()=>c.leafPublic(raw));
  assert.equal(c.leafPublic('/rss','https://example.com/news'),'https://example.com/rss');
  assert.equal(c.leafPublic('http://example.com/feed#fragment'),'https://example.com/feed');
});
test('failed cross-origin reads use only the public relay without credentials',async()=>{
  const calls=[];const c=context(async(url,options)=>{calls.push({url,options});if(!url.startsWith('https://proxy.cors.dev/'))throw Error('CORS');return new Response('feed text');});vm.runInContext(source,c);
  const result=await c.leafApi('feed','https://example.com/rss');
  assert.equal(result.items[0].title,'feed text');assert.equal(calls.length,2);
  assert.equal(calls[1].url,'https://proxy.cors.dev/https://example.com/rss');
  assert.equal(calls[1].options.credentials,'omit');assert.equal(calls[1].options.referrerPolicy,'no-referrer');
  await c.leafApi('feed','https://example.com/rss');assert.equal(calls.length,2);
  await assert.rejects(c.leafApi('state','https://example.com'),/only in this browser/);
});
test('failed requests are not cached and can be retried',async()=>{
  let available=false;const c=context(async()=>{if(!available)throw Error('offline');return new Response('article');});vm.runInContext(source,c);
  await assert.rejects(c.leafApi('article','https://example.com/story'));
  available=true;assert.equal((await c.leafApi('article','https://example.com/story')).blocks[0].text,'article');
});
test('JavaScript parses and app shell assets exist with relative Pages paths',()=>{
  for(const file of ['reader.js','reader-engine.js','transport.js','sw.js'])execFileSync(process.execPath,['--check',new URL('../web/'+file,import.meta.url).pathname]);
  const html=fs.readFileSync(new URL('../web/index.html',import.meta.url),'utf8');
  assert.ok(!html.includes('/api/reader'));assert.ok(!html.includes('Continue with ChatGPT'));
  for(const match of html.matchAll(/(?:src|href)="([^"$]+)"/g)){const url=match[1];if(url.startsWith('http')||url.startsWith('#'))continue;assert.ok(!url.startsWith('/'),url);assert.ok(fs.existsSync(new URL('../web/'+url,import.meta.url)),url);}
});
