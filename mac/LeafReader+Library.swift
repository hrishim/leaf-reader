import AppKit

struct LeafSidebarRow { var title:String;var kind:String;var feedIndex:Int?;var path:[String]=[] }
extension LeafReader {
 func publicationFeedBody(_ article:[String:Any])->[String:Any]?{
  guard article["restricted"] as? Bool != true,let feed=article["feed"] as? String,let host=URL(string:feed)?.host,(host.hasSuffix(".substack.com") || host=="www.hindutamil.in" || host=="hindutamil.in"),let blocks=article["feedBlocks"] as? [[String:Any]],!blocks.isEmpty else{return nil}
  let short=blocks.compactMap{$0["text"] as? String}.joined().count<1400
  return ["blocks":blocks,"status":short ? "feed-only":"feed-text","message":short ? "Available text supplied in the publisher’s feed. It may be an excerpt; open the heading for the original.":"Article text supplied in the publisher’s feed."]
 }
 var refreshChoices:[Int]{[0,5,15,30,60]}
 func refreshIsDue(now:Date=Date())->Bool{ready && refreshMinutes>0 && loading==0 && loadQueue.isEmpty && now.timeIntervalSince(lastRefresh)>=Double(refreshMinutes*60)}
 func refreshIfDue(){if refreshIsDue(){refresh()}}
 @objc func refreshScheduleChanged(_ sender:NSPopUpButton){refreshMinutes=refreshChoices[sender.indexOfSelectedItem];persist()}
 @objc func computerWoke(_ note:Notification){refreshIfDue()}
 func cachedHeadlines()->[[String:Any]]{
  var counts:[String:Int]=[:]
  return articles.compactMap{article in guard let feed=article["feed"] as? String,(counts[feed] ?? 0)<200,feeds.contains(where:{$0["url"] as? String==feed}) else{return nil};counts[feed,default:0]+=1;var value=article;value["feedBlocks"]=[];return value}
 }
 func acceptFeedItems(_ incoming:[[String:Any]],feed:[String:Any]){
  guard let address=feed["url"] as? String,feeds.contains(where:{$0["url"] as? String==address}) else{return}
  let ids=Set(incoming.compactMap{$0["id"] as? String})
  let older=articles.filter{$0["feed"] as? String==address && !ids.contains($0["id"] as? String ?? "")}
  articles.removeAll{$0["feed"] as? String==address}
  articles.append(contentsOf:(incoming+older).prefix(200).map{item in var value=item;value["feed"]=address;value["source"]=feed["name"];return value})
 }
 func migrateFeedAddresses(){
  guard let file=Bundle.main.url(forResource:"feed-updates",withExtension:"json"),let data=try? Data(contentsOf:file),let updates=try? JSONSerialization.jsonObject(with:data) as? [String:String] else{return}
  applyFeedAddressUpdates(updates)
 }
 func applyFeedAddressUpdates(_ updates:[String:String]){
  var changed=false
  for i in feeds.indices where feeds[i]["url"] as? String=="https://www.economist.com/latest/rss.xml" && feeds[i]["name"] as? String=="Latest Updates"{feeds[i]["name"]="The Economist";changed=true}
  for i in feeds.indices{guard let old=feeds[i]["url"] as? String,let next=updates[old],next.hasPrefix("https://") else{continue};feeds[i]["url"]=next;if currentScope==old{currentScope=next};for (id,value) in savedMeta{if var metadata=value as? [String:Any],metadata["feed"] as? String==old{metadata["feed"]=next;savedMeta[id]=metadata}};changed=true}
  if changed{var seen=Set<String>();feeds=feeds.filter{seen.insert($0["url"] as? String ?? "").inserted};do{try store.save(stateObject())}catch{alert("Could not update feed addresses",error.localizedDescription)}}
 }
 var sidebarRows:[LeafSidebarRow] {
  var rows=[LeafSidebarRow(title:"All Items",kind:"all"),LeafSidebarRow(title:"Unread",kind:"unread"),LeafSidebarRow(title:"Read Later",kind:"saved"),LeafSidebarRow(title:"ON THIS DEVICE",kind:"heading"),LeafSidebarRow(title:"Today",kind:"today")]
  var groups:[String:[Int]]=[:],keys:[String]=[]
  for (i,f) in feeds.enumerated(){let path=f["folderPath"] as? [String] ?? [];let key=path.joined(separator:" / ");if groups[key]==nil{keys.append(key);groups[key]=[]};groups[key]!.append(i)}
  for key in keys{if !key.isEmpty{let index=groups[key]!.first!;let path=feeds[index]["folderPath"] as? [String] ?? [];rows.append(LeafSidebarRow(title:(collapsedFolders.contains(key) ? "▸ ":"▾ ")+key,kind:"folder",path:path));if collapsedFolders.contains(key){continue}};for i in groups[key]!{rows.append(LeafSidebarRow(title:feeds[i]["name"] as? String ?? "Feed",kind:"feed",feedIndex:i))}}
  return rows
 }
 func restoreSidebarScope(scroll:Bool=true){
  if let feed=feeds.first(where:{$0["url"] as? String==currentScope}){collapsedFolders.remove((feed["folderPath"] as? [String] ?? []).joined(separator:" / "))}
  sidebar.reloadData()
  let row=sidebarRows.firstIndex{entry in
   if let i=entry.feedIndex{return feeds[i]["url"] as? String==currentScope}
   if currentScope.isEmpty{return entry.kind==currentFilter}
   if currentScope=="@today"{return entry.kind=="today"}
   if entry.kind=="folder",let data=try? JSONSerialization.data(withJSONObject:entry.path){return currentScope=="@folder:"+String(data:data,encoding:.utf8)!}
   return false
  }
  guard let row=row else{return}
  sidebar.delegate=nil;sidebar.selectRowIndexes(IndexSet(integer:row),byExtendingSelection:false);sidebar.delegate=self
  if scroll{sidebar.scrollRowToVisible(row)}
 }
 func feedIndex(at row:Int)->Int?{guard sidebarRows.indices.contains(row) else{return nil};return sidebarRows[row].feedIndex}
 func inScope(_ a:[String:Any])->Bool {
  if currentScope.isEmpty{return true}
  if currentScope=="@today"{return Calendar.current.isDateInToday(date(a["date"] as? String ?? ""))}
  if currentScope.hasPrefix("@folder:"),let data=String(currentScope.dropFirst(8)).data(using:.utf8),let path=try? JSONSerialization.jsonObject(with:data) as? [String]{let f=feeds.first{$0["url"] as? String==a["feed"] as? String};let full=f?["folderPath"] as? [String] ?? [];return full.starts(with:path)}
  return a["feed"] as? String==currentScope
 }
 func chooseItemFilter(_ value:String){currentFilter=value;clearArticleDisplay(title:"Choose an article",notice:"Select an article from this view.");rebuildList();persist()}
 @objc func sidebarClicked(){let row=sidebar.clickedRow;guard sidebarRows.indices.contains(row),sidebarRows[row].kind=="folder" else{return};let key=sidebarRows[row].path.joined(separator:" / ");if collapsedFolders.contains(key){collapsedFolders.remove(key)}else{collapsedFolders.insert(key)};sidebar.reloadData();persist()}
 @objc func bottomFilterChanged(_ sender:NSSegmentedControl){chooseItemFilter(["saved","unread","all"][sender.selectedSegment])}
 @objc func nextUnread(){let next=allArticles().first{inScope($0) && !read.contains($0["id"] as? String ?? "")};if let next=next{openArticle(next)}else{clearArticleDisplay(title:"All caught up.",notice:"No unread articles in this view.");rebuildList()}}
 @objc func libraryCenter(){guard ready else{return};let a=NSAlert();a.messageText="Subscriptions & Import";a.informativeText="On this device · local public feeds\n\nAdd an RSS/Atom feed or website, import an OPML subscription file, or organize feeds into folders.\n\nSubstack: paste the publication address under Add Feed. New posts refresh while the app is open. Each Mac keeps its own library. OPML can copy subscriptions between Macs.";a.addButton(withTitle:"Add Feed / Substack");a.addButton(withTitle:"Import OPML…");a.addButton(withTitle:"Organize Feeds…");a.addButton(withTitle:"Done");switch a.runModal(){case .alertFirstButtonReturn:addFeed();case .alertSecondButtonReturn:importOPML();case .alertThirdButtonReturn:organizeFeeds();default:break}}
 @objc func organizeFeeds(){guard !feeds.isEmpty else{addFeed();return};let a=NSAlert();a.messageText="Organize subscriptions";a.informativeText="Choose a feed, then rename it or enter a folder path. Use / between nested folders.";let stack=NSStackView();stack.orientation = .vertical;stack.spacing=12;stack.frame=NSRect(x:0,y:0,width:400,height:110);let choice=NSPopUpButton();choice.addItems(withTitles:feeds.map{$0["name"] as? String ?? "Feed"});let chosen=contextFeedIndex.flatMap{feeds.indices.contains($0) ? $0:nil} ?? 0;choice.selectItem(at:chosen);let name=NSTextField(string:feeds[chosen]["name"] as? String ?? ""),folder=NSTextField(string:(feeds[chosen]["folderPath"] as? [String] ?? []).joined(separator:" / "));organizerFields=["choice":choice,"name":name,"folder":folder];choice.target=self;choice.action=#selector(organizerSelectionChanged);name.placeholderString="New name (leave blank to keep)";folder.placeholderString="Folder / Subfolder (blank removes folder)";for v in [choice,name,folder]{v.widthAnchor.constraint(equalToConstant:390).isActive=true;stack.addArrangedSubview(v)};a.accessoryView=stack;a.addButton(withTitle:"Save");a.addButton(withTitle:"Cancel");guard a.runModal() == .alertFirstButtonReturn else{return};let i=choice.indexOfSelectedItem;guard feeds.indices.contains(i) else{return};if !name.stringValue.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{feeds[i]["name"]=name.stringValue};feeds[i]["folderPath"]=folder.stringValue.split(separator:"/").map{String($0).trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty};persist();sidebar.reloadData();rebuildList()}
 @objc func organizerSelectionChanged(){guard let choice=organizerFields["choice"] as? NSPopUpButton,let name=organizerFields["name"] as? NSTextField,let folder=organizerFields["folder"] as? NSTextField,feeds.indices.contains(choice.indexOfSelectedItem) else{return};let f=feeds[choice.indexOfSelectedItem];name.stringValue=f["name"] as? String ?? "";folder.stringValue=(f["folderPath"] as? [String] ?? []).joined(separator:" / ")}
 @objc func behaviorChanged(_ sender:NSControl){if let open=settingsWidgets["markOnOpen"] as? NSButton{markOnOpen=open.state == .on};if let order=settingsWidgets["oldestFirst"] as? NSButton{oldestFirst=order.state == .on};persist();rebuildList()}
}
