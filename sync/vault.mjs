import {createCipheriv,createDecipheriv,randomBytes} from 'node:crypto';
// Supply a 32-byte encryption key through the backend secret configuration, never through Git or the web UI.
export class CredentialVault {
 constructor(store,key){if(!Buffer.isBuffer(key)||key.length!==32)throw new Error('A 32-byte backend vault key is required');this.store=store;this.key=key;this.tail=Promise.resolve();}
 async get(id){const values=await this.store.load()||{};const entry=values[id];if(!entry)return null;const decipher=createDecipheriv('aes-256-gcm',this.key,Buffer.from(entry.iv,'base64'));decipher.setAAD(Buffer.from(id));decipher.setAuthTag(Buffer.from(entry.tag,'base64'));return JSON.parse(Buffer.concat([decipher.update(Buffer.from(entry.data,'base64')),decipher.final()]).toString());}
 update(action){const run=async()=>{const values=await this.store.load()||{};action(values);await this.store.save(values)};this.tail=this.tail.then(run,run);return this.tail;}
 async set(id,value){if(['__proto__','constructor','prototype'].includes(id))throw new Error('Invalid credential ID');return this.update(values=>{const iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',this.key,iv);cipher.setAAD(Buffer.from(id));const data=Buffer.concat([cipher.update(JSON.stringify(value)),cipher.final()]);values[id]={iv:iv.toString('base64'),tag:cipher.getAuthTag().toString('base64'),data:data.toString('base64')}});}
 async delete(id){return this.update(values=>{delete values[id]})}
}
