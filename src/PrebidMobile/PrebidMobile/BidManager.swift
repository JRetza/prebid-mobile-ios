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

@objcMembers class BidManager: NSObject {

    var prebidAdUnit: AdUnit

    private static var adUnits:[AdUnit] = []
    private static var adUnitBidMap:[String : [AdUnitBidMap]] = [:]
    private static var bidMap:[String : [Bid]] = [:]
    
    
    init(adUnit: AdUnit) {

        prebidAdUnit = adUnit
        super.init()
    }
    
    static func addAdUnitBidMap(prebidAdUnit:AdUnit, adView:AnyObject) -> AdUnitBidMap {
        let newObj = AdUnitBidMap(adView: adView, adUnitCode: prebidAdUnit.identifier)
        if var adUnitbidMaps = BidManager.adUnitBidMap[prebidAdUnit.identifier] {
            adUnitbidMaps.append(newObj)
        } else {
            BidManager.adUnitBidMap[prebidAdUnit.identifier] = [newObj]
        }
        return newObj
    
    }
    
    static func addAdUnit(prebidAdUnit:AdUnit) {
        BidManager.adUnits.append(prebidAdUnit)
    }
    
    static func saveBids(prebidAdUnit:AdUnit, bids:[Bid]) {
        BidManager.bidMap[prebidAdUnit.identifier] = bids
    }
    
    static func getBidsForAdUnit(adUnitCode:String) -> [Bid] {
        return BidManager.bidMap[adUnitCode] ?? []
    }
    
    static func getAdUnitMapByAdView(adView:AnyObject) -> AdUnitBidMap? {
        for item in BidManager.adUnitBidMap {
            for bidAdUnitMap in item.value {
                if bidAdUnitMap.adView === adView {
                    return bidAdUnitMap
                }
            }
        }
        
        return nil
    }
    
    static func getAdUnitByCode(code:String) -> AdUnit? {
        for adUnit in self.adUnits {
            if (adUnit.identifier == code) {
                return adUnit
            }
        }
        return nil
    }
    
    static func gatherSizes(adUnitBidMap:AdUnitBidMap) -> NSMutableDictionary {
        let sizesDict = NSMutableDictionary()
        let sizeArr = NSMutableArray()
        let sizeObj = BidManager.gatherSize(adUnitBidMap: adUnitBidMap)
        sizeArr.add(sizeObj)
        sizesDict["sizes"] = sizeArr
        
        return sizesDict;
    }
    
    static func gatherSize(adUnitBidMap:AdUnitBidMap) -> NSMutableDictionary {
        
        let sizeDict = NSMutableDictionary();
        if let adUnit = BidManager.getAdUnitByCode(code: adUnitBidMap.adUnitCode) {
            
            let prebidDict = NSMutableDictionary();
            let tiersList = NSMutableArray();
            let tierDict = NSMutableDictionary();
            let bidsList = NSMutableArray();
            let adserverDict = NSMutableDictionary();
            let deliveryDict = NSMutableDictionary();
            
            sizeDict.setValue(0, forKey: "id")
            sizeDict.setValue(adUnitBidMap.isDefault, forKey: "isDefault")
            sizeDict.setValue(true, forKey: "viaAdserver")
            sizeDict.setValue(true, forKey: "active")
            sizeDict.setValue(adUnit.getTimeToLoad(), forKey: "timeToLoad")
            
            
            
            adserverDict.setValue("DFP", forKey: "name")
            adserverDict.setValue(adUnitBidMap.adView.value(forKey: "adUnitID") as? String, forKey: "id")
            
            deliveryDict.setValue(adUnitBidMap.lineItemId, forKey: "lineitemId")
            deliveryDict.setValue(adUnitBidMap.creativeId, forKey: "creativeId")
            
            adserverDict.setValue(deliveryDict, forKey: "delivery")
            sizeDict.setValue(adserverDict, forKey: "adserver")
            
            
            sizeDict.setValue(prebidDict, forKey: "prebid")
            prebidDict.setValue(tiersList, forKey: "tiers")
            
            tiersList.add(tierDict)
            tierDict.setValue(0, forKey: "id")
            
            
            let bids = BidManager.getBidsForAdUnit(adUnitCode: adUnitBidMap.adUnitCode)
         
            for bid in bids {
                bidsList.add(bid.gatherBidJSON())
            }
            
            
            tierDict.setValue(bidsList, forKey: "bids")
            
            
            
        }
        
        return sizeDict
    }
    
 
    
    static func gatherPlacements() -> NSMutableArray {
        let placementDict = NSMutableArray()
        for item in BidManager.adUnitBidMap {
            for bidAdUnitMap in item.value {
                if (!bidAdUnitMap.isServerUpdated) { placementDict.add(BidManager.gatherSizes(adUnitBidMap: bidAdUnitMap))
                }
                bidAdUnitMap.isServerUpdated = true;
            }
        }
    
        return placementDict;
    }
    

    dynamic func requestBidsForAdUnit(callback: @escaping (_ response: BidResponse?, _ result: ResultCode) -> Void) {

        do {
            try RequestBuilder.shared.buildPrebidRequest(adUnit: prebidAdUnit) {(urlRequest) in
                let demandFetchStartTime = BidManager.getCurrentMillis()
                URLSession.shared.dataTask(with: urlRequest!) { data, _, error in
                    let demandFetchEndTime = BidManager.getCurrentMillis()
                    guard error == nil else {
                        print("error calling GET on /todos/1")
                        return
                    }

                    // make sure we got data
                    if (data == nil ) {
                        print("Error: did not receive data")
                        callback(nil, ResultCode.prebidNetworkError)

                    }
                    if (!Prebid.shared.timeoutUpdated) {
                        let tmax = self.getTmaxRequest(data!)
                        if (tmax > 0) {
                            Prebid.shared.timeoutMillis = min(demandFetchEndTime - demandFetchStartTime + tmax + 200, .PB_Request_Timeout)
                            Prebid.shared.timeoutUpdated = true
                        }
                    }
                    let processData = self.processBids(data!)
                    var bidMap: [String: AnyObject] = processData.0
                    let bids = processData.1
                    let result: ResultCode = processData.2
                    
                    BidManager.saveBids(prebidAdUnit: self.prebidAdUnit, bids: bids)
                    
                    if let winner = bids.sorted(by: { $0.cpm > $1.cpm }).first {
                        let winnerKeywords = winner.getKeywords()
                        for winnerKeyword in winnerKeywords.keys {
                            bidMap[winnerKeyword] = winnerKeywords[winnerKeyword] as AnyObject
                        }
                    } 
                    print("result is " + result.name())
                    if (result == ResultCode.prebidDemandFetchSuccess) {
                            let bidResponse = BidResponse(adId: "PrebidMobile", adServerTargeting: bidMap)
                            Log.info("Bid Successful with rounded bid targeting keys are \(bidResponse.customKeywords) for adUnit id is \(bidResponse.adUnitId)")
                        
                        DispatchQueue.main.async {
                            
                            bidResponse.setBids(bids: bids)
                            callback(bidResponse, ResultCode.prebidDemandFetchSuccess)
                        }
                        
                        
                        
                        
                        
                        
                    } else {
                        DispatchQueue.main.async {
                            callback(nil, result)
                        }
                    }

                    }.resume()

            }

        } catch let error {
            print(error.localizedDescription)
            
            let errorCode = ResultCode.prebidServerURLInvalid
            Log.error(errorCode.name())
            callback(nil, errorCode)
        }
    }

    func processBids(_ data: Data) -> ([String: AnyObject], [Bid], ResultCode) {

        do {
            let errorString: String = String.init(data: data, encoding: .utf8)!
            print(String(format: "Response from server: %@", errorString))
            if (!errorString.contains("Invalid request")) {
                let response: [String: AnyObject] = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]

                var bidDict: [String: AnyObject] = [:]
                var containTopBid = false

                guard response.count > 0, response["seatbid"] != nil else { return ([:], [], ResultCode.prebidDemandNoBids)}
                let seatbids = response["seatbid"] as! [AnyObject]
                
                var bidObjects:[Bid] = []
                for seatbid in seatbids {
                    var seatbidDict = seatbid as? [String: AnyObject]
                    guard seatbid is [String: AnyObject], seatbidDict?["bid"] is [AnyObject] else { break }
                    
                    var responseTime = 0
                    let bidderName = seatbidDict?["seat"] as? String
                    if let extObj = response["ext"] as? [String: AnyObject] {
                        if let responseTimeObj = extObj["responsetimemillis"] as? [String:AnyObject] {
                            if bidderName != nil {
                                if let time = responseTimeObj[bidderName!] as? Int {
                                    responseTime = time
                                }
                            }
                        }
                    }
                    
                    let bids = seatbidDict?["bid"] as! [AnyObject]
                    for bid in bids {
                        let mutableBid = bid.mutableCopy() as! NSMutableDictionary
                        mutableBid.setValue(String(format: "Prebid_%@_%lld", String(format: "%08X", arc4random()),  Int(Date().timeIntervalSince1970 * 1000)), forKey: "cache_id")
                        let bidObject = Bid(bidDictionary: mutableBid)
                        bidObject.bidderCode = bidderName
                        bidObject.dealId = bid["dealId"] as? String
                        bidObject.responseTime = responseTime
                        bidObjects.append(bidObject)
                       
                        var containBid = false
                        var adServerTargeting: [String: AnyObject]?
                        guard bid["ext"] != nil else { break }
                        let extDict: [String: Any] = bid["ext"] as! [String: Any]
                        guard extDict["prebid"] != nil else { break }
                        let prebidDict: [String: Any] = extDict["prebid"] as! [String: Any]
                        adServerTargeting = prebidDict["targeting"] as? [String: AnyObject]
                        guard adServerTargeting != nil else { break }
                        for key in adServerTargeting!.keys {
                            if (key == "hb_cache_id") {
                                containTopBid = true
                             }
                            if (key.starts(with: "hb_cache_id")) {
                                containBid = true
                            }
                        }
                        guard containBid else {  break }
                        for (key, value) in adServerTargeting! {
                            bidDict[key] = value
                        }
                    }
              }
                
               
                
                if (containTopBid && bidDict.count > 0) {
                    return (bidDict, bidObjects, ResultCode.prebidDemandFetchSuccess)
                } else {
                    return ([:], [], ResultCode.prebidDemandNoBids)
                }
            } else {
                if (errorString.contains("Stored Imp with ID") || errorString.contains("No stored imp found")) {
                    return ([:], [], ResultCode.prebidInvalidConfigId)
                } else if (errorString.contains("Stored Request with ID") || errorString.contains("No stored request found")) {
                    return ([:], [], ResultCode.prebidInvalidAccountId)
                } else if ((errorString.contains("Invalid request: Request imp[0].banner.format")) || errorString.contains("Request imp[0].banner.format") || (errorString.contains("Unable to set interstitial size list"))) {
                    return ([:], [], ResultCode.prebidInvalidSize)
                } else {
                    return ([:], [], ResultCode.prebidServerError)
                }
            }

        } catch let error {
            print(error.localizedDescription)

            return ([:], [], ResultCode.prebidDemandNoBids)
        }

    }

    static func getCurrentMillis() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    func getTmaxRequest(_ data: Data) -> Int {
        do {
            let response: [String: AnyObject] = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
            let ext = response["ext"] as! [String: AnyObject]
            if (ext["tmaxrequest"] != nil) {
                return  ext["tmaxrequest"] as! Int
            }
        } catch let error {
            print(error.localizedDescription)
        }
        return -1
    }
}
