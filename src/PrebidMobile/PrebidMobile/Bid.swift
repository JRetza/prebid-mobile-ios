//
//  Bid.swift
//  PrebidMobile
//
//  Created by L.D. Deurman on 30/05/2019.
//  Copyright © 2019 AppNexus. All rights reserved.
//

import Foundation
import UIKit
//Added from https://gist.githubusercontent.com/pwightman/64c57076b89c5d7f8e8c/raw/23d99284e1b6c3b57f0fcc41847fa8e87d955188/JavaScriptEncode.swift
extension String {
    func javaScriptEscapedString() -> String {
        // Because JSON is not a subset of JavaScript, the LINE_SEPARATOR and PARAGRAPH_SEPARATOR unicode
        // characters embedded in (valid) JSON will cause the webview's JavaScript parser to error. So we
        // must encode them first. See here: http://timelessrepo.com/json-isnt-a-javascript-subset
        // Also here: http://media.giphy.com/media/wloGlwOXKijy8/giphy.gif
        
        let str = self.replacingOccurrences(of: "\u{2028}", with: "\\u2028").replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        
        
        // Because escaping JavaScript is a non-trivial task (https://github.com/johnezang/JSONKit/blob/master/JSONKit.m#L1423)
        // we proceed to hax instead:
        let data = try! JSONSerialization.data(withJSONObject: [str], options: [])
        let encodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!
        return encodedString.substring(with: NSMakeRange(1, encodedString.length - 2))
    }
}



class Bid {
    
    private var bidDictionary:NSDictionary
    
    var width:Int!
    var height:Int!
    var cpm:CGFloat!
    var cacheId:String!
    
    var bidderCode:String?
    var dealId:String?
    var targetingKeywords:[String: String] = [:]
    
    var responseTime = 0
    var winner = false;
    
    
    init (bidDictionary:NSDictionary) {
        self.bidDictionary = bidDictionary
        self.width = bidDictionary["w"] as? Int
        self.cpm = bidDictionary["price"] as? CGFloat
        self.height = bidDictionary["h"] as? Int
        self.cacheId = bidDictionary["cache_id"] as? String
       
        let extDict: [String: Any] = bidDictionary["ext"] as! [String: Any]
        let prebidDict: [String: Any] = extDict["prebid"] as! [String: Any]
        if let adServerTargeting = prebidDict["targeting"] as? [String: String] {
            self.targetingKeywords = adServerTargeting
        }
        
    
        
        
    }
    
    func getKeywords() -> [String : String] {
        var keywords:[String : String] = [:]
        
        for key in self.targetingKeywords.keys {
            keywords[key] = self.targetingKeywords[key]
        }
        
        if let bidderName = self.bidderCode {
            let cacheIdKey = "hb_cache_id_" + bidderName;
            keywords[cacheIdKey] = self.getCreative()
        }
        
        let prefix = "pb_";
        if let winnerBidder = self.bidderCode {
            keywords[prefix + "winner"] = winnerBidder
        }
        
        keywords[prefix + "cpm"] = round(self.cpm * 100).description
        keywords[prefix + "size"] = getSize()
        keywords["hb_size"] = getSize()
        
        if let dealId = self.dealId {
            keywords[prefix + "deal"] = dealId
        }
        
        keywords["hb_env"] = "mobile-app"
        keywords["hb_format"] = "html"
        
        
        keywords["hb_cache_id"] = getCreative()
        
        return keywords
    }
    
    func getCreative() -> String {
        return self.cacheId
    }
    
    func getJSON() -> String? {
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: self.bidDictionary,
            options: []) {
            let theJSONText = String(data: theJSONData,
                                     encoding: .utf8)
            return theJSONText
        }
        return nil
    }
    
    func getSize() -> String {
        return self.width.description + "x" + self.height.description
    }
    
    func setWinner() {
        self.winner = true;
    }
    
    func gatherBidJSON() -> NSMutableDictionary {
        let bidObj = NSMutableDictionary()
        bidObj.setValue(self.bidderCode, forKey: "bidder")
        bidObj.setValue(self.winner, forKey: "winner")
        bidObj.setValue(round(self.cpm * 1000), forKey: "cpm")
        bidObj.setValue(nil, forKey: "origCPM")
        bidObj.setValue(getSize(), forKey: "size")
        bidObj.setValue(1, forKey: "state")
        bidObj.setValue(self.responseTime, forKey: "time")
        if self.dealId != nil {
            bidObj.setValue(self.dealId, forKey: "dealId")
        }
        
        return bidObj;
    }
    
   
}
