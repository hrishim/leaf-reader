import {mkdir,readFile,writeFile,rename} from 'node:fs/promises';import path from 'node:path';import {randomUUID} from 'node:crypto';
export class JsonFileStore {
 constructor(directory){this.directory=directory;this.file=path.join(directory,'sync-state.json');this.tail=Promise.resolve();}
 async load(){try{return JSON.parse(await readFile(this.file,'utf8'))}catch(e){if(e.code==='ENOENT')return null;throw e}}
 save(value){const text=JSON.stringify(value);const write=async()=>{await mkdir(this.directory,{recursive:true,mode:0o700});const tmp=this.file+'.'+randomUUID()+'.tmp';await writeFile(tmp,text,{mode:0o600});await rename(tmp,this.file)};this.tail=this.tail.then(write,write);return this.tail;}
}
export class MemoryStore {async load(){return this.value?structuredClone(this.value):null}async save(value){this.value=structuredClone(value)}}
