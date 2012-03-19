//
//  iRateAppDelegate.m
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateAppDelegate.h"
#import "iRateViewController.h"
#import "iRate.h"


@implementation iRateAppDelegate

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

+ (void)initialize
{
	//set the app and bundle ID. normally you wouldn't need to do this
    //but we need to test with an app that's actually on the store
	[iRate sharedInstance].appStoreID = 355313284;
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.rainbowblocks";
	
    //enable debug mode
    [iRate sharedInstance].debug = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

    return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
    [viewController release];
    [window release];
    [super dealloc];
}


@end
