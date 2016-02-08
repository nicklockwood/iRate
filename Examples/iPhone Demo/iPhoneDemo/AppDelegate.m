//
//  AppDelegate.m
//  iPhoneDemo
//
//  Created by Nick Lockwood on 12/10/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "AppDelegate.h"
#import "iRate.h"

@implementation AppDelegate

@synthesize window;

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.rainbowblocks-free";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    
    //enable preview mode
    [iRate sharedInstance].previewMode = YES;
    /*
    [iRate sharedInstance].shouldAskSentiment = YES;
    [iRate sharedInstance].cancelButtonLabel = @"Not now";
    [iRate sharedInstance].developerEmail = @"test@test.com";
     */
}

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}

@end
