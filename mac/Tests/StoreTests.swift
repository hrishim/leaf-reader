import Foundation
@main struct StoreTests {
 static func main() throws {
  let root=URL(fileURLWithPath:ProcessInfo.processInfo.environment["READER_TEST_DIR"]!).appendingPathComponent(UUID().uuidString)
  let s=try ReaderStore(directory:root),now=Date(timeIntervalSince1970:1_800_000_000),article:[String:Any]=["blocks":[["type":"p","text":"Offline fixture"]]]
  assert(s.retentionDays==0);try s.keep("saved",article:article);assert(s.body("saved") != nil)
  try s.markRead("saved",article:article,now:now);assert(s.body("saved")==nil)
  s.retentionDays=999;assert(s.retentionDays==30);try s.markRead("retained",article:article,now:now)
  assert(s.body("retained",now:now.addingTimeInterval(29*86400)) != nil);assert(s.body("retained",now:now.addingTimeInterval(30*86400))==nil)
  s.retentionDays=7;try s.keep("unread",article:article);try s.markRead("expired",article:article,now:now)
  try s.purge(now:now.addingTimeInterval(8*86400));assert(s.body("expired")==nil);assert(s.body("unread") != nil)
  try s.markRead("shorten",article:article,now:now);try s.updateRetention(1,now:now);assert(s.body("shorten",now:now.addingTimeInterval(2*86400))==nil)
  try s.markRead("immediate",article:article,now:now);try s.updateRetention(0,now:now);assert(s.body("immediate")==nil);assert(s.body("unread") != nil)
  try s.save(["feeds":[["name":"Fixture","url":"https://example.com/feed"]],"read":["story"],"saved":["unread"]]);let reopened=try ReaderStore(directory:root);assert((reopened.state["read"] as? [String])==["story"]);assert(reopened.body("unread") != nil)
  for bad in ["file:///etc/passwd","http://localhost/feed","http://127.0.0.1/feed","https://user:pass@example.com/feed","https://example.com/feed?token=private"]{assert((try? ReaderNetwork.validated(bad))==nil)}
  assert((try? ReaderNetwork.validated("https://9to5mac.com/feed/")) != nil)
  let fixture=Data("<opml><body><outline text='Nested'><outline text='One &amp; Two' xmlUrl='https://example.com/rss?a=1&amp;b=2'/><outline xmlUrl='https://example.com/rss?a=1&amp;b=2'/><outline xmlUrl='https://example.com/feed?token=secret'/></outline></body></opml>".utf8)
  let imported=try ReaderOPML.decode(fixture);assert(imported.count==1);let roundtrip=try ReaderOPML.decode(Data(ReaderOPML.encode(imported).utf8));assert(roundtrip[0]["name"] as? String=="One & Two");assert(roundtrip[0]["url"] as? String=="https://example.com/rss?a=1&b=2")
  assert((try? ReaderOPML.decode(Data("<opml><body>".utf8)))==nil);assert((try? ReaderOPML.decode(Data("<rss/>".utf8)))==nil);assert((try? ReaderOPML.decode(Data(repeating:32,count:1_000_001)))==nil)
  let body="Line one & two\nTamil தமிழ் ₹922 <test>";let gmail=ReaderLinks.compose(service:"Gmail",title:"A & B",body:body)!;let q=URLComponents(url:gmail,resolvingAgainstBaseURL:false)!.queryItems!;assert(q.first{$0.name=="body"}?.value==body);assert(gmail.host=="mail.google.com");assert(ReaderLinks.compose(service:"Outlook on the web",title:"Title",body:body)?.host=="outlook.live.com");assert(ReaderLinks.compose(service:"Default Mac mail app",title:"Title",body:body)?.scheme=="mailto")
  print("PASS: immediate deletion; 30-day cap; expiry; Read Later preservation; retention reduction; library restart; public URL validation; OPML nested import, deduplication, private-feed rejection, roundtrip, malformed XML, wrong format, size limit")
 }
}
