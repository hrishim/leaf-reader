import AppKit
import WebKit
@main final class DisplayRegressionTests:NSObject,NSApplicationDelegate,WKNavigationDelegate {
 var reader:LeafReader!
 static func main(){let app=NSApplication.shared;let delegate=DisplayRegressionTests();app.delegate=delegate;app.run();withExtendedLifetime(delegate){}}
 func applicationDidFinishLaunching(_ note:Notification){do{
  let root=URL(fileURLWithPath:"/Volumes/codex_Extender/Work/leaf-tmp").appendingPathComponent("display-regression-"+UUID().uuidString)
  reader=LeafReader();reader.store=try ReaderStore(directory:root);reader.ready=true
  reader.list.dataSource=reader;reader.list.delegate=reader;reader.sidebar.dataSource=reader;reader.sidebar.delegate=reader
  reader.readControl=NSButton();reader.laterControl=NSButton();reader.detail.navigationDelegate=self
  let a:[String:Any] = ["id":"a","title":"First","url":"https://example.com/a","feed":"https://example.com/rss"]
  let b:[String:Any] = ["id":"b","title":"Second","url":"https://example.com/b","feed":"https://example.com/rss"]
  reader.feeds=[["name":"Feed A","url":"https://example.com/rss","folderPath":["News","India"]]]
  reader.read=["old-article"];reader.saved=["later"];reader.savedMeta=["later":["id":"later","feed":"https://example.com/rss"]];reader.currentScope="https://example.com/rss"
  reader.applyFeedAddressUpdates(["https://example.com/rss":"https://example.com/new.rss"])
  assert(reader.feeds[0]["url"] as? String=="https://example.com/new.rss")
  assert(reader.currentScope=="https://example.com/new.rss")
  assert(reader.read.contains("old-article") && reader.saved.contains("later"))
  assert((reader.savedMeta["later"] as? [String:Any])?["feed"] as? String=="https://example.com/new.rss")
  assert(reader.feeds[0]["folderPath"] as? [String]==["News","India"])
  reader.feeds[0]["url"]="https://example.com/rss";reader.saved=[];reader.savedMeta=[:]
  let publicPost:[String:Any] = ["feed":"https://author.substack.com/feed","feedBlocks":(0..<3).map{["type":"p","text":String(repeating:"Public text. ",count:50)+String($0)]}]
  assert(reader.publicationFeedBody(publicPost) != nil)
  var paidPost=publicPost;paidPost["restricted"]=true;assert(reader.publicationFeedBody(paidPost)==nil)
  assert(reader.refreshIsDue(now:Date(timeIntervalSince1970:10000)))
  reader.lastRefresh=Date();assert(!reader.refreshIsDue());reader.refreshMinutes=0;assert(!reader.refreshIsDue(now:Date().addingTimeInterval(86400)));reader.refreshMinutes=15
  reader.acceptFeedItems([["id":"first","title":"Old headline","feedBlocks":[["type":"p","text":"Body must not persist"]]]],feed:reader.feeds[0])
  reader.read.insert("first")
  reader.acceptFeedItems([["id":"second","title":"New post"]],feed:reader.feeds[0])
  assert(reader.articles.count==2 && reader.read.contains("first"),"New feed posts must not reset old read markers or drop older headlines")
  assert(reader.cachedHeadlines().allSatisfy{($0["feedBlocks"] as? [[String:Any]])?.isEmpty==true},"Ordinary article bodies must not be persisted")
  reader.persist();let cached=LeafReader();cached.applyState(reader.store.state);assert(cached.articles.count==2 && cached.read.contains("first"));assert(cached.refreshMinutes==15)
  reader.currentScope="@folder:[\"News\"]";assert(reader.inScope(a));reader.currentScope="https://other.example/rss";assert(!reader.inScope(a));reader.currentScope=""
  assert(reader.sidebarRows.contains{$0.kind=="folder"});let mapped=reader.sidebarRows.firstIndex{$0.feedIndex==0}!;assert(reader.feedIndex(at:mapped)==0)
  reader.currentScope="https://example.com/rss";reader.collapsedFolders=["News / India"];reader.restoreSidebarScope()
  assert(!reader.collapsedFolders.contains("News / India"));assert(reader.feedIndex(at:reader.sidebar.selectedRow)==0,"Startup must reveal and select the saved feed")
  reader.currentScope="";reader.currentFilter="unread";reader.restoreSidebarScope();assert(reader.sidebarRows[reader.sidebar.selectedRow].kind=="unread")
  reader.articles=[a,b];reader.currentFilter="all";reader.read=["a"];reader.rebuildList()
  let readCell=reader.tableView(reader.list,viewFor:nil,row:0)!
  let unreadCell=reader.tableView(reader.list,viewFor:nil,row:1)!
  assert(readCell.alphaValue==0.55 && unreadCell.alphaValue==1,"Read headlines must dim while unread headlines stay prominent")
  reader.read.remove("a");reader.rebuildList()
  assert(reader.tableView(reader.list,viewFor:nil,row:0)!.alphaValue==1,"Mark unread must restore the normal appearance")
  reader.articles=[a,b];reader.read=["a","b"];reader.selected=a;reader.articleBlocks=[["type":"p","text":"STALE ARTICLE MUST DISAPPEAR"]];reader.bodyStatus="loading";reader.fetchSerial=41;reader.search.stringValue="First"
  reader.changeReadingSettings(size:32,interfaceSize:18,font:"sans",spacing:1.5,title:1.8,theme:"light")
  assert(reader.store.state["fontSize"] as? Int==32)
  reader.fontSize=19;reader.applyState(reader.store.state);assert(reader.fontSize==32);assert(reader.interfaceFontSize==18);assert(reader.articleFontStyle=="sans")
  reader.showUnreadAfterMarkAll()
  assert(reader.currentFilter=="unread");assert(reader.store.state["currentFilter"] as? String=="unread","Unread view persists after Mark All Read");assert(reader.visible.isEmpty);assert(reader.selected==nil);assert(reader.articleBlocks.isEmpty);assert(reader.fetchSerial>41);assert(reader.search.stringValue.isEmpty);assert(reader.readControl?.isEnabled==false)
  reader.currentFilter="https://example.com/rss";reader.rebuildList();assert(reader.visible.isEmpty,"Read articles must disappear from feed lists")
  reader.selected=a;reader.rebuildList();assert(reader.visible.count==1,"The article being read remains visible until moving on")
  reader.selected=nil
  reader.persist();let restored=LeafReader();restored.applyState(reader.store.state);assert(restored.read.contains("a") && restored.read.contains("b"),"Read status persists independently of refreshed feed content")
  reader.currentFilter="all";reader.rebuildList();assert(reader.visible.count==2,"Read history remains available explicitly")
  reader.contextArticle=b;reader.contextToggleRead();assert(!reader.read.contains("b"));assert(reader.read.contains("a"),"Context action must affect its own article")
  reader.currentFilter="unread";reader.showUnreadAfterMarkAll();assert(reader.visible.count==1,"Partial completion preserves unread articles")
  reader.contextToggleRead();assert(reader.read.contains("b"));reader.showUnreadAfterMarkAll()
  Timer.scheduledTimer(withTimeInterval:12,repeats:false){_ in fputs("FAIL: timed out rendering empty state\n",stderr);exit(1)}
 }catch{fputs("FAIL: \(error)\n",stderr);exit(1)}}
 func webView(_ view:WKWebView,didFinish navigation:WKNavigation!){view.evaluateJavaScript("document.body.innerText"){result,error in
  guard let text=result as? String,text.contains("All caught up.") else{return}
  assert(!text.contains("STALE ARTICLE"))
  view.evaluateJavaScript("({size:getComputedStyle(document.body).fontSize,spacing:getComputedStyle(document.body).lineHeight,title:getComputedStyle(document.querySelector('h1')).fontSize})"){value,error in
   guard let values=value as? [String:String] else{fatalError("Could not inspect rendered reading styles")}
   assert(values["size"]=="32px","Chosen article size must render in WebKit")
   assert(values["spacing"]=="48px","Chosen line spacing must render in WebKit")
   let titlePixels=Double((values["title"] ?? "0px").replacingOccurrences(of:"px",with:"")) ?? 0;assert(abs(titlePixels-57.6)<0.1,"Title size follows its independent multiplier")
   print("PASS: rendered WebKit font size, line spacing and title size; saved reading/interface settings; Mark All Read clearing; late extraction cancellation; history; context marking")
   exit(0)
  }
 }}
}
