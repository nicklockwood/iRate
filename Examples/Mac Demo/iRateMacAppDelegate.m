//
//  iRateMacAppDelegate.m
//  iRateMac
//
//  Created by Nick Lockwood on 04/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateMacAppDelegate.h"
#import "iRate.h"


@implementation iRateMacAppDelegate

@synthesize window;

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.RainbowBlocksLite";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    
    //enable preview mode
    [iRate sharedInstance].previewMode = YES;
}

@end
