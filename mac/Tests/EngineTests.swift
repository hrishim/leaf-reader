import AppKit
import WebKit
@main final class EngineTests:NSObject,NSApplicationDelegate,WKNavigationDelegate {
 var web:WKWebView!
 static func main(){let app=NSApplication.shared;let delegate=EngineTests();app.delegate=delegate;app.run();withExtendedLifetime(delegate){}}
 func applicationDidFinishLaunching(_ notification:Notification){web=WKWebView();web.navigationDelegate=self;web.loadHTMLString("<html><body></body></html>",baseURL:nil)}
 func webView(_ webView:WKWebView,didFinish navigation:WKNavigation!){do{let root=URL(fileURLWithPath:ProcessInfo.processInfo.environment["READER_SOURCE"]!);let code=try String(contentsOf:root.appendingPathComponent("mac/Resources/Readability.js"),encoding:.utf8)+"\n"+String(contentsOf:root.appendingPathComponent("mac/Resources/reader-engine.js"),encoding:.utf8)+"\n"+String(contentsOf:root.appendingPathComponent("mac/Tests/engine-tests.js"),encoding:.utf8);web.callAsyncJavaScript(code,arguments:["ciplaHTML":(try? String(contentsOf:root.appendingPathComponent("qa/cipla.html"),encoding:.utf8)) ?? ""],in:nil,in:.page){result in switch result{case .success(let value):print(value);exit(0);case .failure(let error):fputs(error.localizedDescription+"\n",stderr);exit(1)}}}catch{print(error);exit(1)}}
}
