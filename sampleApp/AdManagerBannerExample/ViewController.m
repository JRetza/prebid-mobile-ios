//  Copyright (c) 2014 Google. All rights reserved.

@import GoogleMobileAds;

#import "ViewController.h"
#import "PrebidMobile/PrebidMobile.h"

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Replace this ad unit ID with your own ad unit ID.
  //self.bannerView.adUnitID = @"/6499/example/banner";
    self.bannerView.adUnitID = @"/2172982/mobile-sdk";
    self.bannerView.rootViewController = self;
    self.bannerView.validAdSizes = @[NSValueFromGADAdSize(kGADAdSizeMediumRectangle)];
    self.bannerView.delegate = self;
    self.bannerView.appEventDelegate = self;
  
    [PrebidMobile setBidKeywordsOnAdObject:self.bannerView withAdUnitId:@"test-imp-id" withTimeout:1000 completionHandler:^{
        [self.bannerView loadRequest:[DFPRequest request]];
    }];}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}
/// Tells the delegate an ad request loaded an ad.
- (void)adViewDidReceiveAd:(DFPBannerView *)adView {
    NSLog(@"adViewDidReceiveAd");
}

/// Tells the delegate an ad request failed.
- (void)adView:(DFPBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

/// Tells the delegate that a full-screen view will be presented in response
/// to the user clicking on an ad.
- (void)adViewWillPresentScreen:(DFPBannerView *)adView {
    NSLog(@"adViewWillPresentScreen");
}

/// Tells the delegate that the full-screen view will be dismissed.
- (void)adViewWillDismissScreen:(DFPBannerView *)adView {
    NSLog(@"adViewWillDismissScreen");
}

/// Tells the delegate that the full-screen view has been dismissed.
- (void)adViewDidDismissScreen:(DFPBannerView *)adView {
    NSLog(@"adViewDidDismissScreen");
}

/// Tells the delegate that a user click will open another app (such as
/// the App Store), backgrounding the current app.
- (void)adViewWillLeaveApplication:(DFPBannerView *)adView {
    NSLog(@"adViewWillLeaveApplication");
}

- (void)adView:(DFPBannerView *)banner
    didReceiveAppEvent:(NSString *)name
    withInfo:(NSString *)info {
NSLog(@"received banner event ");

}

@end
