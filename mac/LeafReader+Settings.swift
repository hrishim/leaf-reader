import AppKit
import WebKit

extension LeafReader {
    func applyReadingStyle(){
        let family=articleFontStyle=="sans" ? "-apple-system, sans-serif":"Georgia, serif"
        detail.callAsyncJavaScript("document.documentElement.dataset.theme=theme;document.body.style.fontSize=size+'px';document.body.style.fontFamily=family;document.body.style.lineHeight=spacing;const heading=document.querySelector('h1');if(heading){heading.style.fontSize=titleScale+'em';heading.style.fontFamily=family;}",arguments:["theme":appearanceTheme,"size":fontSize,"family":family,"spacing":articleSpacing,"titleScale":articleTitleScale],in:nil,in:.page){_ in}
        window?.appearance=appearanceTheme=="system" ? nil:NSAppearance(named:appearanceTheme=="dark" ? .darkAqua:.aqua)
    }
    func changeReadingSettings(size:Int,interfaceSize:Double,font:String,spacing:Double,title:Double,theme:String){
        fontSize=min(36,max(14,size));interfaceFontSize=min(20,max(11,interfaceSize.isFinite ? interfaceSize:13));articleFontStyle=font=="sans" ? "sans":"serif";articleSpacing=min(2.2,max(1.3,spacing.isFinite ? spacing:1.85));articleTitleScale=min(2.5,max(1.3,title.isFinite ? title:2.1));appearanceTheme=["system","light","dark"].contains(theme) ? theme:"system"
        applyReadingStyle();sidebar.reloadData();list.reloadData();list.noteHeightOfRows(withIndexesChanged:IndexSet(integersIn:0..<visible.count));persist()
    }
    @objc func settingsChanged(_ sender:NSControl){
        guard let size=settingsWidgets["size"] as? NSSlider,let ui=settingsWidgets["ui"] as? NSSlider,let spacing=settingsWidgets["spacing"] as? NSSlider,let title=settingsWidgets["title"] as? NSSlider,let font=settingsWidgets["font"] as? NSPopUpButton,let theme=settingsWidgets["theme"] as? NSPopUpButton else{return}
        changeReadingSettings(size:Int(size.doubleValue.rounded()),interfaceSize:ui.doubleValue.rounded(),font:font.indexOfSelectedItem==0 ? "serif":"sans",spacing:(spacing.doubleValue*20).rounded()/20,title:(title.doubleValue*10).rounded()/10,theme:["system","light","dark"][theme.indexOfSelectedItem])
        updateSettingsLabels()
    }
    func updateSettingsLabels(){
        settingsLabels["size"]?.stringValue="Article text size: \(fontSize) px"
        settingsLabels["ui"]?.stringValue="Interface text size: \(Int(interfaceFontSize)) pt"
        settingsLabels["spacing"]?.stringValue=String(format:"Line spacing: %.2f",articleSpacing)
        settingsLabels["title"]?.stringValue=String(format:"Title size: %.1f×",articleTitleScale)
    }
    @objc func openSettings(){
        let alert=NSAlert();alert.messageText="Leaf Reader Settings";alert.informativeText="Reading and appearance changes apply immediately and are saved on this Mac."
        let tabs=NSTabView(frame:NSRect(x:0,y:0,width:600,height:350));settingsWidgets=[:];settingsLabels=[:]
        func tab(_ title:String)->NSStackView{let item=NSTabViewItem(identifier:title);item.label=title;let stack=NSStackView();stack.orientation = .vertical;stack.alignment = .leading;stack.spacing=10;stack.edgeInsets=NSEdgeInsets(top:16,left:16,bottom:16,right:16);item.view=stack;tabs.addTabViewItem(item);return stack}
        func slider(_ key:String,_ value:Double,_ min:Double,_ max:Double,_ parent:NSStackView){let label=NSTextField(labelWithString:"");settingsLabels[key]=label;parent.addArrangedSubview(label);let control=NSSlider(value:value,minValue:min,maxValue:max,target:self,action:#selector(settingsChanged(_:)));control.isContinuous=true;control.widthAnchor.constraint(equalToConstant:385).isActive=true;settingsWidgets[key]=control;parent.addArrangedSubview(control)}
        func popup(_ key:String,_ label:String,_ values:[String],_ index:Int,_ parent:NSStackView){parent.addArrangedSubview(NSTextField(labelWithString:label));let control=NSPopUpButton();control.addItems(withTitles:values);control.selectItem(at:index);control.target=self;control.action=#selector(settingsChanged(_:));control.widthAnchor.constraint(equalToConstant:385).isActive=true;settingsWidgets[key]=control;parent.addArrangedSubview(control)}
        let reading=tab("Reading");slider("size",Double(fontSize),14,36,reading);popup("font","Article font",["Serif","System sans serif"],articleFontStyle=="sans" ? 1:0,reading);slider("spacing",articleSpacing,1.3,2.2,reading);slider("title",articleTitleScale,1.3,2.5,reading)
        let appearance=tab("Appearance");slider("ui",interfaceFontSize,11,20,appearance);popup("theme","Theme",["System","Light","Dark"],["system","light","dark"].firstIndex(of:appearanceTheme) ?? 0,appearance);appearance.addArrangedSubview(NSTextField(wrappingLabelWithString:"Interface size changes feed names and article-list text. Article text size is controlled separately under Reading."))
        let accounts=tab("Accounts & Import");let manage=NSButton(title:"Accounts, RSS & OPML…",target:self,action:#selector(libraryCenter));accounts.addArrangedSubview(manage);accounts.addArrangedSubview(NSTextField(wrappingLabelWithString:"Local public feeds work without sign-in. Service synchronization is not yet available. OPML imports preserve folders and preview changes before adding feeds."));let behavior=tab("Behavior");for(key,title,value) in [("markOnOpen","Mark read when opening an article",markOnOpen),("oldestFirst","Oldest articles first",oldestFirst)]{let button=NSButton(checkboxWithTitle:title,target:self,action:#selector(behaviorChanged(_:)));button.state=value ? .on:.off;settingsWidgets[key]=button;behavior.addArrangedSubview(button)};behavior.addArrangedSubview(NSTextField(wrappingLabelWithString:"Unread items leave the list after you move on. Mark All Read affects the current view and asks for confirmation. Use View → Next Unread (Command-J) to continue reading."));let general=tab("General");for(title,action) in [("Browser & Email…",#selector(browserSettings)),("Article Storage…",#selector(retentionSettings))]{let button=NSButton(title:title,target:self,action:action);general.addArrangedSubview(button)};general.addArrangedSubview(NSTextField(wrappingLabelWithString:"Use the View menu for refresh, Reader mode, marking articles read and the sidebar. Reading history and Read Later copies are stored locally."))
        alert.accessoryView=tabs;alert.addButton(withTitle:"Done");alert.addButton(withTitle:"Reset Appearance");updateSettingsLabels()
        if alert.runModal() == .alertSecondButtonReturn{changeReadingSettings(size:19,interfaceSize:13,font:"serif",spacing:1.85,title:2.1,theme:"system")}
        settingsWidgets=[:];settingsLabels=[:]
    }
}
