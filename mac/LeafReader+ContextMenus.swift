import AppKit

extension LeafReader: NSMenuDelegate {
    func installContextMenus(){
        articleContextMenu.delegate=self;feedContextMenu.delegate=self
        list.menu=articleContextMenu;sidebar.menu=feedContextMenu
    }
    func menuNeedsUpdate(_ menu:NSMenu){
        menu.removeAllItems()
        func item(_ title:String,_ action:Selector){let i=menu.addItem(withTitle:title,action:action,keyEquivalent:"");i.target=self}
        if menu === articleContextMenu {
            let row=list.clickedRow
            guard row>=0,row<visible.count else{contextArticle=nil;return}
            let a=visible[row],id=a["id"] as? String ?? ""
            contextArticle=a;contextArticlesBelow=Array(visible[row...])
            item(read.contains(id) ? "Mark as Unread":"Mark as Read",#selector(contextToggleRead))
            item(saved.contains(id) ? "Remove from Read Later":"Read Later",#selector(contextToggleLater))
            item("Mark Below as Read…",#selector(contextMarkBelow))
            menu.addItem(.separator())
            item("Copy Link",#selector(contextCopyLink));item("Copy Article Text",#selector(contextCopyText))
            item("Email Article…",#selector(contextEmail))
            menu.addItem(.separator());item("Open in Browser",#selector(contextOpenOriginal))
        }else if menu === feedContextMenu {
            let index=sidebar.clickedRow-4
            guard feeds.indices.contains(index) else{contextFeedIndex=nil;return}
            contextFeedIndex=index
            item("Open Website",#selector(contextOpenFeed));item("Refresh Feed",#selector(contextRefreshFeed))
            item("Mark Feed as Read…",#selector(contextMarkFeed))
            menu.addItem(.separator());item("Edit Subscription…",#selector(contextEditFeed));item("Remove Subscription…",#selector(contextRemoveFeed))
        }
    }
    func finishContextChange(){persist();rebuildList();updateArticleControls()}
    @objc func contextToggleRead(){
        guard let a=contextArticle,let id=a["id"] as? String else{return}
        do{if read.contains(id){read.remove(id)}else{
            try store.markRead(id,article:id==selected?["id"] as? String && bodyStatus != "loading" && !articleRestricted ? extractedObject():nil)
            read.insert(id);saved.remove(id);savedMeta.removeValue(forKey:id)
        };finishContextChange()}catch{alert("Could not update article",error.localizedDescription)}
    }
    func withContextBody(_ a:[String:Any],completion:@escaping([String:Any])->Void){
        guard let id=a["id"] as? String,let url=a["url"] as? String else{return}
        if let body=store.body(id){completion(body);return}
        if id==selected?["id"] as? String,bodyStatus != "loading",!articleRestricted,!articleBlocks.isEmpty{completion(extractedObject());return}
        status.stringValue="Retrieving article text…"
        js("article",url){[weak self] result,error in
            guard let self=self else{return}
            guard var result=result,result["restricted"] as? Bool != true,let blocks=result["blocks"] as? [[String:Any]],!blocks.isEmpty else{self.alert("Article text unavailable",error ?? "No freely accessible article text was returned.");return}
            result["article"]=a;completion(result)
        }
    }
    @objc func contextToggleLater(){
        guard let a=contextArticle,let id=a["id"] as? String else{return}
        if saved.contains(id){do{try store.removeBody(id);saved.remove(id);savedMeta.removeValue(forKey:id);finishContextChange()}catch{alert("Could not remove Read Later copy",error.localizedDescription)};return}
        guard saved.count<100 else{alert("Read Later limit","Keep up to 100 articles in Read Later.");return}
        withContextBody(a){[weak self] body in guard let self=self else{return};do{try self.store.keep(id,article:body);self.saved.insert(id);self.read.remove(id);var metadata=a;metadata["feedBlocks"]=[];self.savedMeta[id]=metadata;self.finishContextChange()}catch{self.alert("Could not save article",error.localizedDescription)}}
    }
    func markContextArticles(_ items:[[String:Any]],prompt:String){
        let pending=items.filter{!read.contains($0["id"] as? String ?? "")};guard !pending.isEmpty else{return}
        let a=NSAlert();a.messageText=prompt;a.informativeText="Mark \(pending.count) articles as read. Read Later copies follow your Article Storage settings.";a.addButton(withTitle:"Mark Read");a.addButton(withTitle:"Cancel");guard a.runModal() == .alertFirstButtonReturn else{return}
        do{for item in pending{guard let id=item["id"] as? String else{continue};try store.markRead(id,article:nil);read.insert(id);saved.remove(id);savedMeta.removeValue(forKey:id)}}catch{alert("Some articles could not be updated",error.localizedDescription)}
        finishContextChange()
    }
    @objc func contextMarkBelow(){markContextArticles(contextArticlesBelow,prompt:"Mark this article and those below it as read?")}
    @objc func contextCopyLink(){guard let link=contextArticle?["url"] as? String else{return};NSPasteboard.general.clearContents();NSPasteboard.general.setString(link,forType:.string);status.stringValue="Article link copied"}
    func contextText(_ article:[String:Any],_ body:[String:Any])->String{
        let blocks=body["blocks"] as? [[String:Any]] ?? []
        let warning=["feed-only","possibly-incomplete"].contains(body["status"] as? String ?? "") ? "Available text — may be incomplete\n\n":""
        return (article["title"] as? String ?? "Article")+"\n\n"+warning+blocks.filter{$0["type"] as? String != "image"}.compactMap{$0["text"] as? String}.joined(separator:"\n\n")+"\n\nSource: "+(article["url"] as? String ?? "")
    }
    @objc func contextCopyText(){guard let a=contextArticle else{return};withContextBody(a){[weak self] body in guard let self=self else{return};NSPasteboard.general.clearContents();NSPasteboard.general.setString(self.contextText(a,body),forType:.string);self.status.stringValue="Article text copied"}}
    @objc func contextEmail(){guard let a=contextArticle else{return};withContextBody(a){[weak self] body in guard let self=self else{return};let text=self.contextText(a,body);guard text.count<=12000,let url=ReaderLinks.compose(service:self.emailService,title:a["title"] as? String ?? "Article",body:text) else{self.alert("Article is too long for a mail link","Use Copy Article Text and paste into your draft to avoid truncation.");return};if url.scheme=="mailto"{NSWorkspace.shared.open(url)}else{self.openWeb(url)}}}
    @objc func contextOpenOriginal(){if let link=contextArticle?["url"] as? String,let url=URL(string:link){openWeb(url)}}
    @objc func contextOpenFeed(){guard let index=contextFeedIndex,feeds.indices.contains(index),let link=feeds[index]["url"] as? String,var u=URLComponents(string:link) else{return};u.path="/";u.query=nil;u.fragment=nil;if let url=u.url{openWeb(url)}}
    @objc func contextRefreshFeed(){guard let index=contextFeedIndex,feeds.indices.contains(index),loading==0 else{return};loadQueue=[feeds[index]];nextFeed()}
    @objc func contextMarkFeed(){guard let index=contextFeedIndex,feeds.indices.contains(index),let url=feeds[index]["url"] as? String else{return};markContextArticles(allArticles().filter{$0["feed"] as? String==url},prompt:"Mark this feed’s articles as read?")}
    @objc func contextEditFeed(){
        guard let index=contextFeedIndex,feeds.indices.contains(index) else{return}
        let a=NSAlert();a.messageText="Edit subscription";a.informativeText="Update the feed name and public RSS or Atom URL."
        let stack=NSStackView();stack.orientation = .vertical;stack.spacing=8;stack.frame=NSRect(x:0,y:0,width:380,height:68)
        let name=NSTextField(string:feeds[index]["name"] as? String ?? ""),address=NSTextField(string:feeds[index]["url"] as? String ?? "");for field in [name,address]{field.widthAnchor.constraint(equalToConstant:380).isActive=true;stack.addArrangedSubview(field)}
        a.accessoryView=stack;a.addButton(withTitle:"Save");a.addButton(withTitle:"Cancel");guard a.runModal() == .alertFirstButtonReturn else{return}
        do{let url=try ReaderNetwork.validated(address.stringValue);let old=feeds[index]["url"] as? String
            guard !feeds.enumerated().contains(where:{$0.offset != index && $0.element["url"] as? String==url.absoluteString}) else{alert("Duplicate feed","That feed is already subscribed.");return}
            feeds[index]=["name":name.stringValue.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? url.host ?? "Feed":name.stringValue,"url":url.absoluteString]
            if old != url.absoluteString{articles.removeAll{$0["feed"] as? String==old}}
            persist();sidebar.reloadData();rebuildList();refresh()
        }catch{alert("Invalid feed URL",error.localizedDescription)}
    }
    @objc func contextRemoveFeed(){guard let index=contextFeedIndex,feeds.indices.contains(index) else{return};sidebar.selectRowIndexes(IndexSet(integer:index+4),byExtendingSelection:false);removeFeed()}
}
