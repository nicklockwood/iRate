//
//  iRateAppDelegate.m
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateAppDelegate.h"
#import "iRateViewController.h"


@implementation iRateAppDelegate

@synthesize window;
@synthesize viewController;


//absolutely no configuration whatsoever!
//the app details are retrieved directly
//from iTunes using the app's bundle ID

//NOTE: you won't actually see anything until you've had the example installed
//for 10 days and launched it 10 times. You can simulate this by adjusting
//the date on your device if you wish to verify that it works


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    window.rootViewController = viewController;
    // Add the view controller's view to the window and display.
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

    return YES;
}

@end
