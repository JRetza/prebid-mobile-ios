/*   Copyright 2018-2019 Prebid.org, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objcMembers public class Prebid: NSObject {
    public var timeoutMillis: Int = .PB_Request_Timeout
    var timeoutUpdated: Bool = false

    public var prebidServerAccountId: String! = ""
    
    public var appPage:String! = ""
    
    public var appName:String! = ""
    
    public var lastGatherStats:Double?
    

    /**
    * This property is set by the developer when he is willing to share the location for better ad targeting
    **/
    private var geoLocation: Bool = false
    public var shareGeoLocation: Bool {
        get {
           return geoLocation
        }

        set {
            geoLocation = newValue
            if (geoLocation == true) {
                Location.shared.startCapture()
            } else {
                Location.shared.stopCapture()
            }
        }
    }

    public var prebidServerHost: PrebidHost = PrebidHost.Custom {
        didSet {
            timeoutMillis = .PB_Request_Timeout
            timeoutUpdated = false
        }
    }

    /**
     * The class is created as a singleton object & used
     */
    public static let shared = Prebid()

    /**
     * The initializer that needs to be created only once
     */
    private override init() {
        super.init()
        if (RequestBuilder.myUserAgent == "") {
            RequestBuilder.UserAgent {(userAgentString) in
                Log.info(userAgentString)
                RequestBuilder.myUserAgent = userAgentString
            }
        }
    }
    


    public func setCustomPrebidServer(url: String) throws {

        if (Host.shared.verifyUrl(urlString: url) == false) {
                throw ErrorCode.prebidServerURLInvalid(url)
        } else {
            prebidServerHost = PrebidHost.Custom
            Host.shared.setHostURL = url
        }
    }
    
    func gatherPlacements() -> NSMutableArray {
        
        return BidManager.gatherPlacements()
    }
    
    public func markAdUnitLoaded(adView:AnyObject) {
        let bidMap = BidManager.getAdUnitMapByAdView(adView: adView)
        
        if (bidMap != nil) {
            bidMap!.isServerUpdated = false;
            let adUnit = BidManager.getAdUnitByCode(code: bidMap!.adUnitCode)
            adUnit?.stopLoadTime = BidManager.getCurrentMillis()
        }
    }
    
    public func markWinner(adUnitCode:String, creativeCode:String) {
        let bids = BidManager.getBidsForAdUnit(adUnitCode: adUnitCode)
        for bid in bids {
            if bid.getCreative() == creativeCode {
                bid.setWinner()
            }
        }
    }
    
    public func adUnitReceivedAppEvent(adView:AnyObject, instruction:String, prm:String?) {
        
        if prm != nil {
            if instruction == "deliveryData" {
                let serveData = prm!.components(separatedBy: "|")
                if serveData.count == 2 {
                    let lineItemId = serveData[0]
                    let creativeId = serveData[1]
                    if let adUnitBidMap = BidManager.getAdUnitMapByAdView(adView: adView) {
                        adUnitBidMap.lineItemId = lineItemId
                        adUnitBidMap.creativeId = creativeId
                    }
                }
            } else if instruction == "wonHB" {
                if let adUnitBidMap = BidManager.getAdUnitMapByAdView(adView: adView) {
                    markWinner(adUnitCode: adUnitBidMap.adUnitCode, creativeCode: prm!);
                }
            }
        }
        
        
        
    }
    
    
    
    public func adUnitReceivedDefault(adView:AnyObject) {
        let bidMap = BidManager.getAdUnitMapByAdView(adView: adView)
        bidMap?.isDefault = true
    }
    
    func trackStats(dictionary:NSMutableDictionary) {
        
        
        var mutableRequest = URLRequest(url: URL(string: "https://tagmans3.adsolutions.com/log/")!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 1000)
        mutableRequest.httpMethod = "POST"
        
        let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        mutableRequest.httpBody = data
        
        URLSession.shared.dataTask(with: mutableRequest, completionHandler: {
            data, urlResponse, error in
            
            if (error != nil) {
                print("Statstracker finished with error: ")
                print(error?.localizedDescription)
            }
            
        }).resume()
        
    }
    
    public func gatherStats() {
        let statsDict = NSMutableDictionary()
        let height = UIScreen.main.bounds.size.height;
        let width = UIScreen.main.bounds.size.width;
        let language = Locale.preferredLanguages.first
        
        
        statsDict["client"] = self.prebidServerAccountId
        statsDict["host"] = self.appName;
        statsDict["page"] = self.appPage;
        statsDict["proto"] = "https:";
        statsDict["duration"] = 0;
        statsDict["screenWidth"] = width;
        statsDict["screenHeight"] = height;
        statsDict["language"] = language;
        let currentTime = Date().timeIntervalSince1970 * 1000
        if let gatheredStats = self.lastGatherStats {
            statsDict["duration"] = currentTime - gatheredStats
        }
        let placements = self.gatherPlacements()
        statsDict["placements"] = placements
        
        self.lastGatherStats = currentTime
        if placements.count > 0 {
            print("Gather stats sent with " + statsDict.description)
            trackStats(dictionary: statsDict)
        } else {
            print("Ignoring gatherStats because now changes are made")
        }
        
        
    
        
    }
    
   
}
