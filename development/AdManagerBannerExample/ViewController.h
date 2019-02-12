//  Copyright (c) 2014 Google. All rights reserved.

#import <UIKit/UIKit.h>

@class DFPBannerView;
@import GoogleMobileAds;

@interface ViewController : UIViewController <GADAppEventDelegate,GADBannerViewDelegate>


/// The DFP banner view.
@property(nonatomic, weak) IBOutlet DFPBannerView *bannerView;

@end
