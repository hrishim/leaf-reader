import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const engine=fs.readFileSync(new URL('../web/reader-engine.js',import.meta.url),'utf8');
function context(){const c=vm.createContext({URL});vm.runInContext(engine,c);return c;}
test('Hindu Tamil RSS article body is usable without fetching the oversized website',()=>{
  const c=context();const article={url:'https://www.hindutamil.in/news/tamilnadu/story',title:'தமிழ் செய்தி',feedContentKind:'content',feedBlocks:[{type:'p',text:'தமிழ் செய்தி '.repeat(100)},{type:'p',text:'Second paragraph '.repeat(30)},{type:'p',text:'Third paragraph'},{type:'p',text:'கடைசி பத்தி'}]};
  const result=c.readerFeedArticle(article);
  assert.equal(result.blocks.at(-1).text,'கடைசி பத்தி');assert.equal(result.status,'publisher-feed');assert.match(result.message,/RSS feed/);
});
test('summary-only, empty and other-publisher feeds are not presented as Hindu Tamil articles',()=>{
  const c=context();const base={url:'https://www.hindutamil.in/news/story',feedContentKind:'content',feedBlocks:[{type:'p',text:'Article '.repeat(30)}]};
  assert.equal(c.readerFeedArticle({...base,feedContentKind:'summary'}),null);
  assert.equal(c.readerFeedArticle({...base,feedBlocks:[]}),null);
  assert.equal(c.readerFeedArticle({...base,url:'https://hindutamil.in.example.com/story'}),null);
  const short=c.readerFeedArticle(base);assert.equal(short.status,'possibly-incomplete');
});
