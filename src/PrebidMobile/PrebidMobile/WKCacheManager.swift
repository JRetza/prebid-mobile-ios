//
//  CacheManager.swift
//  PrebidMobile
//
//  Created by L.D. Deurman on 30/05/2019.
//  Copyright © 2019 AppNexus. All rights reserved.
//



import Foundation
import WebKit
import UIKit

typealias CompletionHandler = () -> Void

public class WKCacheManager : NSObject, WKNavigationDelegate {
    
    
    private static var cache:WKCacheManager?
    
    private let configuration = WKWebViewConfiguration()
     
    private var navigationDelegate:WKNavigationDelegate!
    private var webView:WKWebView!
    private var startTime:Double!
    private var isWebViewFinished = false;
    private var webViewCompletionHandlers:[CompletionHandler] = [];
    
    public override init() {
        super.init()
        
        self.startTime = Date().timeIntervalSince1970
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.navigationDelegate = self
        self.webView.navigationDelegate = navigationDelegate;
        UIApplication.shared.keyWindow!.addSubview(webView)
        
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        print("CacheManager initialization took " + elapsedTime.description + " ms")
        self.webViewCompletionHandlers.append({
            self.cleanupBids()
            self.setupBidCleanup()
        })
        setupCache()
    }
    
    public static func configure() {
        if (WKCacheManager.cache == nil) {
            WKCacheManager.cache = WKCacheManager();
        }
    }
    
    private func debugLocalStorageInfo() {
        self.webView.evaluateJavaScript("window.location.host + ' has ' + localStorage.length + ' localStorage items'", completionHandler: {
            obj, error in
            
            if let result = obj {
                print(result)
            } else {
                print("JS localStorage info debug didn't return a value")
            }
            
        })
    }
    
    private func cacheBids(bids:[Bid], completion:@escaping CompletionHandler) {
        
        var jsObjects:[String] = []
        for bid in bids {
            if let jsonString = bid.getJSON() {
                jsObjects.append(String(format: "{creative: '%@', bid: %@}", bid.getCreative(), jsonString))
            }
        }
        
        
        
        let arrayStr = String(format: "var items = [" + jsObjects.joined(separator: ",")) + "]";
        let script =  "" +
            "\n" +
            arrayStr +
            "\n" +
            "for (var i = 0; i < items.length; i++) {\n" +
            "  var item = items[i];\n" +
            "  localStorage.setItem(item.creative, JSON.stringify(item.bid));\n" +
            "}" + "\n\n"
        
        
        let dateStarted = Date()
        self.webView.evaluateJavaScript(script, completionHandler: {
            obj, error in
            
            let elapsedTime = self.getTimeElapsed(startTime: dateStarted)
            print("CacheManager did cache bids in " + elapsedTime.description + " ms")
            completion()
            
        })
        
        
        debugLocalStorageInfo()
        
        
    }
    
    func saveBids(bids:[Bid], completion:@escaping CompletionHandler) {
        DispatchQueue.main.async {
            if self.isWebViewFinished {
                self.cacheBids(bids: bids, completion: completion)
            } else {
                self.webViewCompletionHandlers.append({
                    self.cacheBids(bids: bids, completion: completion)
                })
            }
        }
    }
    
    static func getCacheManager() -> WKCacheManager {
        return WKCacheManager.cache!
    }
    
    private func setupCache() {
        if let url = URL(string: "https://pubads.g.doubleclick.net") {
            webView.loadHTMLString("<html></html>", baseURL: url)
        }
    }
    
    private func getTimeElapsed(startTime:Date? = nil) -> Double {
        
        var startTimeMillis:Double = 0
        if startTime != nil {
            startTimeMillis = startTime!.timeIntervalSince1970
        } else {
            startTimeMillis = self.startTime
        }
        
        let elapsedTime = Date().timeIntervalSince1970 - startTimeMillis
        return elapsedTime
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        print("CacheManager webView loaded in " + elapsedTime.description + " ms")
        
        self.isWebViewFinished = true;
        
        for webViewCompletion in self.webViewCompletionHandlers {
            webViewCompletion()
        }
        self.webViewCompletionHandlers = []
    }
    
    private func cleanupBids() {
        let startDate = Date()
        let now = startDate.timeIntervalSince1970 * 1000;
        let nowString = String(now);
        let removeCacheScript = "var currentTime = " + nowString + ";" +
            "\nvar toBeDeleted = [];\n" +
            "\n" +
            "for(i = 0; i< localStorage.length; i ++) {\n" +
            "\tif (localStorage.key(i).startsWith('Prebid_')) {\n" +
            "\t\tcreatedTime = localStorage.key(i).split('_')[2];\n" +
            "\t\tif (( currentTime - createdTime) > 270000){\n" +
            "\t\t\ttoBeDeleted.push(localStorage.key(i));\n" +
            "\t\t}\n" +
            "\t}\n" +
            "}\n" +
            "\n" +
            "for ( i = 0; i< toBeDeleted.length; i ++) {\n" +
            "\tlocalStorage.removeItem(toBeDeleted[i]);\n" +
        "}";
        
       
        self.webView.evaluateJavaScript(removeCacheScript, completionHandler: {
            obj, error in
            
            let elapsedTime = self.getTimeElapsed(startTime: startDate)
            print("CacheManager did do cleanup in " + elapsedTime.description + " ms")
        
            
        })
    }
    
    private func setupBidCleanup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: {
            self.cleanupBids()
            self.setupBidCleanup()
        })
    }
    
    
}
