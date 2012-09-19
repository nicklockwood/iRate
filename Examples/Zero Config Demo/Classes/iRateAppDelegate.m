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


//absolutely no configuration whatsoever!
//the app details are retrieved directly
//from iTunes using the app's bundle ID


#pragma mark -
#pragma mark Application lifecycle

+ (void)initialize
{
    //ok, we'll enable preview mode just so
    //you can see something without waiting for
    //ten days, but in the real app, you don't need this
    [iRate sharedInstance].previewMode = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
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
