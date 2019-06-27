//
//  AppDelegate.swift
//  AdManagerBannerExample
//
//  Created by L.D. Deurman on 28/05/2019.
//  Copyright © 2019 adsolutions. All rights reserved.
//

import UIKit
import PrebidMobile

/*
 
 TODO:
 
 1. Discuss cachemanager options, async or not? Should not result in timeout for adUnit
 1.1 Current version only caches one bid and doesn't clear like Android
 2. Test for multiple ad units
 3. Discuss gatherStats place => applicationDidEnterBackground?
 4. Create CocoaPods depenedy
 
 */


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Prebid.shared.prebidServerHost = PrebidHost.AdSolutions
        Prebid.shared.prebidServerAccountId = "0"
        Prebid.shared.shareGeoLocation = true
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        CacheManager.configure()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

