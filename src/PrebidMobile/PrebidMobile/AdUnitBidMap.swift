//
//  AdUnitBidMap.swift
//  PrebidMobile
//
//  Created by L.D. Deurman on 31/05/2019.
//  Copyright © 2019 AppNexus. All rights reserved.
//

import Foundation
class AdUnitBidMap {
    
    public var adView:AnyObject
    public var adUnitCode:String
    
    public var isWinner = false
    public var isDefault = false
    public var isServerUpdated = false
    
    public var lineItemId:String = "";
    public var creativeId:String = "";
    
    init(adView:AnyObject, adUnitCode:String) {
        self.adView = adView;
        self.adUnitCode = adUnitCode;
    }
    
    
}
