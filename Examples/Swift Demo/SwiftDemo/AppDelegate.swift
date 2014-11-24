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

    override class func initialize() -> Void {
        
        //set the bundle ID. normally you wouldn't need to do this
        //as it is picked up automatically from your Info.plist file
        //but we want to test with an app that's actually on the store
        iRate.sharedInstance().applicationBundleID = "com.charcoaldesign.rainbowblocks-free"
        iRate.sharedInstance().onlyPromptIfLatestVersion = false
        
        //enable preview mode
        iRate.sharedInstance().previewMode = true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

