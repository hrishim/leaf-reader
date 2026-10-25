import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
function reader(initial='{"feeds":[]}'){
 const nodes=new Map(),storage=new Map([['leaf-v1',initial],['leaf-reader-mode','off']]);
 const node=selector=>{if(!nodes.has(selector))nodes.set(selector,{textContent:'',innerHTML:'',value:'',dataset:{},style:{},classList:{toggle(){},contains(){return false},remove(){}},setAttribute(){},showModal(){},close(){}});return nodes.get(selector)};
 const context=vm.createContext({document:{querySelector:node,body:{dataset:{},classList:{remove(){}}}},localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},setTimeout:()=>0,clearTimeout(){},navigator:{},window:{addEventListener(){}},leafOpenSettings(){},leafApplyPreferences(){},leafPreferences:{},leafApi:async()=>({items:[]}),readerFeedArticle:()=>null,URL,Date,console,confirm:()=>true});
 vm.runInContext(fs.readFileSync('web/library-model.js','utf8'),context);
 vm.runInContext(fs.readFileSync('web/reader.js','utf8'),context);
 return {run:s=>vm.runInContext(s,context),nodes,storage};
}
test('read article stays during reading, disappears on next, previous restores it, saved state records reading',async()=>{
 const r=reader();r.run(`articles=[{id:'a',title:'First',feed:'feed',feedBlocks:[]},{id:'b',title:'Second',feed:'feed',feedBlocks:[]}];filter='feed';`);
 await r.run('show(articles[0])');assert.equal(r.run("read.has('a')"),true);assert.equal(r.run('merged().filter(match).length'),2);
 r.run('navigateArticle(1)');assert.equal(r.run('selected.id'),'b');assert.equal(r.run("merged().filter(match).some(a=>a.id==='a')"),false);
 r.run('navigateArticle(-1)');assert.equal(r.run('selected.id'),'a');
 assert.equal(JSON.parse(r.storage.get('leaf-v1')).read.length,2);
 r.run('navigateArticle(1);navigateArticle(1)');assert.equal(r.run('selected'),null);assert.equal(r.run('merged().filter(match).length'),0);
 assert.ok(!r.nodes.get('#story').innerHTML.includes('End of available text'));
});
test('mark all read clears article, navigation and unread list',async()=>{
 const r=reader();r.run(`articles=[{id:'a',title:'First',feedBlocks:[]}];`);await r.run('show(articles[0])');r.nodes.get('#markAll').onclick();
 assert.equal(r.run('selected'),null);assert.equal(r.run('merged().filter(match).length'),0);assert.equal(r.nodes.get('#articleNavigation').hidden,true);
 assert.equal(r.nodes.get('#syncStatus').textContent,'');
});

test('refresh and restart preserve older read status beyond 1500 articles',async()=>{
 const r=reader();r.run(`read=new Set(Array.from({length:1700},(_,i)=>'read-'+i));persist();`);
 assert.equal(JSON.parse(r.storage.get('leaf-v1')).read.length,1700);
 const restarted=reader(r.storage.get('leaf-v1'));await restarted.run('Promise.resolve()');
 restarted.run(`feeds=[{url:'feed',name:'Test'}];leafApi=async()=>({items:[{id:'read-0',title:'Old'},{id:'new',title:'New'}]});`);
 await restarted.run('refreshAll()');
 assert.equal(restarted.run('merged().filter(match).map(a=>a.id).join()'),'new');
 assert.equal(restarted.run("read.has('read-0')"),true);
});
test('bottom menu switches between Read Later, Unread and All Items',()=>{
 const r=reader();r.run(`articles=[{id:'a',title:'Read'},{id:'b',title:'Unread'}];read.add('a');saved.add('a');`);
 r.nodes.get('#bottomSaved').onclick();assert.equal(r.run('filter'),'saved');assert.equal(r.run('merged().filter(match).map(a=>a.id).join()'),'a');
 r.nodes.get('#bottomUnread').onclick();assert.equal(r.run('merged().filter(match).map(a=>a.id).join()'),'b');
 r.nodes.get('#bottomAll').onclick();assert.equal(r.run('merged().filter(match).length'),2);
});
