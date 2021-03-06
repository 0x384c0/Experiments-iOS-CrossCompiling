
//
//  PublishSubject.swift
//  yesno
//
//  Created by Andrew Ashurow on 12/9/15.
//  Copyright © 2015 0x384c0. All rights reserved.
//

import UIKit

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    func localized(_ comment: String = "") -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
    
    func getHtml(withFontSize size:CGFloat) -> String{
        //let fontSize:Int = Int(size * UIScreen.mainScreen().scale)
        let body = self
        var html = "<!DOCTYPE html>"
//        html += "<html lang=\"en\"><head>"
//        html += "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />"
//        html += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=no\">"
        html += "<style type=\"text/css\">"
        html += "body { "
        html += "font-family:  HelveticaNeue-Light !important; font-size:\(Int(size))px !important;"
//        html += "max-width:100%; width:auto; height:auto; margin-left:0; margin-right:0; "
        html += "}"
        html += "b { font-family: HelveticaNeue-Bold;  }"
        html += "strong { font-family: HelveticaNeue-Bold;  }"
        html += "em { font-family: HelveticaNeue-LightItalic;  }"
        html += "</style>"
        html += "</head>"
        html += "<body>"
        html += body
        html += "</body>"
        html += "</html>"
        
        return html
    }
    
    
    func replaceWithRegExp(_ find:String,replace:String) -> String{
        let range = NSMakeRange(0, characters.count)
        if let regex = try? NSRegularExpression(pattern: find, options: .caseInsensitive) {
            let modString = regex.stringByReplacingMatches(
                in: self,
                options: .withoutAnchoringBounds,
                range: range,
                withTemplate: replace
            )
            return modString
        }
        return self
    }
    
    static func fromCString (_ cs: UnsafePointer<CChar>, length: Int!) -> String? {
        if length == .none { // no length given, use \0 standard variant
            return String(cString: cs)
        }
        
        let buflen = length + 1
        let buf    = UnsafeMutablePointer<CChar>.allocate(capacity: buflen)
        memcpy(buf, cs, length)
        buf[length] = 0 // zero terminate
        let s = String(cString: buf)
        buf.deallocate(capacity: buflen)
        return s
    }    
    
}
