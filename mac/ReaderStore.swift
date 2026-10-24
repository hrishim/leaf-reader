import Foundation
import CryptoKit

/// Only Read Later and unexpired retained articles have bodies on disk.
final class ReaderStore {
    let directory:URL
    var state:[String:Any]=[:]
    var retentionDays:Int { get {min(30,max(0,state["retentionDays"] as? Int ?? 0))} set {state["retentionDays"]=min(30,max(0,newValue))} }
    init(directory:URL?=nil) throws {
        self.directory=directory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("LeafReader",isDirectory:true)
        try FileManager.default.createDirectory(at:self.directory,withIntermediateDirectories:true)
        let file=self.directory.appendingPathComponent("state.json")
        if FileManager.default.fileExists(atPath:file.path){let data=try Data(contentsOf:file);guard let object=try JSONSerialization.jsonObject(with:data) as? [String:Any] else{throw NSError(domain:"ReaderStore",code:1,userInfo:[NSLocalizedDescriptionKey:"The saved library could not be read."])};state=object}
        try purge()
    }
    func save(_ value:[String:Any]) throws {var value=value;value["retentionDays"]=retentionDays;let data=try JSONSerialization.data(withJSONObject:value,options:[.sortedKeys]);try data.write(to:directory.appendingPathComponent("state.json"),options:.atomic);state=value}
    func key(_ id:String)->String{SHA256.hash(data:Data(id.utf8)).map{String(format:"%02x",$0)}.joined()}
    func bodyURL(_ id:String)->URL{directory.appendingPathComponent(key(id)+".article.json")}
    func keep(_ id:String,article:[String:Any],expires:Date?=nil) throws {var value=article;value["expiresAt"]=expires?.timeIntervalSince1970 ?? 0;try JSONSerialization.data(withJSONObject:value).write(to:bodyURL(id),options:.atomic)}
    func body(_ id:String,now:Date=Date())->[String:Any]? {guard let data=try? Data(contentsOf:bodyURL(id)),let value=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else{return nil};if let expiry=value["expiresAt"] as? Double,expiry>0,expiry<=now.timeIntervalSince1970{try? FileManager.default.removeItem(at:bodyURL(id));return nil};return value}
    func removeBody(_ id:String) throws{let url=bodyURL(id);if FileManager.default.fileExists(atPath:url.path){try FileManager.default.removeItem(at:url)}}
    func markRead(_ id:String,article:[String:Any]?,now:Date=Date()) throws {if retentionDays==0{try removeBody(id)}else if let value=article ?? body(id){try keep(id,article:value,expires:now.addingTimeInterval(Double(retentionDays)*86400))}}
    func retainedMetadata(now:Date=Date())->[[String:Any]] {let urls=(try? FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil)) ?? [];return urls.filter{$0.lastPathComponent.hasSuffix(".article.json")}.compactMap{url in guard let data=try? Data(contentsOf:url),let value=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let expiry=value["expiresAt"] as? Double,expiry>now.timeIntervalSince1970,let metadata=value["article"] as? [String:Any] else{return nil};return metadata}}
    func purge(now:Date=Date()) throws {for url in try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil) where url.lastPathComponent.hasSuffix(".article.json"){guard let data=try? Data(contentsOf:url),let value=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else{continue};if let expiry=value["expiresAt"] as? Double,expiry>0,expiry<=now.timeIntervalSince1970{try FileManager.default.removeItem(at:url)}}}
    func updateRetention(_ days:Int,now:Date=Date()) throws {retentionDays=days;for url in try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil) where url.lastPathComponent.hasSuffix(".article.json"){guard let data=try? Data(contentsOf:url),var value=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let expiry=value["expiresAt"] as? Double,expiry>0 else{continue};if retentionDays==0{try FileManager.default.removeItem(at:url)}else{value["expiresAt"]=min(expiry,now.addingTimeInterval(Double(retentionDays)*86400).timeIntervalSince1970);try JSONSerialization.data(withJSONObject:value).write(to:url,options:.atomic)}};try save(state)}
}
