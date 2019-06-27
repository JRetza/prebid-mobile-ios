//
//  MultipleAdViewController.swift
//  AdManagerBannerExample
//
//  Created by L.D. Deurman on 07/06/2019.
//  Copyright © 2019 adsolutions. All rights reserved.
//

import UIKit
import PrebidMobile
import GoogleMobileAds

class MultipleAdViewController: UIViewController, GADBannerViewDelegate, GADAppEventDelegate {

    @IBOutlet weak var dfpBannerViewTwo: DFPBannerView!
    @IBOutlet weak var dfpBannerViewOne: DFPBannerView!
    
    var bannerAdUnitOne:BannerAdUnit!
    var bannerAdUnitTwo:BannerAdUnit!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Prebid.shared.appPage = "MultiAdViewController";
        Prebid.shared.appName = "AdManagerBannerExample";
        
        self.bannerAdUnitOne = BannerAdUnit(configId: "test-imp-id", size: CGSize(width: 300, height: 250))
        self.bannerAdUnitTwo = BannerAdUnit(configId: "test-imp-id", size: CGSize(width: 300, height: 250))
        
        self.setupDFPAdView(dfpBannerView: self.dfpBannerViewOne);
        self.setupDFPAdView(dfpBannerView: self.dfpBannerViewTwo);
        
        self.loadAdView(dfpBannerView: self.dfpBannerViewOne, adUnit: self.bannerAdUnitOne)
        
        self.loadAdView(dfpBannerView: self.dfpBannerViewTwo, adUnit: self.bannerAdUnitTwo)
    }
    
    func setupDFPAdView(dfpBannerView:DFPBannerView) {
        dfpBannerView.adUnitID = "/2172982/mobile-sdk";
        dfpBannerView.backgroundColor = UIColor.red
        dfpBannerView.rootViewController = self;
        dfpBannerView.validAdSizes = [NSValueFromGADAdSize(kGADAdSizeMediumRectangle)];
        dfpBannerView.delegate = self;
        dfpBannerView.appEventDelegate = self;
        
        
    }
    
    func loadAdView(dfpBannerView:DFPBannerView, adUnit:BannerAdUnit) {
        let publisherRequest = DFPRequest()
        adUnit.fetchDemand(adObject: publisherRequest, adView: dfpBannerView, completion: {
            resultCode in
            
            dfpBannerView.load(publisherRequest);
            
        })
        
        
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
        self.loadAdView(dfpBannerView: self.dfpBannerViewOne, adUnit: self.bannerAdUnitOne)
        
        self.loadAdView(dfpBannerView: self.dfpBannerViewTwo, adUnit: self.bannerAdUnitTwo)
    }
    
    @IBAction func didPressGatherStats(_ sender: UIButton) {
        Prebid.shared.gatherStats()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
