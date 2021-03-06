//  Copyright (c) 2014 Google. All rights reserved.

#import "AppDelegate.h"
#import "PrebidMobile/PBBannerAdUnit.h"
#import "PrebidMobile/PBServerAdapter.h"
#import "PrebidMobile/PBTargetingParams.h"
#import "PrebidMobile/PrebidMobile.h"
#import "PrebidMobile/PBLogManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
    [PBLogManager setPBLogLevel:PBLogLevelAll];
    
    [[PBTargetingParams sharedInstance] setLocalCache: TRUE];
    
    //PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"pg-i-pzc"];
    //PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"pg-a-pzc"];
    //PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"test-imp-empty"];
    //PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"test-imp-dealid"];
    PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"test-imp-id"];
    //PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"test-imp-id" andConfigId:@"test-imp-id.3"];
    [adUnit1 addSize:CGSizeMake(300, 250)];
    
    
    [PrebidMobile registerAdUnits:@[adUnit1]
                    withAccountId:@"0"
                         withHost:PBServerHostAdsolutions
               andPrimaryAdServer:PBPrimaryAdServerDFP
                      withAppName:@"demoAppI"
     ];
    
    [PrebidMobile setAppPage:@"/home"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for
  // certain types of temporary interruptions (such as an incoming phone call or SMS message) or
  // when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
  // rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store
  // enough application state information to restore your application to its current state in case
  // it is terminated later.
  // If your application supports background execution, this method is called instead of
  // applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo
  // many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If
  // the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also
  // applicationDidEnterBackground:.
}

@end
