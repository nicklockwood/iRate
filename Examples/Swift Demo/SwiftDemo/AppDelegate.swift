//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by Nick Lockwood on 12/10/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        //set the bundle ID. normally you wouldn't need to do this
        //as it is picked up automatically from your Info.plist file
        //but we want to test with an app that's actually on the store
        iRate.sharedInstance().applicationBundleID = "com.charcoaldesign.rainbowblocks"
        iRate.sharedInstance().onlyPromptIfLatestVersion = false
        iRate.sharedInstance().useSKStoreReviewControllerIfAvailable = false

        //enable preview mode
        iRate.sharedInstance().previewMode = true

        return true
    }
}

