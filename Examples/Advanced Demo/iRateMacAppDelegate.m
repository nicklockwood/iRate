//
//  iRateMacAppDelegate.m
//  iRateMac
//
//  Created by Nick Lockwood on 06/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateMacAppDelegate.h"
#import "iRate.h"


@implementation iRateMacAppDelegate

@synthesize window;
@synthesize progressIndicator;
@synthesize label;

+ (void)initialize
{
	//set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.RainbowBlocksLite";
	
    //enable debug mode
    [iRate sharedInstance].debug = YES;
    
    //prevent automatic prompt
    [iRate sharedInstance].promptAtLaunch = NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//set myself as iRate delegate
    //you don't actually need to set this if you
    //are using the AppDelegate as your iRate delegate
    //as that is the default iRate delegate anyway
	[iRate sharedInstance].delegate = self;
}

- (IBAction)promptForRating:(id)sender;
{
	//perform manual check
	[[iRate sharedInstance] promptIfNetworkAvailable];
	[label setStringValue:@"Connecting to App Store..."];
	[progressIndicator startAnimation:self];
}

#pragma mark -
#pragma mark iVersionDelegate methods

- (void)iRateCouldNotConnectToAppStore:(NSError *)error
{
	[label setStringValue:[error localizedDescription]];
	[progressIndicator stopAnimation:self];
}

- (BOOL)iRateShouldPromptForRating
{
	//don't show prompt, just open app store
	[[iRate sharedInstance] openRatingsPageInAppStore];
	[label setStringValue:@"Connected."];
	[progressIndicator stopAnimation:self];
	return NO;
}

@end
