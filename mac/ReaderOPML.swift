import Foundation
final class OPMLReader:NSObject,XMLParserDelegate {
 var feeds:[[String:Any]]=[],stack:[String?]=[],rootSeen=false,validRoot=false,skipped=0
 func parser(_ parser:XMLParser,didStartElement name:String,namespaceURI:String?,qualifiedName:String?,attributes:[String:String]) {
  if !rootSeen{rootSeen=true;validRoot=name.lowercased()=="opml"}
  guard name=="outline" else{return}
  guard stack.count<32 else{parser.abortParsing();return}
  let path=stack.compactMap{$0}
  if let raw=attributes["xmlUrl"] {
   stack.append(nil)
   guard let u=try? ReaderNetwork.validated(raw),["http","https"].contains(u.scheme ?? ""),u.user==nil,u.password==nil else{skipped+=1;return}
   let keys=URLComponents(url:u,resolvingAgainstBaseURL:false)?.queryItems?.map{$0.name.lowercased()} ?? []
   guard !keys.contains(where:{$0.contains("token")||$0.contains("auth")||$0.contains("key")||$0.contains("signature")}) else{skipped+=1;return}
   feeds.append(["url":u.absoluteString,"name":attributes["text"] ?? attributes["title"] ?? u.host ?? "Feed","folderPath":path])
  }else{stack.append(attributes["text"] ?? attributes["title"])}
 }
 func parser(_ parser:XMLParser,didEndElement name:String,namespaceURI:String?,qualifiedName:String?){if name=="outline",!stack.isEmpty{stack.removeLast()}}
}
enum ReaderOPML {
 static func report(_ data:Data)throws->(feeds:[[String:Any]],skipped:Int){guard data.count<1_000_000 else{throw ReaderNetwork.failure("Choose an OPML file smaller than 1 MB.")};let reader=OPMLReader(),parser=XMLParser(data:data);parser.delegate=reader;parser.shouldResolveExternalEntities=false;guard parser.parse(),reader.validRoot else{throw ReaderNetwork.failure("This OPML file could not be read.")};return(reader.feeds,reader.skipped)}
 static func plan(_ incoming:[[String:Any]],existing:[[String:Any]])->(add:[[String:Any]],updates:[[String:Any]],duplicates:Int,overflow:Int){var seen=Set<String>(),add:[[String:Any]]=[],updates:[[String:Any]]=[],duplicates=0,overflow=0;for f in incoming{guard let link=f["url"] as? String else{continue};if !seen.insert(link).inserted{duplicates+=1;continue};if let old=existing.first(where:{$0["url"] as? String==link}){if old["name"] as? String != f["name"] as? String || (old["folderPath"] as? [String] ?? []) != (f["folderPath"] as? [String] ?? []){updates.append(f)}else{duplicates+=1};continue};if existing.count+add.count>=250{overflow+=1;continue};add.append(f)};return(add,updates,duplicates,overflow)}
 static func decode(_ data:Data)throws->[[String:Any]]{var seen=Set<String>();return try report(data).feeds.filter{seen.insert($0["url"] as? String ?? "").inserted}.prefix(250).map{$0}}
 static func encode(_ feeds:[[String:Any]])->String {
  func esc(_ s:String)->String{s.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;").replacingOccurrences(of:"'",with:"&apos;")}
  func write(_ items:[[String:Any]],_ depth:Int)->String {var result="",groups:[String:[[String:Any]]]=[:],order:[String]=[];for f in items{let path=f["folderPath"] as? [String] ?? [];if path.count<=depth{result+="<outline type='rss' text='\(esc(f["name"] as? String ?? ""))' xmlUrl='\(esc(f["url"] as? String ?? ""))'/>"}else{let name=path[depth];if groups[name]==nil{order.append(name);groups[name]=[]};groups[name]!.append(f)}};for name in order{result+="<outline text='\(esc(name))'>\(write(groups[name]!,depth+1))</outline>"};return result}
  return "<?xml version='1.0' encoding='UTF-8'?><opml version='2.0'><head><title>Leaf Reader subscriptions</title></head><body>\(write(feeds,0))</body></opml>"
 }
}
