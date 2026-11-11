import AppKit

// Render the existing web/favicon.svg geometry without changing the Leaf Reader logo.
let directory=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
for (name,pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
 let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
 let transform=NSAffineTransform();transform.translateX(by:0,yBy:CGFloat(pixels));transform.scaleX(by:CGFloat(pixels)/512,yBy:-CGFloat(pixels)/512);transform.concat()
 let green=NSColor(srgbRed:52/255,green:75/255,blue:59/255,alpha:1)
 green.setFill();NSBezierPath(roundedRect:NSRect(x:0,y:0,width:512,height:512),xRadius:112,yRadius:112).fill()
 let leaf=NSBezierPath();leaf.move(to:NSPoint(x:137,y:375));leaf.curve(to:NSPoint(x:379,y:101),controlPoint1:NSPoint(x:92,y:211),controlPoint2:NSPoint(x:227,y:115));leaf.curve(to:NSPoint(x:137,y:375),controlPoint1:NSPoint(x:386,y:269),controlPoint2:NSPoint(x:307,y:402));leaf.close();NSColor(srgbRed:229/255,green:235/255,blue:220/255,alpha:1).setFill();leaf.fill()
 let stem=NSBezierPath();stem.move(to:NSPoint(x:137,y:375));stem.line(to:NSPoint(x:336,y:151));stem.lineWidth=14;stem.lineCapStyle = .round;green.setStroke();stem.stroke()
 NSGraphicsContext.restoreGraphicsState();try rep.representation(using:.png,properties:[:])!.write(to:directory.appendingPathComponent(name+".png"))
}
