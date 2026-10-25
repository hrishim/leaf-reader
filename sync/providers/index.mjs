import {inoreader,freshRSS} from './google-reader.mjs';import {feedbin} from './feedbin.mjs';import {newsblur} from './newsblur.mjs';
export const providerCatalogue=[
 {id:'inoreader',name:'Inoreader',adapter:true,authentication:'registered-oauth',liveVerified:false},
 {id:'freshrss',name:'FreshRSS',adapter:true,authentication:'api-password',liveVerified:false},
 {id:'feedbin',name:'Feedbin',adapter:true,authentication:'account-password',liveVerified:false},
 {id:'newsblur',name:'NewsBlur',adapter:true,authentication:'account-session',liveVerified:false},
 {id:'feedly',name:'Feedly',adapter:false,authentication:'provider-registration-required',liveVerified:false},
 {id:'bazqux',name:'BazQux',adapter:false,authentication:'not-implemented',liveVerified:false},
 {id:'theoldreader',name:'The Old Reader',adapter:false,authentication:'not-implemented',liveVerified:false},
 {id:'feedhq',name:'FeedHQ',adapter:false,authentication:'not-implemented',liveVerified:false},
 {id:'instapaper',name:'Instapaper',adapter:false,authentication:'read-later-adapter-required',liveVerified:false}
];
export async function createAdapter(provider,configuration){switch(provider){case 'inoreader':return inoreader(configuration);case 'freshrss':return freshRSS(configuration);case 'feedbin':return feedbin(configuration);case 'newsblur':return newsblur(configuration);default:throw new Error('This service adapter is not implemented')}}
