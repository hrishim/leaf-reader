import Foundation
import Security

/// Trusted backend transport. This does not connect local-only subscriptions to a provider automatically.
final class ReaderSyncClient {
 private final class NoRedirect:NSObject,URLSessionTaskDelegate {func urlSession(_ session:URLSession,task:URLSessionTask,willPerformHTTPRedirection response:HTTPURLResponse,newRequest request:URLRequest,completionHandler:@escaping(URLRequest?)->Void){completionHandler(nil)}}
 let base:URL
 let session:URLSession
 private let accessKey:()->String?
 init(base:URL,session:URLSession?=nil,accessKey:@escaping()->String?) throws {
  guard let host=base.host,base.user==nil,base.password==nil,base.query==nil,base.fragment==nil,base.path.isEmpty || base.path=="/",base.scheme=="https" || base.scheme=="http" && ["127.0.0.1","localhost","::1"].contains(host) else{throw Self.failure("Use a trusted HTTPS sync backend.")}
  self.base=base;self.accessKey=accessKey
  if let session=session{self.session=session}else{let config=URLSessionConfiguration.ephemeral;config.httpCookieStorage=nil;config.urlCache=nil;config.timeoutIntervalForRequest=45;self.session=URLSession(configuration:config)}
 }
 static func failure(_ message:String)->NSError{NSError(domain:"LeafReaderSync",code:1,userInfo:[NSLocalizedDescriptionKey:message])}
 func request(_ path:String,method:String="GET",body:[String:Any]?=nil) async throws->[String:Any]{
  guard path.hasPrefix("/"),!path.hasPrefix("//"),let key=accessKey(),!key.isEmpty,let url=URL(string:path,relativeTo:base)?.absoluteURL,url.scheme==base.scheme,url.host==base.host,url.port==base.port else{throw Self.failure("Sign in to the configured sync backend.")}
  var request=URLRequest(url:url);request.httpMethod=method;request.setValue("Bearer "+key,forHTTPHeaderField:"Authorization");request.setValue("application/json",forHTTPHeaderField:"Accept")
  if let body=body{request.httpBody=try JSONSerialization.data(withJSONObject:body);request.setValue("application/json",forHTTPHeaderField:"Content-Type")}
  let (data,response)=try await session.data(for:request,delegate:NoRedirect())
  guard let http=response as? HTTPURLResponse,http.url?.host==base.host,http.url?.scheme==base.scheme,http.url?.port==base.port else{throw Self.failure("Unexpected sync backend response.")}
  guard (200..<300).contains(http.statusCode) else{throw Self.failure(http.statusCode==401 ? "Sign in to the sync backend again.":http.statusCode==429 ? "Sync rate limit reached; try later.":"Sync failed. Pending reading changes are retained.")}
  guard let result=try JSONSerialization.jsonObject(with:data) as? [String:Any] else{throw Self.failure("Invalid sync backend response.")};return result
 }
 func accounts() async throws->[String:Any]{try await request("/accounts")}
 func providers() async throws->[String:Any]{try await request("/providers")}
 func route(_ id:String)throws->String{guard !id.isEmpty,id.range(of:"^[A-Za-z0-9_-]{1,100}$",options:.regularExpression) != nil else{throw Self.failure("Invalid account identifier.")};return "/accounts/"+id}
 func snapshot(_ id:String) async throws->[String:Any]{try await request(route(id))}
 func synchronize(_ id:String) async throws->[String:Any]{try await request(route(id)+"/sync",method:"POST")}
 func change(_ id:String,item:String,field:String,value:Bool) async throws->[String:Any]{guard ["read","saved"].contains(field) else{throw Self.failure("Invalid reading change.")};return try await request(route(id)+"/changes",method:"POST",body:["changes":[["itemId":item,"field":field,"value":value]]])}
 func disconnect(_ id:String) async throws->[String:Any]{try await request(route(id),method:"DELETE")}
}

/// Only the backend access key is stored here; provider passwords and OAuth secrets stay on the backend.
enum ReaderSyncKeychain {
 static let service="local.leafreader.sync-backend"
 static func query(_ backend:String)->[String:Any]{[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:backend]}
 static func load(_ backend:String)throws->String?{var q=query(backend);q[kSecReturnData as String]=true;q[kSecMatchLimit as String]=kSecMatchLimitOne;var result:CFTypeRef?;let status=SecItemCopyMatching(q as CFDictionary,&result);if status==errSecItemNotFound{return nil};guard status==errSecSuccess,let data=result as? Data else{throw ReaderSyncClient.failure("Could not read sync sign-in from Keychain.")};return String(data:data,encoding:.utf8)}
 static func save(_ key:String,backend:String)throws{let q=query(backend),data=Data(key.utf8);let status=SecItemUpdate(q as CFDictionary,[kSecValueData as String:data] as CFDictionary);if status==errSecItemNotFound{var add=q;add[kSecValueData as String]=data;add[kSecAttrAccessible as String]=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;guard SecItemAdd(add as CFDictionary,nil)==errSecSuccess else{throw ReaderSyncClient.failure("Could not save sync sign-in in Keychain.")}}else if status != errSecSuccess{throw ReaderSyncClient.failure("Could not update sync sign-in in Keychain.")}}
 static func remove(_ backend:String)throws{let status=SecItemDelete(query(backend) as CFDictionary);guard status==errSecSuccess||status==errSecItemNotFound else{throw ReaderSyncClient.failure("Could not remove sync sign-in from Keychain.")}}
}
