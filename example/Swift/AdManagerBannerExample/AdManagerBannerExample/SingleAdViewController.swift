//
//  ViewController.swift
//  AdManagerBannerExample
//
//  Created by L.D. Deurman on 28/05/2019.
//  Copyright © 2019 adsolutions. All rights reserved.
//

import UIKit
import PrebidMobile
import GoogleMobileAds

class SingleAdViewController: UIViewController, GADBannerViewDelegate, GADAppEventDelegate {

    @IBOutlet weak var dfpBannerView: DFPBannerView!
    
    var bannerAdUnit:BannerAdUnit!
    var request = DFPRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        Prebid.shared.appPage = "SingleAdViewController";
        Prebid.shared.appName = "AdManagerBannerExample";
        
        self.bannerAdUnit = BannerAdUnit(configId: "test-imp-id", size: CGSize(width: 300, height: 250))
        
        self.dfpBannerView.adUnitID = "/2172982/mobile-sdk";
        self.dfpBannerView.backgroundColor = UIColor.red
        self.dfpBannerView.rootViewController = self;
        self.dfpBannerView.validAdSizes = [NSValueFromGADAdSize(kGADAdSizeMediumRectangle)];
        self.dfpBannerView.delegate = self;
        self.dfpBannerView.appEventDelegate = self;
        self.refreshAdUnit() 
        
        
        
        
    }
    
    
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        Prebid.shared.markAdUnitLoaded(adView: bannerView)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        if error.code == GADErrorCode.noFill.rawValue {
            Prebid.shared.adUnitReceivedDefault(adView: bannerView)
        }
        Prebid.shared.markAdUnitLoaded(adView: bannerView)
    }
    
    func adView(_ banner: GADBannerView, didReceiveAppEvent name: String, withInfo info: String?) {
        Prebid.shared.adUnitReceivedAppEvent(adView: banner, instruction: name, prm: info)
    }
    
    @IBAction func didPressRefresh(_ sender: UIButton) {
        self.refreshAdUnit()
    }
    
    func refreshAdUnit() {
        let req = DFPRequest()
        self.bannerAdUnit.fetchDemand(adObject: req, adView: self.dfpBannerView, completion: {
            resultCode in
            
            self.dfpBannerView.load(req);
            
        })
    }
    
    
    
    @IBAction func didPressGatherStats(_ sender: UIButton) {
        Prebid.shared.gatherStats()
    }
    

}

