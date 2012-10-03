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
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.rainbowblocks-free";
	
    //enable preview mode
    [iRate sharedInstance].previewMode = YES;
    
    //max out the text
    [iRate sharedInstance].message = @"This long message demonstrates how the UIAlertView switches to using a scrolling panel when the text is too long unless the disableAlertViewResizing option is set to NO. It's even worse in landscape mode - try it!";
    
    //disable the alert view resizing
    [iRate sharedInstance].disableAlertViewResizing = YES;
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
